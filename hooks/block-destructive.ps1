# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# block-destructive.ps1
# PreToolUse hook: block dangerous shell commands before they execute.
#
# Env vars:
#   SKIP_DESTRUCTIVE_GUARD=true       - bypass entirely (emergency circuit breaker)
#   TOOL_GUARD_ALLOWLIST=sub1,sub2    - comma-separated command substrings to allow through
#   GOVERNANCE_LEVEL=open|standard|strict|locked (default: standard)
#   HOOK_LOG_DIR=<path>               - override structured hook log directory
#
# Lifecycle: fires on every PreToolUse event. Exits 0 immediately for non-terminal
# tool calls (no tool_input.command field means nothing to check).
# Outputs hookSpecificOutput.permissionDecision = "deny" with exit 0 to block
# individual tool calls while letting the agent session continue.

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

# --- Circuit breaker ---
if (Test-MMCircuitBreaker -EnvVar 'SKIP_DESTRUCTIVE_GUARD') { exit 0 }

$governanceLevel = Get-MMGovernanceLevel

# --- Read stdin ---
$inputData = Read-MMHookInput
if (-not $inputData) { exit 0 }

try {
    # --- Only intercept terminal tool calls ---
    if ((Get-MMProp $inputData 'tool_name') -ne 'run_in_terminal') { exit 0 }

    $toolInput = Get-MMProp $inputData 'tool_input' $null
    $command = Get-MMProp $toolInput 'command' $null
    if (-not $command) { exit 0 }

    # --- Blocked patterns (literal substring match) ---
    $blocked = @(
        'rm -rf',
        'rm -fr',
        'rm -r -f',
        'rm --recursive --force',
        'DROP TABLE',
        'DROP DATABASE',
        'TRUNCATE TABLE',
        'truncate table',
        'git push --force',
        'git push -f ',
        # NOTE: the 'git push --force' substring above intentionally ALSO blocks
        # 'git push --force-with-lease'. This is a documented residual decision
        # (upgrade-plan.md 2.2 / Open human decisions 2.2): the team has not opted
        # to allow --force-with-lease, so the substring match blocks it too.
        'git reset --hard',
        'Format-Volume',
        'del /s /q',
        'del /q /s',
        'Clear-Content',
        'reg delete',
        'diskpart',
        'cipher /w',
        'chmod 777',
        'chmod -R 777'
    )

    # --- Blocked patterns (regex match) ---
    # Used for commands where parameter order varies (e.g. Remove-Item permutations)
    # Flag-order independence: a destructive flag (recurse/force) is matched
    # regardless of position, so `rm -r -f`, `rm -fr`, `rm --recursive --force`,
    # `Remove-Item -Force` (no -Recurse), `ri`, `rd /s /q`, `del /q /s`,
    # `pwsh -enc`, and piped `| iex` are all caught.
    $blockedRegex = @(
        # rm with both recursive and force flags, in any order/combination, plus
        # long forms --recursive / --force. Tokenize so flag reordering cannot evade.
        '\brm\s+(?=(?:\S+\s+)*?-{1,2}\w*r)(?=(?:\S+\s+)*?-{1,2}\w*f)',
        '\brm\s+(?=(?:\S+\s+)*?-{1,2}(?:recursive|force))(?=(?:\S+\s+)*?-{1,2}(?:recursive|force))',
        # PowerShell destructive cmdlets with any destructive flag (recurse OR force
        # OR /s OR /q). Remove-Item -Force alone (no -Recurse) now counts.
        '\b(Remove-Item|ri|rd|del|erase)\b.*(-Recurse|-Force|/s|/q)',
        'chmod\s+(-[A-Za-z]+\s+)*777',            # chmod [flags] 777 — any world-writable variant
        '\bsudo\s',                               # sudo <any command> — privilege escalation
        'curl[^|#\n]*\|\s*(?:bash|sh)\b',         # curl ... | bash or | sh — remote code execution
        'wget[^|#\n]*\|\s*(?:bash|sh)\b',         # wget ... | bash or | sh — remote code execution
        '\brunas\b',                              # Windows privilege escalation
        '\b(powershell|pwsh)(\.exe)?\s+.*-e(nc|ncodedcommand)?\b',  # encoded-command (obfuscated RCE)
        'certutil\s+.*-urlcache',                 # certutil download cradle
        'Invoke-WebRequest[^|#\n]*\|\s*iex\b',    # iwr ... | iex — remote code execution
        '\biex\s*\(',                             # Invoke-Expression (inline eval)
        'Invoke-Expression',                      # explicit eval alias
        '\|\s*iex\b',                             # piped | iex — remote code execution
        '\|\s*Invoke-Expression\b'               # piped | Invoke-Expression
    )

    # The old guard allowed ANY command containing a temp marker to bypass the
    # destructive check, so a workspace target paired with an unrelated `C:\Temp`
    # argument slipped through. We now exempt a destructive command ONLY when every
    # path-bearing target resolves beneath an approved scratch root. A command with
    # no path tokens (e.g. `rm -rf foo`) is never auto-exempted.
    $scratchRoots = @()
    foreach ($var in @('TEMP', 'TMP')) {
        $val = [Environment]::GetEnvironmentVariable($var)
        if ($val) { $scratchRoots += $val.Trim().TrimEnd('\', '/') }
    }
    # Common scratch markers regardless of env vars
    $scratchRoots += @('C:\Temp', 'C:\Windows\Temp', '/tmp', '/var/tmp', '/dev/shm')

    # Extract ALL non-flag argument tokens from the command for containment checks.
    # A flag is a token starting with '-' or '/' followed by letters. Tokens
    # WITHOUT a path separator (e.g. `important-dir` in `rm -rf important-dir
    # /tmp/decoy`) are no longer dropped: they are treated as path targets and must
    # also resolve under a scratch root, otherwise the exemption does NOT apply.
    # The first token is the command/executable itself (e.g. `rm`, `Remove-Item`)
    # and is excluded from path-target consideration.
    $pathTokens = @()
    $tokens = $command -split '\s+' | Where-Object { $_ }
    $tokenIdx = 0
    foreach ($tok in $tokens) {
        $tokenIdx++
        if ($tokenIdx -eq 1) { continue }   # skip the command/executable
        $bare = $tok.Trim('"', "'")
        # A flag is '-x'/'--xx' or a DOS-style switch '/s' with NO further path
        # separator. A Unix absolute path like '/tmp/foo' contains a second '/'
        # and MUST be treated as a path target, not a flag (H-F5 fix). A bare
        # root like '/tmp' is conservatively treated as a switch and therefore
        # never auto-exempted (over-blocking is the safe direction).
        $isFlag = ($bare -match '^-') -or ($bare -match '^/[A-Za-z]+$')
        if ($isFlag) { continue }
        $pathTokens += $bare
    }

    # A destructive command is exempt only if it has at least one path token and
    # EVERY path token resolves beneath an approved scratch root.
    $hasDestructiveIntent = $false
    foreach ($pattern in $blocked) {
        if ($command -match [regex]::Escape($pattern)) { $hasDestructiveIntent = $true; break }
    }
    if (-not $hasDestructiveIntent) {
        foreach ($rxPattern in $blockedRegex) {
            if ($command -match $rxPattern) { $hasDestructiveIntent = $true; break }
        }
    }
    if ($hasDestructiveIntent -and $pathTokens.Count -gt 0) {
        $allScratch = $true
        foreach ($tok in $pathTokens) {
            $underScratch = $false
            foreach ($root in $scratchRoots) {
                if (Test-MMPathUnderRoot -Path $tok -Root $root) { $underScratch = $true; break }
            }
            if (-not $underScratch) { $allScratch = $false; break }
        }
        if ($allScratch) {
            Write-MMHookLog -HookName 'block-destructive' -Event 'scratch_exempt' -Decision 'allow' `
                -Extra @{ tool = 'run_in_terminal'; reason = 'all destructive targets under approved scratch root'; targets = ($pathTokens -join ', ') }
            exit 0
        }
    }

    # --- Allowlist: bypass for known-safe patterns ---
    if ($env:TOOL_GUARD_ALLOWLIST) {
        $allowlist = $env:TOOL_GUARD_ALLOWLIST -split ',' | ForEach-Object { $_.Trim() }
        foreach ($allowed in $allowlist) {
            if ($allowed -and ($command -like "*$allowed*")) { exit 0 }
        }
    }

    $allMatched = $false
    $matchedPattern = ''

    foreach ($pattern in $blocked) {
        if ($command -match [regex]::Escape($pattern)) {
            $allMatched = $true
            $matchedPattern = $pattern
            break
        }
    }

    if (-not $allMatched) {
        foreach ($rxPattern in $blockedRegex) {
            if ($command -match $rxPattern) {
                $allMatched = $true
                $matchedPattern = $rxPattern
                break
            }
        }
    }

    # --- Special case: DELETE FROM without a WHERE clause (unbounded delete) ---
    if (-not $allMatched -and $command -imatch 'DELETE\s+FROM\s+\w' -and $command -inotmatch '\bWHERE\b') {
        $allMatched = $true
        $matchedPattern = 'DELETE FROM (no WHERE clause)'
    }

    if ($allMatched) {
        if ($governanceLevel -eq 'open') {
            Write-MMHookLog -HookName 'block-destructive' -Event 'threat_detected' -Decision 'allow' `
                -Extra @{ tool = 'run_in_terminal'; reason = 'open governance level (warn-only)'; pattern = $matchedPattern }
            Write-Host "WARNING (block-destructive): matched '$matchedPattern' but allowed because GOVERNANCE_LEVEL=open"
            exit 0
        }

        $reason = "Blocked: '$matchedPattern' requires manual execution. Run this command yourself if intentional. " +
        "Set TOOL_GUARD_ALLOWLIST=<substring> to allow through, or SKIP_DESTRUCTIVE_GUARD=true to disable this guard."

        Write-MMHookLog -HookName 'block-destructive' -Event 'threat_detected' -Decision 'deny' `
            -Extra @{ tool = 'run_in_terminal'; reason = $reason; pattern = $matchedPattern }

        $output = [ordered]@{
            hookSpecificOutput = [ordered]@{
                hookEventName            = 'PreToolUse'
                permissionDecision       = 'deny'
                permissionDecisionReason = $reason
            }
        } | ConvertTo-Json -Depth 5 -Compress:$false

        Write-Output $output
        exit 0   # exit 0 so VS Code parses the JSON decision
    }

    Write-MMHookLog -HookName 'block-destructive' -Event 'scan_complete' -Decision 'allow' `
        -Extra @{ tool = 'run_in_terminal'; reason = 'no dangerous patterns matched'; pattern = '' }

    exit 0
}
catch {
    # A crash in the guard body must NOT let the destructive command proceed
    # silently (that would bypass the guard). Fail closed.
    Write-MMHookFailClosedDeny -HookName 'block-destructive' -Exception $_
}
