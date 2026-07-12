# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# cap-subagent-budget.ps1
# PreToolUse hook: enforce per-session caps on subagent launches.
#
# Closes the "Researcher hidden subagent has no budget cap" architectural gap:
# a misbehaving orchestrator could otherwise fan out into unbounded parallel
# subagents (especially the Researcher) and burn through token budget.
#
# How it works:
#   * Counter file: .copilot/state/subagent-budget.json
#     (initialised by session-context.ps1 on SessionStart, see that hook.)
#   * Every PreToolUse for tool_name == 'runSubagent' atomically increments the
#     per-agent counter, then compares to the configured caps.
#   * When over budget, the hook denies the tool call with a reason that tells
#     the orchestrator which budget was exceeded and how to raise it.
#
# Env vars:
#   SKIP_SUBAGENT_BUDGET=true       - emergency circuit breaker
#   SUBAGENT_BUDGET_TOTAL=<int>      - total subagent launches per session (default 30)
#   SUBAGENT_BUDGET_RESEARCHER=<int> - cap specifically for the hidden Researcher (default 10)
#   SUBAGENT_BUDGET_<AGENT>=<int>    - per-agent override, UPPER_SNAKE form
#                                      (e.g. SUBAGENT_BUDGET_GUARDIAN=5)
#   GOVERNANCE_LEVEL=open            - warn instead of block

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot '_lib.ps1')

if (Test-MMCircuitBreaker -EnvVar 'SKIP_SUBAGENT_BUDGET') { exit 0 }

$governanceLevel = Get-MMGovernanceLevel
$inputData = Read-MMHookInput
if (-not $inputData) { exit 0 }

