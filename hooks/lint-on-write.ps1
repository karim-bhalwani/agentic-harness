# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# lint-on-write.ps1
# PreToolUse hook: lint Python files BEFORE the write hits disk.
# If ruff finds errors, the write is DENIED. The agent must fix and retry.
#
# This is Burke Holland's "one hook that might be all you need" pattern:
# force the AI to write lintable code in the inner loop, not backtrack
# after 10 broken files.
#
# Handles three file-writing tools:
#   create_file                  - tool_input.content   (full new file content)
#   replace_string_in_file       - tool_input.newString (fragment; reconstructs full
#                                  file by applying the replacement to disk content)
#   multi_replace_string_in_file - tool_input.replacements[] (each entry carries its
#                                  own filePath/oldString/newString; every .py entry
#                                  is linted; first failure denies the whole call)
#
# Non-Python files and non-file-writing tools: exit 0 immediately (zero cost).
#
# Env vars:
#   SKIP_LINT_ON_WRITE=true  - bypass entirely (emergency circuit breaker)
#   LINT_MODE=warn            - log lint errors without blocking (default: block)
#
# Output on deny: hookSpecificOutput.permissionDecision = "deny" + reason.
# The reason is shown to the agent in chat so it knows exactly what to fix.

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

# --- Circuit breaker ---
if (Test-MMCircuitBreaker -EnvVar 'SKIP_LINT_ON_WRITE') { exit 0 }

# --- Read stdin ---
$inputData = Read-MMHookInput
if (-not $inputData) { exit 0 }

$toolName = Get-MMProp $inputData 'tool_name'

# --- Only intercept file-writing tools ---
if ($toolName -notin @('create_file', 'replace_string_in_file', 'multi_replace_string_in_file')) { exit 0 }

$toolInput = Get-MMProp $inputData 'tool_input'

# --- Normalize the payload into one or more write items (H-F4 fix) ---
# multi_replace_string_in_file carries replacements[], each with its own
# filePath; previously those writes bypassed this gate entirely.
$writeItems = @()
if ($toolName -eq 'multi_replace_string_in_file') {
    foreach ($rep in @(Get-MMProp $toolInput 'replacements' @())) {
        $writeItems += [pscustomobject]@{
            FilePath  = Get-MMProp $rep 'filePath'
            OldString = Get-MMProp $rep 'oldString'
            NewString = Get-MMProp $rep 'newString'
            Content   = $null
        }
    }
}
elseif ($toolName -eq 'create_file') {
    $writeItems += [pscustomobject]@{
        FilePath  = Get-MMProp $toolInput 'filePath'
        OldString = $null
        NewString = $null
        Content   = Get-MMProp $toolInput 'content'
    }
}
else {
    $writeItems += [pscustomobject]@{
        FilePath  = Get-MMProp $toolInput 'filePath'
        OldString = Get-MMProp $toolInput 'oldString'
        NewString = Get-MMProp $toolInput 'newString'
        Content   = $null
    }
}
if ($writeItems.Count -eq 0) { exit 0 }

# Path traversal guard - DENY (not allow) on traversal attempts.
# This MUST run before the ruff availability check because it is a security boundary.
# We test for a path SEGMENT equal to '..' (not a substring), so a benign
# filename like 'config..json' is processed normally (H-03 fix).
foreach ($item in $writeItems) {
    $itemPath = $item.FilePath
    if (-not $itemPath) { continue }
    if (($itemPath -split '[\\/]') -contains '..') {
        $traversalReason = "BLOCKED (lint-on-write): filePath '$itemPath' contains a '..' traversal segment. Path traversal is not permitted. Use a clean absolute or repo-relative path with no parent-directory references."
        $denyPayload = [ordered]@{
            hookSpecificOutput = [ordered]@{
                hookEventName            = 'PreToolUse'
                permissionDecision       = 'deny'
                permissionDecisionReason = $traversalReason
            }
        } | ConvertTo-Json -Depth 5 -Compress:$false
        Write-Output $denyPayload
        exit 0
    }
}

