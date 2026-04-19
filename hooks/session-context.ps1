# Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani |
#
# session-context.ps1
# SessionStart hook: inject project context at the start of every agent session.
#
# Injects:
#   - Current git branch and last commit
#   - Python version
#   - Project root
#   - Project Bible status (.copilot/context/PROJECT_CONTEXT.md)
#   - Active venv path
#   - Pipeline artifact detection (spec, review-report, holdout, feature-progress)
#   - Inferred pipeline phase from artifact presence
#   - Mega Minions hook harness version
#
# Output: JSON on stdout with hookSpecificOutput.additionalContext
# Exit 0 always — SessionStart hooks cannot block, only inject context.

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_SESSION_CONTEXT -eq 'true') {
    exit 0
}

# --- Collect environment facts ---
$branch = & git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -ne 0) { $branch = 'unknown' }

$lastCommit = & git log -1 --oneline 2>$null
if ($LASTEXITCODE -ne 0) { $lastCommit = 'no commits' }

$pythonVer = python --version 2>&1
if ($LASTEXITCODE -ne 0) { $pythonVer = 'not found' }

$projectRoot = & git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $projectRoot = (Get-Location).Path }
# Normalise to Windows path separators
$projectRoot = $projectRoot -replace '/', '\'

# --- Project Bible ---
$biblePath = Join-Path $projectRoot '.copilot\context\PROJECT_CONTEXT.md'
$bibleStatus = if (Test-Path $biblePath) {
    'loaded from .copilot/context/PROJECT_CONTEXT.md'
}
else {
    'NOT FOUND — run Brownfield Discovery or Greenfield Interview before starting'
}

# --- Active venv ---
$venvStatus = if ($env:VIRTUAL_ENV) { $env:VIRTUAL_ENV } else { 'none' }

# --- Session State ---
$sessionStatePath = Join-Path $projectRoot '.copilot\state\SESSION_STATE.md'
$sessionStateStatus = if (Test-Path $sessionStatePath) {
    'found — check .copilot/state/SESSION_STATE.md for prior session resume options'
}
else {
    'none'
}

# --- Pipeline Artifact Detection ---
$specPath = Join-Path $projectRoot '.copilot\specs\SPEC.md'
$reviewPath = Join-Path $projectRoot '.copilot\artifacts\review-report.md'
$holdoutPath = Join-Path $projectRoot '.copilot\holdout\HOLDOUT.md'
$featureProgressPath = Join-Path $projectRoot '.copilot\state\FEATURE_PROGRESS.json'

$artifacts = @()
if (Test-Path $specPath) { $artifacts += 'spec' }
if (Test-Path $reviewPath) { $artifacts += 'review-report' }
if (Test-Path $holdoutPath) { $artifacts += 'holdout' }
if (Test-Path $featureProgressPath) { $artifacts += 'feature-progress' }

# Infer pipeline phase from artifact presence
$pipelinePhase = if ($artifacts -contains 'review-report') {
    'Ship (review complete, ready for release)'
}
elseif ($artifacts -contains 'spec' -and -not ($artifacts -contains 'review-report')) {
    'Build or Review (spec exists, no review report yet)'
}
elseif (Test-Path $biblePath) {
    'Design (Project Bible exists, no spec yet)'
}
else {
    'Discovery (no Project Bible or spec found)'
}

$artifactList = if ($artifacts.Count -gt 0) { $artifacts -join ', ' } else { 'none' }

# --- Build context string ---
$ctx = @"
=== Mega Minions Session Context (auto-injected) ===
- Branch:        $branch
- Last commit:   $lastCommit
- Python:        $pythonVer
- Project root:  $projectRoot
- Project Bible: $bibleStatus
- Session state: $sessionStateStatus
- Active venv:   $venvStatus
- Pipeline phase: $pipelinePhase
- Artifacts:     $artifactList
- Hook harness:  v1.1 (8 hooks: quality-gate, scan-secrets, block-destructive, lint-on-write, auto-format, session-context, subagent-context, pre-compact-save)
"@

# --- Output JSON for VS Code context injection ---
$output = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName     = 'SessionStart'
        additionalContext = $ctx
    }
} | ConvertTo-Json -Depth 5 -Compress:$false

Write-Output $output
exit 0
