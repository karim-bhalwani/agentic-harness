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

[CmdletBinding()]
param()

function Get-GovernanceLevel {
    $level = if ($env:GOVERNANCE_LEVEL) { $env:GOVERNANCE_LEVEL.ToLowerInvariant() } else { 'standard' }
    if ($level -notin @('open', 'standard', 'strict', 'locked')) { return 'standard' }
    return $level
}

function Get-HookLogPath {
    $logDir = if ($env:HOOK_LOG_DIR) {
        $env:HOOK_LOG_DIR
    }
    else {
        Join-Path (Get-Location).Path '.copilot\state\hook-logs'
    }

    try {
        $null = New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop
        return Join-Path $logDir 'block-destructive.jsonl'
    }
    catch {
        return $null
    }
}

function Write-HookLog {
    param(
        [string]$Event,
        [string]$ToolName,
        [string]$GovernanceLevel,
        [string]$Decision,
        [string]$Reason,
        [string]$Pattern
    )

    $path = Get-HookLogPath
    if (-not $path) { return }

    $entry = [ordered]@{
        timestamp  = (Get-Date).ToUniversalTime().ToString('o')
        hook       = 'block-destructive'
        event      = $Event
        tool       = $ToolName
        governance = $GovernanceLevel
        decision   = $Decision
        reason     = $Reason
        pattern    = $Pattern
    }

    try {
        Add-Content -Path $path -Value ($entry | ConvertTo-Json -Compress) -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        # Logging failure must never fail the hook decision path.
    }
}

# --- Circuit breaker ---
if ($env:SKIP_DESTRUCTIVE_GUARD -eq 'true') { exit 0 }

$governanceLevel = Get-GovernanceLevel

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
    'cipher /w',
    'chmod 777',
    'chmod -R 777'
)

# --- Blocked patterns (regex match) ---
# Used for commands where parameter order varies (e.g. Remove-Item permutations)
$blockedRegex = @(
    'Remove-Item\b.*-Recurse',                # catches -Recurse with or without -Force, any order
    'chmod\s+(-[A-Za-z]+\s+)*777',            # chmod [flags] 777 — any world-writable variant
    '\bsudo\s',                               # sudo <any command> — privilege escalation
    'curl[^|#\n]*\|\s*(?:bash|sh)\b',         # curl ... | bash or | sh — remote code execution
    'wget[^|#\n]*\|\s*(?:bash|sh)\b'        # wget ... | bash or | sh — remote code execution
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

# --- Special case: DELETE FROM without a WHERE clause (unbounded delete) ---
if (-not $allMatched -and $command -imatch 'DELETE\s+FROM\s+\w' -and $command -inotmatch '\bWHERE\b') {
    $allMatched = $true
    $matchedPattern = 'DELETE FROM (no WHERE clause)'
}

if ($allMatched) {
    if ($governanceLevel -eq 'open') {
        Write-HookLog -Event 'threat_detected' -ToolName 'run_in_terminal' -GovernanceLevel $governanceLevel -Decision 'allow' -Reason 'open governance level (warn-only)' -Pattern $matchedPattern
        Write-Host "WARNING (block-destructive): matched '$matchedPattern' but allowed because GOVERNANCE_LEVEL=open"
        exit 0
    }

    $reason = "Blocked: '$matchedPattern' requires manual execution. Run this command yourself if intentional. " +
    "Set TOOL_GUARD_ALLOWLIST=<substring> to allow through, or SKIP_DESTRUCTIVE_GUARD=true to disable this guard."

    Write-HookLog -Event 'threat_detected' -ToolName 'run_in_terminal' -GovernanceLevel $governanceLevel -Decision 'deny' -Reason $reason -Pattern $matchedPattern

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

Write-HookLog -Event 'scan_complete' -ToolName 'run_in_terminal' -GovernanceLevel $governanceLevel -Decision 'allow' -Reason 'no dangerous patterns matched' -Pattern ''

exit 0
