# Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani |
#
# lint-on-write.ps1
# PreToolUse hook: lint Python files BEFORE the write hits disk.
# If ruff finds errors, the write is DENIED. The agent must fix and retry.
#
# This is Burke Holland's "one hook that might be all you need" pattern:
# force the AI to write lintable code in the inner loop, not backtrack
# after 10 broken files.
#
# Handles two file-writing tools:
#   create_file            - tool_input.content   (full new file content)
#   replace_string_in_file - tool_input.newString (fragment; reconstructs full
#                            file by applying the replacement to disk content)
#
# Non-Python files and non-file-writing tools: exit 0 immediately (zero cost).
#
# Env vars:
#   SKIP_LINT_ON_WRITE=true  - bypass entirely (emergency circuit breaker)
#   LINT_MODE=warn            - log lint errors without blocking (default: block)
#
# Output on deny: hookSpecificOutput.permissionDecision = "deny" + reason.
# The reason is shown to the agent in chat so it knows exactly what to fix.

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_LINT_ON_WRITE -eq 'true') { exit 0 }

# --- Only acts if ruff is available ---
if (-not (Get-Command ruff -ErrorAction SilentlyContinue)) { exit 0 }

# --- Read stdin ---
$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) { exit 0 }

$inputData = $null
try {
    $inputData = $rawInput | ConvertFrom-Json
}
catch {
    exit 0
}

$toolName = $inputData.tool_name

# --- Only intercept file-writing tools ---
if ($toolName -notin @('create_file', 'replace_string_in_file')) { exit 0 }

# --- Resolve file path ---
$filePath = $inputData.tool_input.filePath
if (-not $filePath) { exit 0 }

# Path traversal guard
if ($filePath -match '\.\.') { exit 0 }

# --- Only lint Python files ---
if ($filePath -notmatch '\.py$') { exit 0 }

$mode = if ($env:LINT_MODE) { $env:LINT_MODE } else { 'block' }

# --- Build the content to lint ---
$contentToLint = $null

if ($toolName -eq 'create_file') {
    # Full file content is in tool_input.content
    $contentToLint = $inputData.tool_input.content
}
elseif ($toolName -eq 'replace_string_in_file') {
    # Fragment only — reconstruct by applying the replacement to the existing file
    $oldString = $inputData.tool_input.oldString
    $newString = $inputData.tool_input.newString

    if (-not $newString) { exit 0 }

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
        # New file via replace tool — lint what would be written
        $contentToLint = $newString
    }
}

if (-not $contentToLint) { exit 0 }

# --- Write to temp file and lint ---
$tempFile = $null
try {
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.py'
    Set-Content -Path $tempFile -Value $contentToLint -Encoding UTF8 -NoNewline

    # Run ruff check - capture output and exit code
    $ruffOutput = & ruff check $tempFile --output-format=concise 2>&1
    $ruffExitCode = $LASTEXITCODE

    if ($ruffExitCode -eq 0) {
        # Clean — allow the write
        exit 0
    }

    # Ruff found errors — strip the temp file path from output so the agent
    # sees the logical file path it intended to write, not the temp path
    $cleanOutput = ($ruffOutput -join "`n") -replace [regex]::Escape($tempFile), $filePath

    $reason = "Lint errors in $filePath - fix before writing:`n$cleanOutput"

    if ($mode -eq 'block') {
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
        # Warn mode — log but allow
        Write-Host "lint-on-write WARNING: $reason"
        exit 0
    }

}
catch {
    # Never crash the hook — if linting fails for any reason, allow the write
    exit 0
}
finally {
    # Always clean up temp file
    if ($tempFile -and (Test-Path $tempFile)) {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}
