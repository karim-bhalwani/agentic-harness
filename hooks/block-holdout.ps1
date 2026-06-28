# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# block-holdout.ps1
# PreToolUse hook: block file-read operations targeting .copilot/holdout/
# when the calling agent is a BUILD agent.
#
# Env vars:
#   SKIP_HOLDOUT_GUARD=true  - emergency circuit breaker
#   GOVERNANCE_LEVEL=open|standard|strict|locked (default: standard)
#   HOOK_LOG_DIR=<path>      - override structured hook log directory

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot '_lib.ps1')

if (Test-MMCircuitBreaker -EnvVar 'SKIP_HOLDOUT_GUARD') { exit 0 }

$governanceLevel = Get-MMGovernanceLevel
$inputData = Read-MMHookInput
if (-not $inputData) { exit 0 }

$agentType = Get-MMAgentType -InputData $inputData

# Identity policy: when the caller does not declare an agent_type/agent_name,
# default to deny on holdout paths unless governance=open. This closes the
# residual instruction-only gap noted in CORE_PRINCIPLES.md.
# Trusted non-BUILD agents that MAY access holdout files.
$holdoutReaders = @('guardian', 'architect', 'holdout-validation', 'release-manager')
$buildAgents = @('senior-developer', 'data-engineer', 'ai-engineer', 'data-scientist')

if (-not $agentType) {
    # Unknown caller: only allowed when governance is fully open.
    if ($governanceLevel -eq 'open') { exit 0 }
    # Otherwise continue into path inspection so we can deny holdout access.
    $agentType = 'unknown'
}
elseif ($holdoutReaders -contains $agentType) {
    # Trusted readers always pass through.
    exit 0
}
elseif ($buildAgents -notcontains $agentType -and $agentType -ne 'unknown') {
    # Any other identified agent is not a BUILD agent and not in the reader
    # allowlist; pass through (e.g. debug-detective, prompt-builder).
    exit 0
}

function Test-HoldoutPath {
    param([string]$Value)
    return $Value -match '\.copilot[/\\]holdout'
}

$toolName = if ($inputData.tool_name) { $inputData.tool_name } else { '' }
$toolInput = $inputData.tool_input
$accessedPath = ''
$holdoutAccess = $false

switch ($toolName) {
    'read_file' {
        $p = if ($toolInput -and $toolInput.filePath) { $toolInput.filePath } else { '' }
        if (Test-HoldoutPath $p) { $holdoutAccess = $true; $accessedPath = $p }
    }
    'list_dir' {
        $p = if ($toolInput -and $toolInput.path) { $toolInput.path } else { '' }
        if (Test-HoldoutPath $p) { $holdoutAccess = $true; $accessedPath = $p }
    }
    'grep_search' {
        $p = if ($toolInput -and $toolInput.includePattern) { $toolInput.includePattern } else { '' }
        if (Test-HoldoutPath $p) { $holdoutAccess = $true; $accessedPath = $p }
    }
    'file_search' {
        $p = if ($toolInput -and $toolInput.query) { $toolInput.query } else { '' }
        if (Test-HoldoutPath $p) { $holdoutAccess = $true; $accessedPath = $p }
    }
    'run_in_terminal' {
        $p = if ($toolInput -and $toolInput.command) { $toolInput.command } else { '' }
        if (Test-HoldoutPath $p) {
            $holdoutAccess = $true
            $accessedPath = '(shell command targeting holdout path)'
        }
    }
    default { exit 0 }
}

if (-not $holdoutAccess) {
    Write-MMHookLog -HookName 'block-holdout' -Event 'scan_complete' -Decision 'allow' `
        -Extra @{ agent = $agentType; tool = $toolName; path = '' }
    exit 0
}

if ($governanceLevel -eq 'open') {
    Write-MMHookLog -HookName 'block-holdout' -Event 'holdout_access_detected' -Decision 'allow' `
        -Extra @{ agent = $agentType; tool = $toolName; path = $accessedPath; note = 'governance=open' }
    Write-Host "WARNING (block-holdout): '$agentType' targeted holdout path but was allowed because GOVERNANCE_LEVEL=open"
    exit 0
}

$reason = "BLOCKED (block-holdout): '$agentType' is a BUILD agent and is barred from " +
"reading .copilot/holdout/. Reading holdout scenarios during BUILD contaminates " +
"evaluation results. Only guardian, architect, or holdout-validation agents may " +
"access holdout files. Path attempted: $accessedPath. " +
"To bypass in an emergency set SKIP_HOLDOUT_GUARD=true, but be aware this " +
"invalidates any holdout evaluation for the current session."

Write-MMHookLog -HookName 'block-holdout' -Event 'holdout_access_detected' -Decision 'deny' `
    -Extra @{ agent = $agentType; tool = $toolName; path = $accessedPath }

Write-MMHookDecision -Decision 'deny' -Reason $reason
exit 0
