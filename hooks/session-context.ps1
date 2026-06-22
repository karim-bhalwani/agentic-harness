# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
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
#   - PLAN-phase story context (STORY_ID env var or .copilot/stories/.active-story)
#   - Mega Minions hook harness version
#
# Output: JSON on stdout with hookSpecificOutput.additionalContext
# Exit 0 always - SessionStart hooks cannot block, only inject context.

[CmdletBinding()]
param()

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

# --- Circuit breaker ---
if (Test-MMCircuitBreaker -EnvVar 'SKIP_SESSION_CONTEXT') {
    exit 0
}

# --- Collect environment facts ---
$branch = & git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -ne 0) { $branch = 'unknown' }

$lastCommit = & git log -1 --oneline 2>$null
if ($LASTEXITCODE -ne 0) { $lastCommit = 'no commits' }

$pythonCmd = Get-MMPythonCommand
$pythonVer = if ($pythonCmd) { & $pythonCmd --version 2>&1 } else { 'not found' }
if ($LASTEXITCODE -ne 0) { $pythonVer = 'not found' }

$projectRoot = Get-MMRepoRoot

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

# --- Reset subagent budget counter for new session ---
# Paired with cap-subagent-budget.ps1. Wiping the file on SessionStart guarantees
# each interactive session starts with a fresh budget.
$stateDir = Join-Path $projectRoot '.copilot\state'
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}
$budgetPath = Join-Path $stateDir 'subagent-budget.json'
$budgetSeed = [ordered]@{
    session_start = (Get-Date).ToUniversalTime().ToString('o')
    total         = 0
    by_agent      = @{}
}
try {
    ($budgetSeed | ConvertTo-Json -Depth 3) | Set-Content -Path $budgetPath -Encoding UTF8 -ErrorAction Stop
}
catch { }

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

# --- PLAN-phase story context (env var override + file fallback) ---
$storyId = $null
$storyWarnings = @()
if ($env:STORY_ID) {
    $storyId = $env:STORY_ID.Trim()
}
else {
    $activeStoryPath = Join-Path $projectRoot '.copilot\stories\.active-story'
    if (Test-Path $activeStoryPath) {
        $candidate = (Get-Content $activeStoryPath -Raw -ErrorAction SilentlyContinue)
        if ($candidate) { $storyId = $candidate.Trim() }
    }
}

$storyStatus = 'none'
if ($storyId) {
    $planPath = Join-Path $projectRoot ".copilot\stories\$storyId-PLAN.md"
    if (Test-Path $planPath) {
        $storyStatus = "$storyId (plan: .copilot/stories/$storyId-PLAN.md)"
    }
    else {
        $storyStatus = "$storyId (PLAN MISSING)"
        $storyWarnings += "WARNING (session-context): Active story is $storyId but no plan exists at .copilot/stories/$storyId-PLAN.md. If you are a BUILD agent, stop immediately. Do not write any files until the plan exists. Fix: run story-planner with story id $storyId. Next agent: story-planner."
    }

    # Git advisory (graceful fallback using existing idiom)
    $insideRepo = & git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -eq 0 -and $insideRepo -eq 'true') {
        $expectedPrefix = "story/$storyId"
        if ($branch -and $branch -ne 'unknown' -and -not $branch.StartsWith($expectedPrefix)) {
            $storyWarnings += "INFO (session-context): Active story is $storyId but current branch is '$branch'. Consider: git checkout -b $expectedPrefix-{slug}"
        }
        $dirty = & git status --porcelain 2>$null
        if ($LASTEXITCODE -eq 0 -and $dirty) {
            $storyWarnings += "INFO (session-context): Uncommitted changes detected while working on $storyId. Remember to commit before running close-story."
        }
    }
}

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
- Active story:  $storyStatus
- Hook harness:  v9.0 (14 hooks: quality-gate, scan-secrets, retrospective-check, block-holdout, block-destructive, lint-on-write, auto-format, artifact-manifest, session-context, subagent-context, pre-compact-save, scan-user-prompt, subagent-verify, cap-subagent-budget)
"@

if ($storyWarnings.Count -gt 0) {
    $ctx += "`n" + ($storyWarnings -join "`n")
}

# --- Output JSON for VS Code context injection ---
$output = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName     = 'SessionStart'
        additionalContext = $ctx
    }
} | ConvertTo-Json -Depth 5 -Compress:$false

Write-Output $output
exit 0
