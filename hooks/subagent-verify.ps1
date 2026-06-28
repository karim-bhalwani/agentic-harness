# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# subagent-verify.ps1
# SubagentStop hook: verify expected artifacts after a subagent finishes.
#
# When a subagent claims it produced an artifact (spec, holdout, review report,
# session state, story backlog, story plan), this hook runs the corresponding
# verify_*.py to confirm the file actually landed and is not a stub. If
# verification fails, the hook reports back via decision=block so the
# orchestrating agent knows to retry.
#
# Lookups are best-effort: the hook reads the subagent's agent_type and runs
# the verifier(s) most relevant to that agent. Missing verifiers are silently
# skipped. The hook never crashes the agent harness on its own errors.
#
# Env vars:
#   SKIP_SUBAGENT_VERIFY=true  - bypass entirely (emergency circuit breaker)
#   SUBAGENT_VERIFY_MODE=warn|block - explicit mode override
#   GOVERNANCE_LEVEL=open|standard|strict|locked (default: standard)
#   HOOK_LOG_DIR=<path>        - override structured hook log directory
#
# Output: JSON with decision=block (only on verifier failure) or empty pass-through.
# Exit 0 always when JSON is emitted (VS Code requires exit 0 to parse decisions).

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

# --- Circuit breaker ---
if (Test-MMCircuitBreaker -EnvVar 'SKIP_SUBAGENT_VERIFY') { exit 0 }

$governanceLevel = Get-MMGovernanceLevel
$mode = Resolve-MMMode -OverrideEnvVar 'SUBAGENT_VERIFY_MODE' -GovernanceLevel $governanceLevel `
    -StrictDefault 'block' -StandardDefault 'block' -OpenDefault 'warn'

# --- Read stdin ---
$inputData = Read-MMHookInput
if (-not $inputData) { exit 0 }

$agentType = Get-MMAgentType -InputData $inputData
$cwd = if ($inputData.cwd) { $inputData.cwd } else { (Get-Location).Path }

# Resolve project root
$projectRoot = & git -C $cwd rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $projectRoot) { $projectRoot = $cwd }
if ($PSVersionTable.Platform -eq 'Unix') {
    $projectRoot = $projectRoot.Trim()
} else {
    $projectRoot = ($projectRoot -replace '/', '\').Trim()
}
# Resolve verifier scripts from the repo first (skills/ live in the project),
# then fall back to the user-install mirror at ~/.copilot for deployed setups.
$skillsRoots = @($projectRoot, (Join-Path $HOME '.copilot'))

# --- Verifier map: agent_type -> verifier scripts to run ---
# Only run a verifier if the artifact directory already exists (avoids false
# negatives when the subagent did not run a producing phase).
$verifiers = @()

switch -Regex ($agentType) {
    'architect' {
        if (Test-Path (Join-Path $projectRoot '.copilot\specs')) {
            $verifiers += 'skills/architect/scripts/verify_spec.py'
        }
    }
    'guardian' {
        if (Test-Path (Join-Path $projectRoot '.copilot\artifacts\review-report.md')) {
            $verifiers += 'skills/guardian/scripts/verify_review.py'
        }
    }
    'brownfield-discovery|greenfield-interview' {
        if (Test-Path (Join-Path $projectRoot '.copilot\context')) {
            $verifiers += 'skills/context-engineer/scripts/verify_bible.py'
        }
    }
    'ai-engineer|data-engineer|senior-developer|data-scientist|debug-detective|release-manager|data-analyst' {
        if (Test-Path (Join-Path $projectRoot '.copilot\state\SESSION_STATE.md')) {
            $verifiers += 'skills/context-engineer/scripts/verify_session_state.py'
        }
    }
    'story-master' {
        if (Test-Path (Join-Path $projectRoot '.copilot\stories')) {
            $verifiers += 'skills/story-master/scripts/verify_stories.py'
        }
    }
    'story-planner' {
        if (Test-Path (Join-Path $projectRoot '.copilot\stories')) {
            $verifiers += 'skills/story-planner/scripts/verify_plan.py'
            $verifiers += 'skills/story-planner/scripts/verify_validation.py'
        }
    }
    default { }
}

if ($verifiers.Count -eq 0) {
    Write-MMHookLog -HookName 'subagent-verify' -Event 'verify_skipped' -Decision 'allow' `
        -Extra @{ agent = $agentType; mode = $mode; verifier_count = 0; failure_count = 0 }
    exit 0
}

# --- Run verifiers ---
# uv is required to run the verify_*.py scripts. If it is missing, fail open
# with a warning rather than false-positive blocking (the harness "never crash
# the agent" contract). Document this so operators know to install uv.
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-MMHookLog -HookName 'subagent-verify' -Event 'uv_missing' -Decision 'warn' `
        -Extra @{ agent = $agentType; mode = $mode; verifier_count = $verifiers.Count; note = 'uv not on PATH; failing open' }
    Write-Host "WARNING (subagent-verify): 'uv' not found on PATH; skipping artifact verification. Install uv to enable verification gates."
    exit 0
}

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($v in $verifiers) {
    $vNative = if ($PSVersionTable.Platform -eq 'Unix') { $v } else { $v -replace '/', '\' }
    $script = $null
    foreach ($root in $skillsRoots) {
        $candidate = Join-Path $root $vNative
        if (Test-Path $candidate) { $script = $candidate; break }
    }
    if (-not $script) { continue }
    $null = & uv run --project $projectRoot $script 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failures.Add("$v failed (exit $LASTEXITCODE)")
    }
}

if ($failures.Count -eq 0) {
    Write-MMHookLog -HookName 'subagent-verify' -Event 'verify_complete' -Decision 'allow' `
        -Extra @{ agent = $agentType; mode = $mode; verifier_count = $verifiers.Count; failure_count = 0 }
    exit 0
}

$msg = "Subagent ($agentType) finished but artifact verification failed:`n - " + ($failures -join "`n - ") +
"`nRe-run the subagent or fill the missing artifact before continuing."

if ($mode -eq 'warn') {
    Write-MMHookLog -HookName 'subagent-verify' -Event 'verify_failed' -Decision 'allow' `
        -Extra @{ agent = $agentType; mode = $mode; verifier_count = $verifiers.Count; failure_count = $failures.Count }
    Write-Host "WARNING: $msg"
    exit 0
}

Write-MMHookLog -HookName 'subagent-verify' -Event 'verify_failed' -Decision 'deny' `
    -Extra @{ agent = $agentType; mode = $mode; verifier_count = $verifiers.Count; failure_count = $failures.Count }

$output = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName = 'SubagentStop'
        decision      = 'block'
        reason        = $msg
    }
} | ConvertTo-Json -Depth 5 -Compress:$false

Write-Output $output
exit 0
