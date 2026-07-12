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
$cwd = if (Get-MMProp $inputData 'cwd') { (Get-MMProp $inputData 'cwd') } else { (Get-Location).Path }

# Resolve project root (robust when git is unavailable, e.g. restricted PATH)
$projectRoot = $cwd
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitOut = & git -C $cwd rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitOut) { $projectRoot = $gitOut }
}
if ($PSVersionTable.Platform -eq 'Unix') {
    $projectRoot = $projectRoot.Trim()
}
else {
    $projectRoot = ($projectRoot -replace '/', '\').Trim()
}
# Resolve verifier scripts from the repo first (skills/ live in the project),
# then fall back to the user-install mirror at ~/.copilot for deployed setups.
$skillsRoots = @($projectRoot, (Join-Path $HOME '.copilot'))

# --- Verifier map: agent_type -> verifier scripts to run ---
# Each entry declares the expected artifact path AND the verifier. If the
# expected artifact is ABSENT, that is a verification failure (the subagent
# produced nothing), not a silent skip. This closes the gap where a subagent
# that fails to create its artifact passes verification by omission.
#
# H-03 fix: persona no longer implies mandatory artifact production. Agents
# flagged ReadOnlyByDefault (architect, guardian) are NEVER coerced into writing
# an artifact merely because of their identity. A missing artifact for them is
# logged as `verification_not_applicable` and the subagent is allowed to stop.
# Only workflow agents that are expected to produce artifacts (story-master,
# story-planner, discovery agents, build agents) are failed on a missing
# artifact. When a signed task contract exists (future work), it overrides
# these defaults and only declared artifacts are verified.
$verifierMap = @(
    @{
        Agent             = 'architect'
        Artifact          = (Join-Path $projectRoot '.copilot\specs')
        Script            = 'skills/architect/scripts/verify_spec.py'
        ReadOnlyByDefault = $true
    }
    @{
        Agent             = 'guardian'
        Artifact          = (Join-Path $projectRoot '.copilot\artifacts\review-report.md')
        Script            = 'skills/guardian/scripts/verify_review.py'
        ReadOnlyByDefault = $true
    }
    @{
        Agent    = 'brownfield-discovery|greenfield-interview'
        Artifact = (Join-Path $projectRoot '.copilot\context')
        Script   = 'skills/context-engineer/scripts/verify_bible.py'
    }
    @{
        Agent    = 'ai-engineer|data-engineer|senior-developer|data-scientist|debug-detective|release-manager|data-analyst'
        Artifact = (Join-Path $projectRoot '.copilot\state\SESSION_STATE.md')
        Script   = 'skills/context-engineer/scripts/verify_session_state.py'
    }
    @{
        Agent    = 'story-master'
        Artifact = (Join-Path $projectRoot '.copilot\stories')
        Script   = 'skills/story-master/scripts/verify_stories.py'
    }
    @{
        Agent    = 'story-planner'
        Artifact = (Join-Path $projectRoot '.copilot\stories')
        Script   = 'skills/story-planner/scripts/verify_plan.py'
    }
    @{
        Agent    = 'story-planner'
        Artifact = (Join-Path $projectRoot '.copilot\stories')
        Script   = 'skills/story-planner/scripts/verify_validation.py'
    }
)

$verifiers = @()
$missingArtifacts = [System.Collections.Generic.List[string]]::new()
$notApplicable = [System.Collections.Generic.List[string]]::new()
foreach ($entry in $verifierMap) {
    if ($agentType -match $entry.Agent) {
        if (Test-Path $entry.Artifact) {
            $verifiers += $entry.Script
        }
        elseif ($entry['ReadOnlyByDefault'] -eq $true) {
            # H-03 fix: a read-only-capable agent that produced no artifact is
            # allowed to stop. Never coerce a write from identity alone.
            $notApplicable.Add("verification_not_applicable: $($entry.Artifact) (read-only agent)")
        }
        else {
            # Workflow/build agents are expected to produce the artifact; a
            # missing one is a verification failure so a no-op subagent cannot
            # pass by omission.
            $missingArtifacts.Add("expected artifact missing: $($entry.Artifact)")
        }
    }
}

if ($verifiers.Count -eq 0 -and $missingArtifacts.Count -eq 0) {
    Write-MMHookLog -HookName 'subagent-verify' -Event 'verify_skipped' -Decision 'allow' `
        -Extra @{ agent = $agentType; mode = $mode; verifier_count = 0; failure_count = 0; note = 'no declared artifacts to verify'; not_applicable = ($notApplicable -join '; ') }
    exit 0
}

# --- Run verifiers ---
# uv is required to run the verify_*.py scripts. If it is missing, fail CLOSED
# under standard/strict/locked governance (H-08 fix): a missing verifier
# dependency must not silently weaken the gate precisely when assurance is
# lowest. Only open governance degrades to a warn-only allow for local recovery.
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    if (Test-MMFailClosed -GovernanceLevel $governanceLevel) {
        $msg = "Subagent ($agentType) finished but artifact verification could not run: 'uv' is not installed and GOVERNANCE_LEVEL=$governanceLevel fails closed. Install uv to enable verification gates."
        Write-MMHookLog -HookName 'subagent-verify' -Event 'uv_missing' -Decision 'deny' `
            -Extra @{ agent = $agentType; mode = $mode; verifier_count = $verifiers.Count; note = 'uv not on PATH; failing closed' }
        $output = [ordered]@{
            hookSpecificOutput = [ordered]@{
                hookEventName = 'SubagentStop'
                decision      = 'block'
                reason        = $msg
            }
        } | ConvertTo-Json -Depth 5 -Compress:$false
        Write-Output $output
        exit 0
    }
    Write-MMHookLog -HookName 'subagent-verify' -Event 'uv_missing' -Decision 'warn' `
        -Extra @{ agent = $agentType; mode = $mode; verifier_count = $verifiers.Count; note = 'uv not on PATH; failing open (open governance)' }
    Write-Host "WARNING (subagent-verify): 'uv' not found on PATH; skipping artifact verification. Install uv to enable verification gates."
    if ($missingArtifacts.Count -eq 0) {
        exit 0
    }
    # Fall through to the failure-reporting block below with missing-artifact
    # failures intact.
}

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($m in $missingArtifacts) {
    $failures.Add($m)
}
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
