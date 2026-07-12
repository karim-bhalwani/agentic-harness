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

try {
    $agentType = Get-MMAgentType -InputData $inputData

    # Identity policy: when the caller does not declare an agent_type/agent_name,
    # default to deny on holdout paths unless governance=open. This closes the
    # residual instruction-only gap noted in CORE_PRINCIPLES.md.
    # Trusted non-BUILD agents that MAY access holdout files.
    $holdoutReaders = @('guardian', 'architect', 'holdout-validation', 'release-manager')
    $buildAgents = @('senior-developer', 'data-engineer', 'ai-engineer', 'data-scientist', 'data-analyst')

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
        <#
    .SYNOPSIS True when the value resolves to the canonical holdout root.
    .DESCRIPTION Canonicalizes traversal, relative segments, and aliases before
                 comparing to the resolved .copilot/holdout directory, so
                 indirection such as `.copilot/stories/../holdout` is denied.
                 Environment variables in the token are expanded first, and the
                 value is resolved against BOTH the process CWD and the repo
                 root, so `cd .copilot; cat holdout/x` and `$env:VAR` indirection
                 are both denied.
    #>
        param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
        # Fast literal pre-check keeps the common case cheap.
        if ($Value -match '\.copilot[/\\]holdout') { return $true }
        # Expand environment variables before resolution. Handle both the Windows
        # %VAR% form (via ExpandEnvironmentVariables) and the PowerShell $env:VAR
        # form (literal substitution), so `$env:HOLD/holdout/x` is denied.
        $expanded = [Environment]::ExpandEnvironmentVariables($Value)
        $expanded = [regex]::Replace($expanded, '\$env:([A-Za-z_][A-Za-z0-9_]*)', {
                param($m)
                $v = [Environment]::GetEnvironmentVariable($m.Groups[1].Value)
                if ($null -eq $v) { return $m.Value }
                return $v
            })
        $repoRoot = Get-MMRepoRoot
        $holdoutRoot = Join-Path $repoRoot '.copilot\holdout'
        $candidates = @($expanded)
        # Resolve against the process CWD as well as the repo root, because a hook
        # payload may carry a CWD-relative path after the agent did `cd .copilot`.
        $cwd = (Get-Location).Path
        if ($cwd -and $cwd -ne $repoRoot) { $candidates += (Join-Path $cwd $expanded) }
        foreach ($c in $candidates) {
            $resolved = Resolve-MMCanonicalPath -Value $c
            if (-not $resolved) { continue }
            if (Test-MMPathUnderRoot -Path $resolved -Root $holdoutRoot) { return $true }
        }
        return $false
    }

    $toolName = if (Get-MMProp $inputData 'tool_name') { (Get-MMProp $inputData 'tool_name') } else { '' }
    $toolInput = Get-MMProp $inputData 'tool_input' $null
    $accessedPath = ''
    $holdoutAccess = $false

    switch ($toolName) {
        'read_file' {
            $p = if ($toolInput -and (Get-MMProp $toolInput 'filePath')) { (Get-MMProp $toolInput 'filePath') } else { '' }
            if (Test-HoldoutPath $p) { $holdoutAccess = $true; $accessedPath = $p }
        }
        'list_dir' {
            $p = if ($toolInput -and (Get-MMProp $toolInput 'path')) { (Get-MMProp $toolInput 'path') } else { '' }
            if (Test-HoldoutPath $p) { $holdoutAccess = $true; $accessedPath = $p }
        }
        'grep_search' {
            # Inspect every path-bearing field, not just includePattern. A build
            # agent can otherwise evade the block by passing the holdout path in
            # path/query/glob instead of includePattern.
            $candidates = @(
                if ($toolInput -and (Get-MMProp $toolInput 'includePattern')) { (Get-MMProp $toolInput 'includePattern') }
                if ($toolInput -and (Get-MMProp $toolInput 'path')) { (Get-MMProp $toolInput 'path') }
                if ($toolInput -and (Get-MMProp $toolInput 'query')) { (Get-MMProp $toolInput 'query') }
                if ($toolInput -and (Get-MMProp $toolInput 'glob')) { (Get-MMProp $toolInput 'glob') }
            )
            foreach ($c in $candidates) {
                if ($c -and (Test-HoldoutPath $c)) { $holdoutAccess = $true; $accessedPath = $c; break }
            }
        }
        'file_search' {
            $p = if ($toolInput -and (Get-MMProp $toolInput 'query')) { (Get-MMProp $toolInput 'query') } else { '' }
            if (Test-HoldoutPath $p) { $holdoutAccess = $true; $accessedPath = $p }
        }
        'run_in_terminal' {
            $cmd = if ($toolInput -and (Get-MMProp $toolInput 'command')) { (Get-MMProp $toolInput 'command') } else { '' }
            # Extract path-like tokens (quoted or bare) from the command and test
            # each, so indirection such as `type .copilot/stories/../holdout/x`
            # is caught rather than only the literal whole-command string.
            $pathTokenPattern = '("[^"]+"|''[^'']+''|(?:[A-Za-z]:\\|\\)?[\w.\-/\\]+)'
            foreach ($m in [regex]::Matches($cmd, $pathTokenPattern)) {
                $tok = $m.Value.Trim('"', "'")
                if ($tok -match '[\/\\]') {
                    if (Test-HoldoutPath $tok) {
                        $holdoutAccess = $true
                        $accessedPath = $tok
                        break
                    }
                }
            }
            if (-not $holdoutAccess -and (Test-HoldoutPath $cmd)) {
                $holdoutAccess = $true
                $accessedPath = '(shell command targeting holdout path)'
            }
        }
        default { exit 0 }
    }

    # Coarse heuristic deny: if the command string references both 'holdout' and
    # '.copilot' and the caller is a build agent (or unknown under non-open
    # governance), deny regardless of token resolution. This intentionally
    # over-blocks wildcard/obfuscated forms (e.g. `.copilot\h?ldout\*`) that token
    # extraction cannot pin down.
    if (-not $holdoutAccess -and $toolName -eq 'run_in_terminal') {
        $cmd = if ($toolInput -and (Get-MMProp $toolInput 'command')) { (Get-MMProp $toolInput 'command') } else { '' }
        if ($cmd -match '(?i)holdout' -and $cmd -match '\.copilot') {
            $isBuildOrUnknown = ($buildAgents -contains $agentType) -or ($agentType -eq 'unknown')
            if ($isBuildOrUnknown) {
                $holdoutAccess = $true
                $accessedPath = '(heuristic: command references .copilot holdout)'
            }
        }
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
    "evaluation results. Only guardian, architect, release-manager, or holdout-validation " +
    "agents may access holdout files. Path attempted: $accessedPath. " +
    "To bypass in an emergency set SKIP_HOLDOUT_GUARD=true, but be aware this " +
    "invalidates any holdout evaluation for the current session."

    Write-MMHookLog -HookName 'block-holdout' -Event 'holdout_access_detected' -Decision 'deny' `
        -Extra @{ agent = $agentType; tool = $toolName; path = $accessedPath }

    Write-MMHookDecision -Decision 'deny' -Reason $reason
    exit 0
}
catch {
    # A crash in the guard body must NOT let the holdout read proceed silently
    # (that would bypass the guard). Fail closed.
    Write-MMHookFailClosedDeny -HookName 'block-holdout' -Exception $_
}
