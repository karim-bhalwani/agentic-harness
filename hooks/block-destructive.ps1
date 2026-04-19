# Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani |
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

# --- Allowlist: bypass for known-safe patterns ---
if ($env:TOOL_GUARD_ALLOWLIST) {
    $allowlist = $env:TOOL_GUARD_ALLOWLIST -split ',' | ForEach-Object { $_.Trim() }
    foreach ($allowed in $allowlist) {
        if ($allowed -and ($command -like "*$allowed*")) { exit 0 }
    }
}

# --- Blocked patterns ---
$blocked = @(
    'rm -rf',
    'Remove-Item -Recurse -Force',
    'Remove-Item -Force -Recurse',
    'DROP TABLE',
    'DROP DATABASE',
    'TRUNCATE TABLE',
    'truncate table',
    'git push --force',
    'git push -f ',
    'git reset --hard',
    'Format-Volume',
    'del /s /q'
)

foreach ($pattern in $blocked) {
    # Case-insensitive match for SQL keywords; case-sensitive preserved for others
    if ($command -match [regex]::Escape($pattern)) {
        $reason = "Blocked: '$pattern' requires manual execution. Run this command yourself if intentional. " +
        "Set TOOL_GUARD_ALLOWLIST=$pattern to allow through, or SKIP_DESTRUCTIVE_GUARD=true to disable this guard."

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
}

exit 0