try {
    # Only PreToolUse calls that launch a subagent are interesting.
    if ((Get-MMProp $inputData 'tool_name') -ne 'runSubagent') { exit 0 }

    $toolInput = Get-MMProp $inputData 'tool_input' $null
    $subAgentName = ''
    if ($toolInput) {
        $agentName = Get-MMProp $toolInput 'agentName' $null
        if (-not $agentName) { $agentName = Get-MMProp $toolInput 'agent_name' $null }
        if ($agentName) { $subAgentName = "$agentName".ToLower().Trim() }
    }
    if (-not $subAgentName) { $subAgentName = 'unknown' }

    $repoRoot = Get-MMRepoRoot
    $stateDir = Join-Path $repoRoot '.copilot\state'
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
    $counterPath = Join-Path $stateDir 'subagent-budget.json'

    # --- Resolve caps ---
    $totalCap = if ($env:SUBAGENT_BUDGET_TOTAL) { [int]$env:SUBAGENT_BUDGET_TOTAL } else { 30 }
    $researcherCap = if ($env:SUBAGENT_BUDGET_RESEARCHER) { [int]$env:SUBAGENT_BUDGET_RESEARCHER } else { 10 }

    $perAgentEnvName = 'SUBAGENT_BUDGET_' + ($subAgentName.ToUpper() -replace '-', '_')
    $perAgentCap = [Environment]::GetEnvironmentVariable($perAgentEnvName)
    if ($perAgentCap) {
        $agentCap = [int]$perAgentCap
    }
    elseif ($subAgentName -eq 'researcher') {
        $agentCap = $researcherCap
    }
    else {
        $agentCap = $totalCap  # individual cap defaults to total cap
    }

    # If the counter file exists but cannot be parsed, the budget state is
    # untrustworthy. Under standard/strict/locked governance we must DENY rather
    # than silently reset and allow (which would weaken the cap precisely when
    # assurance is lowest). Only open governance recovers by resetting.
    if (Test-Path $counterPath) {
        $rawContent = $null
        try { $rawContent = Get-Content $counterPath -Raw -ErrorAction Stop } catch { }
        if ($null -ne $rawContent) {
            try {
                $null = $rawContent | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                if (Test-MMFailClosed -GovernanceLevel $governanceLevel) {
                    $reason = "BLOCKED (cap-subagent-budget): budget counter file is corrupt and GOVERNANCE_LEVEL=$governanceLevel fails closed. Inspect or delete .copilot/state/subagent-budget.json."
                    Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'counter_corrupt' -Decision 'deny' `
                        -Extra @{ agent = $subAgentName; note = 'corrupt counter file; failing closed' }
                    Write-MMHookDecision -Decision 'deny' -Reason $reason
                    exit 0
                }
                Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'counter_corrupt' -Decision 'warn' `
                    -Extra @{ agent = $subAgentName; note = 'corrupt counter file; resetting (open governance)' }
            }
        }
    }

    # --- Atomic read-modify-write of the counter file ---
    # Uses an exclusive FileStream lock (Invoke-MMLockedFileOp) so concurrent
    # PreToolUse invocations cannot race past each other and both increment
    # from the same baseline. The scriptblock receives the current raw JSON
    # (or $null) and returns a JSON STRING to persist. That JSON encodes both
    # the counters to write AND the decision metadata, so the caller can parse
    # the decision out of the returned string. (Invoke-MMLockedFileOp writes
    # exactly the scriptblock's return value to disk.)
    $writtenJson = Invoke-MMLockedFileOp -Path $counterPath -ScriptBlock {
        param($raw)

        $counters = [ordered]@{
            session_start = (Get-Date).ToUniversalTime().ToString('o')
            total         = 0
            by_agent      = @{ }
        }
        if ($raw) {
            try {
                $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
                # The persisted file is a decision envelope whose .counters holds
                # the actual counter state. Fall back to the legacy flat shape
                # (bare counters) for files written by older hook versions.
                $src = if ($parsed.counters) { $parsed.counters } else { $parsed }
                if ($src.session_start) { $counters.session_start = $src.session_start }
                if ($src.total) { $counters.total = [int]$src.total }
                if ($src.by_agent) {
                    $counters.by_agent = @{ }
                    foreach ($p in $src.by_agent.PSObject.Properties) {
                        $counters.by_agent[$p.Name] = [int]$p.Value
                    }
                }
            }
            catch {
                # Corrupt counter file - reset rather than fail the build.
                $counters.total = 0
                $counters.by_agent = @{ }
            }
        }

        $currentForAgent = if ($counters.by_agent.ContainsKey($subAgentName)) { [int]$counters.by_agent[$subAgentName] } else { 0 }
        $projectedTotal = $counters.total + 1
        $projectedAgent = $currentForAgent + 1

        $overTotal = $projectedTotal -gt $totalCap
        $overAgent = $projectedAgent -gt $agentCap

        if (-not $overTotal -and -not $overAgent) {
            # Commit the increment and allow.
            $counters.total = $projectedTotal
            $counters.by_agent[$subAgentName] = $projectedAgent
            $envelope = [ordered]@{
                counters     = $counters
                decision     = 'allow'
                currentTotal = $counters.total
                currentAgent = $projectedAgent
                agentCap     = $agentCap
                totalCap     = $totalCap
                overTotal    = $false
                overAgent    = $false
            }
            return ($envelope | ConvertTo-Json -Depth 5)
        }
        # Over budget - do NOT commit the increment (deny path). Persist the
        # unchanged counters so the file stays consistent for the next caller.
        $envelope = [ordered]@{
            counters     = $counters
            decision     = 'deny'
            currentTotal = $counters.total
            currentAgent = $currentForAgent
            agentCap     = $agentCap
            totalCap     = $totalCap
            overTotal    = $overTotal
            overAgent    = $overAgent
        }
        return ($envelope | ConvertTo-Json -Depth 5)
    }

    # Fallback: if the locked op failed entirely (e.g. lock contention beyond
    # the FileStream timeout), fail CLOSED under standard/strict/locked governance
    # lowest. Only open governance degrades to a warn-only allow for local recovery.
    if (-not $writtenJson) {
        if (Test-MMFailClosed -GovernanceLevel $governanceLevel) {
            $reason = "BLOCKED (cap-subagent-budget): could not acquire the budget counter lock after retries and GOVERNANCE_LEVEL=$governanceLevel fails closed. Retry the launch; if this persists, another process is holding .copilot/state/subagent-budget.json open (editor, file watcher, or a stuck hook) - close the handle or set SKIP_SUBAGENT_BUDGET=true to bypass."
            Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'lock_failure' -Decision 'deny' `
                -Extra @{ agent = $subAgentName; note = 'Invoke-MMLockedFileOp returned null; failing closed' }
            Write-MMHookDecision -Decision 'deny' -Reason $reason
            exit 0
        }
        Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'lock_failure' -Decision 'warn' `
            -Extra @{ agent = $subAgentName; note = 'Invoke-MMLockedFileOp returned null; failing open (open governance)' }
        Write-Host "WARNING (cap-subagent-budget): could not acquire budget counter lock; allowing launch (fail-open)."
        exit 0
    }

    # Parse the decision envelope out of the persisted JSON.
    try {
        $decision = $writtenJson | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        if (Test-MMFailClosed -GovernanceLevel $governanceLevel) {
            $reason = "BLOCKED (cap-subagent-budget): could not parse the budget decision envelope and GOVERNANCE_LEVEL=$governanceLevel fails closed. Inspect .copilot/state/subagent-budget.json for corruption."
            Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'envelope_parse_failure' -Decision 'deny' `
                -Extra @{ agent = $subAgentName; note = 'could not parse decision envelope; failing closed' }
            Write-MMHookDecision -Decision 'deny' -Reason $reason
            exit 0
        }
        Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'envelope_parse_failure' -Decision 'warn' `
            -Extra @{ agent = $subAgentName; note = 'could not parse decision envelope; failing open (open governance)' }
        Write-Host "WARNING (cap-subagent-budget): could not parse budget decision envelope; allowing launch (fail-open)."
        exit 0
    }

    if ($decision.decision -eq 'allow') {
        Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'launch_allowed' -Decision 'allow' `
            -Extra @{ agent = $subAgentName; agent_count = $decision.currentAgent; total_count = $decision.currentTotal; agent_cap = $decision.agentCap; total_cap = $decision.totalCap }
        exit 0
    }

    # --- Deny path ---
    $reason = if ($decision.overAgent -and $decision.overTotal) {
        "BLOCKED (cap-subagent-budget): subagent '$subAgentName' would exceed both the per-agent cap ($($decision.agentCap)) AND the per-session total cap ($($decision.totalCap))."
    }
    elseif ($decision.overAgent) {
        "BLOCKED (cap-subagent-budget): subagent '$subAgentName' would exceed its per-agent cap ($($decision.agentCap)). Raise via env var $perAgentEnvName=<higher> if intentional."
    }
    else {
        "BLOCKED (cap-subagent-budget): per-session subagent total would exceed the cap ($($decision.totalCap)). Raise via SUBAGENT_BUDGET_TOTAL=<higher> if intentional, or reduce delegation fan-out."
    }
    $reason += " Current: $($decision.currentTotal) total, $($decision.currentAgent) for '$subAgentName'. Skip with SKIP_SUBAGENT_BUDGET=true."

    if ($governanceLevel -eq 'open') {
        Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'launch_over_budget' -Decision 'warn' `
            -Extra @{ agent = $subAgentName; agent_count = ($decision.currentAgent + 1); total_count = ($decision.currentTotal + 1); agent_cap = $decision.agentCap; total_cap = $decision.totalCap; note = 'governance=open' }
        Write-Host "WARNING (cap-subagent-budget): $reason"
        exit 0
    }

    Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'launch_over_budget' -Decision 'deny' `
        -Extra @{ agent = $subAgentName; agent_count = ($decision.currentAgent + 1); total_count = ($decision.currentTotal + 1); agent_cap = $decision.agentCap; total_cap = $decision.totalCap }

    Write-MMHookDecision -Decision 'deny' -Reason $reason
    exit 0
}
catch {
    # A crash in the guard body must NOT let the subagent launch proceed
    # silently (that would bypass the budget cap). Fail closed.
    Write-MMHookFailClosedDeny -HookName 'cap-subagent-budget' -Exception $_
}
