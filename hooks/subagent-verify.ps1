# Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |
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
#   SUBAGENT_VERIFY_MODE=warn  - log failures without blocking (default: block)
#
# Output: JSON with decision=block (only on verifier failure) or empty pass-through.
# Exit 0 always when JSON is emitted (VS Code requires exit 0 to parse decisions).

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_SUBAGENT_VERIFY -eq 'true') { exit 0 }

$mode = if ($env:SUBAGENT_VERIFY_MODE) { $env:SUBAGENT_VERIFY_MODE } else { 'block' }

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

if ($verifiers.Count -eq 0) { exit 0 }

# --- Run verifiers ---
$failures = [System.Collections.Generic.List[string]]::new()
foreach ($v in $verifiers) {
    $script = Join-Path $projectRoot $v
    if (-not (Test-Path $script)) { continue }
    $null = & uv run --project $projectRoot $script 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failures.Add("$v failed (exit $LASTEXITCODE)")
    }
}

if ($failures.Count -eq 0) { exit 0 }

$msg = "Subagent ($agentType) finished but artifact verification failed:`n - " + ($failures -join "`n - ") +
"`nRe-run the subagent or fill the missing artifact before continuing."

if ($mode -eq 'warn') {
    Write-Host "WARNING: $msg"
    exit 0
}

$output = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName = 'SubagentStop'
        decision      = 'block'
        reason        = $msg
    }
} | ConvertTo-Json -Depth 5 -Compress:$false

Write-Output $output
exit 0
