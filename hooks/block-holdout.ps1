# Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |
#
# block-holdout.ps1
# PreToolUse hook: block file-read operations targeting .copilot/holdout/
# when the calling agent is a BUILD agent.
#
# Provides deterministic enforcement of the holdout access boundary defined in
# the holdout-validation skill. BUILD agents (senior-developer, data-engineer,
# ai-engineer) must never read holdout scenarios during implementation; doing so
# contaminates the evaluation result. This hook catches the attempt before the
# tool executes, converting instruction-level blindness into a hard enforcement.
#
# Intercepted tools:
#   read_file      - checks tool_input.filePath
#   list_dir       - checks tool_input.path
#   grep_search    - checks tool_input.includePattern
#   file_search    - checks tool_input.query
#   run_in_terminal - checks tool_input.command for holdout path references
#
# BUILD agents (always denied access):
#   senior-developer, data-engineer, ai-engineer
#
# Permitted agents (pass through):
#   guardian, architect, brownfield-discovery, greenfield-interview,
#   holdout-validation, researcher, data-analyst, debug-detective, Explore
#
# Unknown agent type: pass through (cannot enforce without identity; instruction-
# level enforcement remains the primary layer for unidentified callers).
#
# Env vars:
#   SKIP_HOLDOUT_GUARD=true  - bypass entirely (emergency circuit breaker)
#
# Output: JSON with permissionDecision=deny + reason, or silent exit 0 (pass).
# Exit 0 always - VS Code requires exit 0 to parse the JSON decision.

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_HOLDOUT_GUARD -eq 'true') { exit 0 }

# --- Read stdin ---
$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) { exit 0 }

$inputData = $null
try {
    $inputData = $rawInput | ConvertFrom-Json
}
catch {
    exit 0
}

# --- Determine agent type (try both field names used across hook events) ---
$agentType = ''
if ($inputData.agent_type) { $agentType = $inputData.agent_type.ToLower().Trim() }
elseif ($inputData.agent_name) { $agentType = $inputData.agent_name.ToLower().Trim() }

# Unknown agent type - cannot enforce; pass through
if (-not $agentType) { exit 0 }

# --- BUILD agent list - only these are denied ---
$buildAgents = @('senior-developer', 'data-engineer', 'ai-engineer')
if ($buildAgents -notcontains $agentType) { exit 0 }

# --- Holdout path matcher ---
# Matches .copilot/holdout or .copilot\holdout anywhere in a string
function Test-HoldoutPath {
    param([string]$Value)
    return $Value -match '\.copilot[/\\]holdout'
}

# --- Inspect the tool call ---
$toolName = if ($inputData.tool_name) { $inputData.tool_name } else { '' }
$toolInput = $inputData.tool_input

$holdoutAccess = $false
$accessedPath = ''

switch ($toolName) {
    'read_file' {
        $path = if ($toolInput -and $toolInput.filePath) { $toolInput.filePath } else { '' }
        if (Test-HoldoutPath $path) { $holdoutAccess = $true; $accessedPath = $path }
    }
    'list_dir' {
        $path = if ($toolInput -and $toolInput.path) { $toolInput.path } else { '' }
        if (Test-HoldoutPath $path) { $holdoutAccess = $true; $accessedPath = $path }
    }
    'grep_search' {
        $pattern = if ($toolInput -and $toolInput.includePattern) { $toolInput.includePattern } else { '' }
        if (Test-HoldoutPath $pattern) { $holdoutAccess = $true; $accessedPath = $pattern }
    }
    'file_search' {
        $query = if ($toolInput -and $toolInput.query) { $toolInput.query } else { '' }
        if (Test-HoldoutPath $query) { $holdoutAccess = $true; $accessedPath = $query }
    }
    'run_in_terminal' {
        $cmd = if ($toolInput -and $toolInput.command) { $toolInput.command } else { '' }
        if (Test-HoldoutPath $cmd) {
            $holdoutAccess = $true
            $accessedPath = '(shell command targeting holdout path)'
        }
    }
    default { exit 0 }
}

if (-not $holdoutAccess) { exit 0 }

# --- Deny ---
$reason = "BLOCKED (block-holdout): '$agentType' is a BUILD agent and is barred from " +
"reading .copilot/holdout/. Reading holdout scenarios during BUILD contaminates " +
"evaluation results. Only guardian, architect, or holdout-validation agents may " +
"access holdout files. Path attempted: $accessedPath. " +
"To bypass in an emergency set SKIP_HOLDOUT_GUARD=true, but be aware this " +
"invalidates any holdout evaluation for the current session."

$output = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName            = 'PreToolUse'
        permissionDecision       = 'deny'
        permissionDecisionReason = $reason
    }
} | ConvertTo-Json -Depth 5 -Compress:$false

Write-Output $output
exit 0
