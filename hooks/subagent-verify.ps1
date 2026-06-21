# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# subagent-verify.ps1
# SubagentStop hook: verify expected artifacts after a subagent finishes.
#
# When a subagent claims it produced an artifact (spec, holdout, review report,
# session state, story backlog, story plan), this hook runs the corresponding
# verify_*.py to confirm the file actually landed and is not a stub. If
# verification fails, the hook reports back via decision=block so the
#ack via decision=block so the
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

[CmdletBinding()]
param()

function Get-GovernanceLevel {
    $level = if ($env:GOVERNANCE_LEVEL) { $env:GOVERNANCE_LEVEL.ToLowerInvariant() } else { 'standard' }
    if ($level -notin @('open', 'standard', 'strict', 'locked')) { return 'standard' }
    return $level
}

function Resolve-VerifyMode {
    param([string]$GovernanceLevel)

    if ($env:SUBAGENT_VERIFY_MODE) { return $env:SUBAGENT_VERIFY_MODE }

    switch ($GovernanceLevel) {
        'strict' { return 'block' }
        'locked' { return 'block' }
        default { return 'warn' }
    }
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
        return Join-Path $logDir 'subagent-verify.jsonl'
    }
    catch {
        return $null
    }
}

function Write-HookLog {
    param(
        [string]$Event,
        [string]$AgentType,
        [string]$Mode,
        [string]$GovernanceLevel,
        [string]$Decision,
        [int]$VerifierCount,
        [int]$FailureCount
    )

    $path = Get-HookLogPath
    if (-not $path) { return }

    $entry = [ordered]@{
        timestamp      = (Get-Date).ToUniversalTime().ToString('o')
        hook           = 'subagent-verify'
        event          = $Event
        agent          = $AgentType
        mode           = $Mode
        governance     = $GovernanceLevel
        decision       = $Decision
        verifier_count = $VerifierCount
        failure_count  = $FailureCount
    }

    try {
        Add-Content -Path $path -Value ($entry | ConvertTo-Json -Compress) -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        # Logging failure must never fail the hook decision path.
    }
}

# --- Circuit breaker ---
if ($env:SKIP_SUBAGENT_VERIFY -eq 'true') { exit 0 }

$governanceLevel = Get-GovernanceLevel
$mode = Resolve-VerifyMode -GovernanceLevel $governanceLevel

# --- Read stdin ---
$rawInput = [Console]::In.ReadToEnd()
$inputData = $null
if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
    try { $inputData = $rawInput | ConvertFrom-Json } catch { exit 0 }
}

$agentType = if ($inputData -and $inputData.agent_type) { $inputData.agent_type } else { '' }
$cwd = if ($inputData -and $inputData.cwd) { $inputData.cwd } else { (Get-Location).Path }

# Resolve project root
$projectRoot = & git -C $cwd rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $projectRoot) { $projectRoot = $cwd }
$projectRoot = $projectRoot -replace '/', '\'
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
    'ai-engineer|data-engineer|senior-developer|debug-detective|release-manager|data-analyst' {
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
    Write-HookLog -Event 'verify_skipped' -AgentType $agentType -Mode $mode -GovernanceLevel $governanceLevel -Decision 'allow' -VerifierCount 0 -FailureCount 0
    exit 0
}

# --- Run verifiers ---
$failures = [System.Collections.Generic.List[string]]::new()
foreach ($v in $verifiers) {
    $vNative = $v -replace '/', '\'
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
    Write-HookLog -Event 'verify_complete' -AgentType $agentType -Mode $mode -GovernanceLevel $governanceLevel -Decision 'allow' -VerifierCount $verifiers.Count -FailureCount 0
    exit 0
}

$msg = "Subagent ($agentType) finished but artifact verification failed:`n - " + ($failures -join "`n - ") +
"`nRe-run the subagent or fill the missing artifact before continuing."

if ($mode -eq 'warn') {
    Write-HookLog -Event 'verify_failed' -AgentType $agentType -Mode $mode -GovernanceLevel $governanceLevel -Decision 'allow' -VerifierCount $verifiers.Count -FailureCount $failures.Count
    Write-Host "WARNING: $msg"
    exit 0
}

Write-HookLog -Event 'verify_failed' -AgentType $agentType -Mode $mode -GovernanceLevel $governanceLevel -Decision 'deny' -VerifierCount $verifiers.Count -FailureCount $failures.Count

$output = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName = 'SubagentStop'
        decision      = 'block'
        reason        = $msg
    }
} | ConvertTo-Json -Depth 5 -Compress:$false

Write-Output $output
exit 0
