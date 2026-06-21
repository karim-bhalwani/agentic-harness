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
# startup: it collects the same environment facts but skips the session state
# check (irrelevant to subagents) and keeps output minimal to conserve the
# subagent's smaller context budget.
#
# Output: JSON on stdout with hookSpecificOutput.additionalContext
# Exit 0 always. SubagentStart hooks cannot block, only inject context.
#
# Env vars:
#   SKIP_SUBAGENT_CONTEXT=true  - bypass entirely (emergency circuit breaker)

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_SUBAGENT_CONTEXT -eq 'true') {
    exit 0
}

# --- Read stdin ---
$rawInput = [Console]::In.ReadToEnd()
$inputData = $null
if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
    try { $inputData = $rawInput | ConvertFrom-Json } catch { }
}

$agentType = if ($inputData -and $inputData.agent_type) { $inputData.agent_type } else { 'unknown' }

# --- Collect environment facts ---
$branch = & git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -ne 0) { $branch = 'unknown' }

$pythonVer = python --version 2>&1
if ($LASTEXITCODE -ne 0) { $pythonVer = 'not found' }

$projectRoot = & git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $projectRoot = (Get-Location).Path }
$projectRoot = $projectRoot -replace '/', '\'

# --- Project Bible ---
$biblePath = Join-Path $projectRoot '.copilot\context\PROJECT_CONTEXT.md'
$bibleStatus = if (Test-Path $biblePath) { 'available' } else { 'NOT FOUND' }

# --- Active venv ---
$venvStatus = if ($env:VIRTUAL_ENV) { $env:VIRTUAL_ENV } else { 'none' }

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
