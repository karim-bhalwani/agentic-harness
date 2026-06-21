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

[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_lib.ps1')

if (Test-MMCircuitBreaker -EnvVar 'SKIP_HOLDOUT_GUARD') { exit 0 }

$governanceLevel = Get-MMGovernanceLevel
$inputData = Read-MMHookInput
if (-not $inputData) { exit 0 }

$agentType = Get-MMAgentType -InputData $inputData
if (-not $agentType) { exit 0 }

# BUILD agents are denied; all others pass through.
$buildAgents = @('senior-developer', 'data-engineer', 'ai-engineer', 'data-scientist')
if ($buildAgents -notcontains $agentType) { exit 0 }

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
