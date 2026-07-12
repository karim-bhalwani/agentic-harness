# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# subagent-context.ps1
# SubagentStart hook: inject environment context into every subagent session.
#
# Problem: subagents run in isolated context windows and do NOT inherit the
# SessionStart hook's context injection. Without this hook, a subagent does not
# know the branch, Python version, venv status, or Project Bible location.
#
# This is a lightweight mirror of session-context.ps1 optimized for subagent
# startup: it collects the same environment facts plus a one-line session
# state pointer (status only, never full content) and keeps output minimal
# to conserve the subagent's smaller context budget.
#
# Output: JSON on stdout with hookSpecificOutput.additionalContext
# Exit 0 always. SubagentStart hooks cannot block, only inject context.
#
# Env vars:
#   SKIP_SUBAGENT_CONTEXT=true  - bypass entirely (emergency circuit breaker)

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

# --- Circuit breaker ---
if (Test-MMCircuitBreaker -EnvVar 'SKIP_SUBAGENT_CONTEXT') {
    exit 0
}

# --- Read stdin ---
$inputData = Read-MMHookInput

$agentType = if ($inputData -and (Get-MMProp $inputData 'agent_type')) { (Get-MMProp $inputData 'agent_type') } else { 'unknown' }

# --- Collect environment facts ---
$branch = & git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -ne 0) { $branch = 'unknown' }

$pythonCmd = Get-MMPythonCommand
$pythonVer = if ($pythonCmd) { & $pythonCmd --version 2>&1 } else { 'not found' }
if ($LASTEXITCODE -ne 0) { $pythonVer = 'not found' }

$projectRoot = Get-MMRepoRoot

# --- Project Bible ---
$biblePath = Join-Path $projectRoot '.copilot\context\PROJECT_CONTEXT.md'
$bibleStatus = if (Test-Path $biblePath) { 'available' } else { 'NOT FOUND' }

# --- Active venv ---
$venvStatus = if ($env:VIRTUAL_ENV) { $env:VIRTUAL_ENV } else { 'none' }

# --- Session state pointer (A4 fix) ---
# Subagents previously started blind to pipeline state. Inject a one-line
# pointer (status only, never full content) so a subagent knows to read
# SESSION_STATE.md for context pointers when resuming pipeline work.
$sessionStatePath = Join-Path $projectRoot '.copilot\state\SESSION_STATE.md'
$sessionStateStatus = 'none'
if (Test-Path $sessionStatePath) {
    $sessionStateStatus = 'found - read .copilot/state/SESSION_STATE.md for context pointers'
    try {
        $stateHead = Get-Content $sessionStatePath -TotalCount 10 -ErrorAction Stop
        $statusLine = $stateHead | Where-Object { $_ -match '\*\*Status:\*\*\s*(\S+)' } | Select-Object -First 1
        if ($statusLine -and $statusLine -match '\*\*Status:\*\*\s*(\S+)') {
            $sessionStateStatus = "found (status: $($matches[1])) - read .copilot/state/SESSION_STATE.md for context pointers"
        }
    }
    catch { }
}

# --- Persist active agent so artifact-manifest.ps1 can attribute writes ---
# (VS Code does not pass agent identity to PostToolUse; this file is the bridge.)
if ($agentType -and $agentType -ne 'unknown') {
    $stateDir = Join-Path $projectRoot '.copilot\state'
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
    Set-Content -Path (Join-Path $stateDir '.active-agent') -Value $agentType -NoNewline -Encoding UTF8
}

# --- Build context string (compact for subagent budget) ---
$ctx = @"
=== Subagent Context (auto-injected by subagent-context.ps1) ===
- Agent type:    $agentType
- Branch:        $branch
- Python:        $pythonVer
- Project root:  $projectRoot
- Project Bible: $bibleStatus
- Active venv:   $venvStatus
- Session state: $sessionStateStatus
"@

# --- Output JSON for VS Code context injection ---
$output = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName     = 'SubagentStart'
        additionalContext = $ctx
    }
} | ConvertTo-Json -Depth 5 -Compress:$false

Write-Output $output
exit 0