# --- Only acts if ruff is available (optional linting after security checks) ---
if (-not (Get-Command ruff -ErrorAction SilentlyContinue)) { exit 0 }

$mode = if ($env:LINT_MODE) { $env:LINT_MODE } else { 'block' }

foreach ($item in $writeItems) {
    $filePath = $item.FilePath
    if (-not $filePath) { continue }

    # --- Only lint Python files ---
    if ($filePath -notmatch '\.py$') { continue }

    # --- Build the content to lint ---
    $contentToLint = $null

    if ($null -ne $item.Content) {
        # Full file content (create_file)
        $contentToLint = $item.Content
    }
    else {
        # Fragment - reconstruct by applying the replacement to the existing file
        $oldString = $item.OldString
        $newString = $item.NewString

        if (-not $newString) { continue }

        if (Test-Path $filePath) {
            try {
                $diskContent = Get-Content $filePath -Raw -ErrorAction Stop
                # Normalize line endings to LF for reliable matching
                $diskNorm = $diskContent -replace "`r`n", "`n"
                $oldNorm = $oldString -replace "`r`n", "`n"
                $newNorm = $newString -replace "`r`n", "`n"
                if ($oldNorm -and $diskNorm.Contains($oldNorm)) {
                    $contentToLint = $diskNorm.Replace($oldNorm, $newNorm)
                }
                else {
                    # Can't reconstruct reliably - lint the new fragment only
                    $contentToLint = $newString
                }
            }
            catch {
                $contentToLint = $newString
            }
        }
        else {
            # New file via replace tool - lint what would be written
            $contentToLint = $newString
        }
    }

    if (-not $contentToLint) { continue }

    # --- Write to temp file and lint (per write item) ---
    $tempFile = $null
    try {
        $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.py'
        Set-Content -Path $tempFile -Value $contentToLint -Encoding UTF8 -NoNewline

        # Run ruff check - capture output and exit code
        $ruffOutput = & ruff check $tempFile --output-format=concise 2>&1
        $ruffExitCode = $LASTEXITCODE

        if ($ruffExitCode -eq 0) {
            # Clean - allow this item, keep checking the remaining items
            Write-MMHookLog -HookName 'lint-on-write' -Event 'lint_passed' -Decision 'allow' `
                -Extra @{ file = $filePath; tool = $toolName }
            continue
        }

        # Ruff found errors - strip the temp file path from output so the agent
        # sees the logical file path it intended to write, not the temp path
        $cleanOutput = ($ruffOutput -join "`n") -replace [regex]::Escape($tempFile), $filePath

        $reason = "Lint errors in $filePath - fix before writing:`n$cleanOutput"

        if ($mode -eq 'block') {
            Write-MMHookLog -HookName 'lint-on-write' -Event 'lint_failed' -Decision 'deny' `
                -Extra @{ file = $filePath; tool = $toolName; issue_count = @($ruffOutput).Count }
            $output = [ordered]@{
                hookSpecificOutput = [ordered]@{
                    hookEventName            = 'PreToolUse'
                    permissionDecision       = 'deny'
                    permissionDecisionReason = $reason
                    additionalContext        = "ruff found $(@($ruffOutput).Count) issue(s) in the content you are trying to write to $filePath. Fix all lint errors before this file write will be allowed."
                }
            } | ConvertTo-Json -Depth 5 -Compress:$false

            Write-Output $output
            exit 0   # exit 0 so VS Code parses the JSON decision
        }
        else {
            # Warn mode - log but allow, keep checking remaining items
            Write-MMHookLog -HookName 'lint-on-write' -Event 'lint_failed' -Decision 'warn' `
                -Extra @{ file = $filePath; tool = $toolName; issue_count = @($ruffOutput).Count; mode = 'warn' }
            Write-Host "lint-on-write WARNING: $reason"
            continue
        }

    }
    catch {
        # Never crash the hook - if linting fails for any reason, allow this item
        continue
    }
    finally {
        # Always clean up temp file
        if ($tempFile -and (Test-Path $tempFile)) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# All items clean (or warn-only) - allow the write
exit 0
