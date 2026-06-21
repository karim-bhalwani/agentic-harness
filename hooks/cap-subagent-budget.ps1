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

[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_lib.ps1')

if (Test-MMCircuitBreaker -EnvVar 'SKIP_SUBAGENT_BUDGET') { exit 0 }

$governanceLevel = Get-MMGovernanceLevel
$inputData = Read-MMHookInput
if (-not $inputData) { exit 0 }

# Only PreToolUse calls that launch a subagent are interesting.
if ($inputData.tool_name -ne 'runSubagent') { exit 0 }

$toolInput = $inputData.tool_input
$subAgentName = ''
if ($toolInput) {
    if ($toolInput.agentName) { $subAgentName = "$($toolInput.agentName)".ToLower().Trim() }
    elseif ($toolInput.agent_name) { $subAgentName = "$($toolInput.agent_name)".ToLower().Trim() }
}
if (-not $subAgentName) { $subAgentName = 'unknown' }

$repoRoot = Get-MMRepoRoot
$stateDir = Join-Path $repoRoot '.copilot\state'
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}
$counterPath = Join-Path $stateDir 'subagent-budget.json'

# --- Atomic read-modify-write of the counter file ---
$counters = [ordered]@{
    session_start = (Get-Date).ToUniversalTime().ToString('o')
    total         = 0
    by_agent      = @{}
}
if (Test-Path $counterPath) {
    try {
        $raw = Get-Content -Path $counterPath -Raw -ErrorAction Stop
        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
        if ($parsed.session_start) { $counters.session_start = $parsed.session_start }
        if ($parsed.total) { $counters.total = [int]$parsed.total }
        if ($parsed.by_agent) {
            $counters.by_agent = @{}
            foreach ($p in $parsed.by_agent.PSObject.Properties) {
                $counters.by_agent[$p.Name] = [int]$p.Value
            }
        }
    }
    catch {
        # Corrupt counter file - reset rather than fail the build.
        $counters.total = 0
        $counters.by_agent = @{}
    }
}

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

$currentForAgent = if ($counters.by_agent.ContainsKey($subAgentName)) { [int]$counters.by_agent[$subAgentName] } else { 0 }
$projectedTotal = $counters.total + 1
$projectedAgent = $currentForAgent + 1

$overTotal = $projectedTotal -gt $totalCap
$overAgent = $projectedAgent -gt $agentCap

if (-not $overTotal -and -not $overAgent) {
    # Commit the increment and allow.
    $counters.total = $projectedTotal
    $counters.by_agent[$subAgentName] = $projectedAgent
    try {
        ($counters | ConvertTo-Json -Depth 4) | Set-Content -Path $counterPath -Encoding UTF8 -ErrorAction Stop
    }
    catch { }
    Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'launch_allowed' -Decision 'allow' `
        -Extra @{ agent = $subAgentName; agent_count = $projectedAgent; total_count = $projectedTotal; agent_cap = $agentCap; total_cap = $totalCap }
    exit 0
}

$reason = if ($overAgent -and $overTotal) {
    "BLOCKED (cap-subagent-budget): subagent '$subAgentName' would exceed both the per-agent cap ($agentCap) AND the per-session total cap ($totalCap)."
}
elseif ($overAgent) {
    "BLOCKED (cap-subagent-budget): subagent '$subAgentName' would exceed its per-agent cap ($agentCap). Raise via env var $perAgentEnvName=<higher> if intentional."
}
else {
    "BLOCKED (cap-subagent-budget): per-session subagent total would exceed the cap ($totalCap). Raise via SUBAGENT_BUDGET_TOTAL=<higher> if intentional, or reduce delegation fan-out."
}
$reason += " Current: $($counters.total) total, $currentForAgent for '$subAgentName'. Skip with SKIP_SUBAGENT_BUDGET=true."

if ($governanceLevel -eq 'open') {
    Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'launch_over_budget' -Decision 'warn' `
        -Extra @{ agent = $subAgentName; agent_count = $projectedAgent; total_count = $projectedTotal; agent_cap = $agentCap; total_cap = $totalCap; note = 'governance=open' }
    Write-Host "WARNING (cap-subagent-budget): $reason"
    # Still commit the increment so telemetry is accurate.
    $counters.total = $projectedTotal
    $counters.by_agent[$subAgentName] = $projectedAgent
    try { ($counters | ConvertTo-Json -Depth 4) | Set-Content -Path $counterPath -Encoding UTF8 -ErrorAction Stop } catch { }
    exit 0
}

Write-MMHookLog -HookName 'cap-subagent-budget' -Event 'launch_over_budget' -Decision 'deny' `
    -Extra @{ agent = $subAgentName; agent_count = $projectedAgent; total_count = $projectedTotal; agent_cap = $agentCap; total_cap = $totalCap }

Write-MMHookDecision -Decision 'deny' -Reason $reason
exit 0
