# Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |
#
# block-destructive.ps1
# PreToolUse hook: block dangerous shell commands before they execute.
#
# Env vars:
#   SKIP_DESTRUCTIVE_GUARD=true       - bypass entirely (emergency circuit breaker)
#   TOOL_GUARD_ALLOWLIST=sub1,sub2    - comma-separated command substrings to allow through
#
# Lifecycle: fires on every PreToolUse event. Exits 0 immediately for non-terminal
# tool calls (no tool_input.command field means nothing to check).
# Outputs hookSpecificOutput.permissionDecision = "deny" with exit 0 to block
# individual tool calls while letting the agent session continue.

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_DESTRUCTIVE_GUARD -eq 'true') { exit 0 }

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

# --- Only intercept terminal tool calls ---
if ($inputData.tool_name -ne 'run_in_terminal') { exit 0 }

$command = $inputData.tool_input.command
if (-not $command) { exit 0 }

# --- Temp-dir bypass: allow destructive ops on scratch paths ---
# If the command targets a clearly-temporary path, do not block. This avoids
# false positives during test setup/teardown without weakening protection on
# project files.
$tempPatterns = @()
foreach ($var in @('TEMP', 'TMP')) {
    $val = [Environment]::GetEnvironmentVariable($var)
    if ($val) { $tempPatterns += [regex]::Escape($val) }
}
# Common scratch markers regardless of env vars
$tempPatterns += '\\Temp\\', '/tmp/', '\\scratch[-_]', '\\test[-_]\d+', 'scaffold-test-\d+'

foreach ($tp in $tempPatterns) {
    if ($command -match $tp) { exit 0 }
}

# --- Allowlist: bypass for known-safe patterns ---
if ($env:TOOL_GUARD_ALLOWLIST) {
    $allowlist = $env:TOOL_GUARD_ALLOWLIST -split ',' | ForEach-Object { $_.Trim() }
    foreach ($allowed in $allowlist) {
        if ($allowed -and ($command -like "*$allowed*")) { exit 0 }
    }
}

# --- Blocked patterns (literal substring match) ---
$blocked = @(
    'rm -rf',
    'DROP TABLE',
    'DROP DATABASE',
    'TRUNCATE TABLE',
    'truncate table',
    'git push --force',
    'git push -f ',
    'git reset --hard',
    'Format-Volume',
    'del /s /q',
    'Clear-Content',
    'reg delete',
    'diskpart',
    'cipher /w'
)

# --- Blocked patterns (regex match) ---
# Used for commands where parameter order varies (e.g. Remove-Item permutations)
$blockedRegex = @(
    'Remove-Item\b.*-Recurse'   # catches -Recurse with or without -Force, any order
)

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

if ($allMatched) {
    $reason = "Blocked: '$matchedPattern' requires manual execution. Run this command yourself if intentional. " +
    "Set TOOL_GUARD_ALLOWLIST=<substring> to allow through, or SKIP_DESTRUCTIVE_GUARD=true to disable this guard."

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

exit 0
