# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# _lib.ps1 - Shared PowerShell helpers for the mega-minion hook harness.
#
# Loaded via dot-source from individual hooks:
#   . (Join-Path $PSScriptRoot '_lib.ps1')
#
# Goals (Standards Analysis fix - "PowerShell style is inconsistent"):
#   * Single canonical implementation of stdin parsing, governance level
#     resolution, JSONL logging, and circuit-breaker handling.
#   * All hooks emit the same JSON shape, the same log envelope, and the
#     same exit-code semantics. New hooks copy the same boilerplate.
#   * Functions are deliberately small and pure-PS (no external commands)
#     so they never themselves cause hook failures.
#
# Conventions:
#   * Every helper is named Verb-MM<Noun> (mega-minion prefix) to avoid
#     collisions with builtin / 3rd-party PowerShell cmdlets.
#   * Helpers never write to stderr unless explicitly requested. Errors are
#     swallowed and converted to safe defaults.
#   * Helpers never call exit; the caller decides how to terminate.

# ---------- Governance --------------------------------------------------------

function Get-MMGovernanceLevel {
    <#
    .SYNOPSIS Resolve the GOVERNANCE_LEVEL env var to one of the canonical tiers.
    .OUTPUTS One of: open | standard | strict | locked.
    #>
    $level = if ($env:GOVERNANCE_LEVEL) { $env:GOVERNANCE_LEVEL.ToLowerInvariant() } else { 'standard' }
    if ($level -notin @('open', 'standard', 'strict', 'locked')) { return 'standard' }
    return $level
}

function Resolve-MMMode {
    <#
    .SYNOPSIS Resolve a hook-specific mode env var with governance fallback.
    .PARAMETER OverrideEnvVar Name of the per-hook mode env var (e.g. SCAN_MODE).
    .PARAMETER GovernanceLevel Output of Get-MMGovernanceLevel.
    .PARAMETER StrictDefault Mode to use when governance is strict/locked.
    .PARAMETER StandardDefault Mode to use when governance is standard.
    .PARAMETER OpenDefault Mode to use when governance is open.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OverrideEnvVar,
        [Parameter(Mandatory)][string]$GovernanceLevel,
        [Parameter(Mandatory)][string]$StrictDefault,
        [Parameter(Mandatory)][string]$StandardDefault,
        [Parameter(Mandatory)][string]$OpenDefault
    )
    $override = [Environment]::GetEnvironmentVariable($OverrideEnvVar)
    if ($override) { return $override }
    switch ($GovernanceLevel) {
        'strict' { return $StrictDefault }
        'locked' { return $StrictDefault }
        'open' { return $OpenDefault }
        default { return $StandardDefault }
    }
}

# ---------- stdin parsing -----------------------------------------------------

function Read-MMHookInput {
    <#
    .SYNOPSIS Read the JSON event payload that VS Code pipes to a hook.
    .OUTPUTS PSCustomObject or $null when stdin is empty/malformed.
    .NOTES Never throws - malformed JSON returns $null so the caller can pass through.
    #>
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    try { return $raw | ConvertFrom-Json } catch { return $null }
}

function Test-MMStopReentry {
    <#
    .SYNOPSIS True if the Stop hook is being re-entered (must no-op).
    #>
    param([Parameter(Mandatory)]$InputData)
    if (-not $InputData) { return $false }
    return [bool]($InputData.stop_hook_active)
}

function Get-MMAgentType {
    <#
    .SYNOPSIS Extract the calling agent name from a hook event payload.
    .OUTPUTS Lowercase string, or empty string when not present.
    #>
    param([Parameter(Mandatory)]$InputData)
    if (-not $InputData) { return '' }
    if ($InputData.agent_type) { return $InputData.agent_type.ToLower().Trim() }
    if ($InputData.agent_name) { return $InputData.agent_name.ToLower().Trim() }
    return ''
}

# ---------- Logging -----------------------------------------------------------

function Get-MMHookLogPath {
    <#
    .SYNOPSIS Resolve the path used for structured JSONL hook logs.
    .PARAMETER HookName File-stem used in the log filename, e.g. 'scan-secrets'.
    .OUTPUTS Absolute path, or $null when the directory cannot be created.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$HookName)
    $logDir = if ($env:HOOK_LOG_DIR) {
        $env:HOOK_LOG_DIR
    }
    else {
        Join-Path (Get-Location).Path '.copilot\state\hook-logs'
    }
    try {
        $null = New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop
        return Join-Path $logDir "$HookName.jsonl"
    }
    catch {
        return $null
    }
}

function Write-MMHookLog {
    <#
    .SYNOPSIS Append a structured JSONL log entry for this hook event.
    .DESCRIPTION
        Every hook writes one line of JSON per decision. Common fields are filled
        in here; pass additional context through -Extra (hashtable). Logging
        errors are swallowed - a logging failure must never alter hook behavior.
    .PARAMETER HookName e.g. 'scan-secrets'
    .PARAMETER Event Short event tag, e.g. 'scan_complete' or 'findings_detected'.
    .PARAMETER Decision One of: allow | deny | warn | block | skip.
    .PARAMETER Extra Hashtable of extra structured fields.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HookName,
        [Parameter(Mandatory)][string]$Event,
        [Parameter(Mandatory)][string]$Decision,
        [hashtable]$Extra
    )
    $path = Get-MMHookLogPath -HookName $HookName
    if (-not $path) { return }
    $entry = [ordered]@{
        timestamp  = (Get-Date).ToUniversalTime().ToString('o')
        hook       = $HookName
        event      = $Event
        decision   = $Decision
        governance = (Get-MMGovernanceLevel)
    }
    if ($Extra) {
        foreach ($key in $Extra.Keys) { $entry[$key] = $Extra[$key] }
    }
    try {
        Add-Content -Path $path -Value ($entry | ConvertTo-Json -Compress) -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        # Logging never fails the decision path.
    }
}

# ---------- VS Code response helpers -----------------------------------------

function Write-MMHookDecision {
    <#
    .SYNOPSIS Emit a PreToolUse permissionDecision JSON envelope.
    .PARAMETER Decision allow | deny
    .PARAMETER Reason Human-readable rationale (surfaced to the agent).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('allow', 'deny')][string]$Decision,
        [Parameter(Mandatory)][string]$Reason
    )
    $payload = [ordered]@{
        hookSpecificOutput = [ordered]@{
            hookEventName            = 'PreToolUse'
            permissionDecision       = $Decision
            permissionDecisionReason = $Reason
        }
    } | ConvertTo-Json -Depth 5 -Compress:$false
    Write-Output $payload
}

function Write-MMHookContext {
    <#
    .SYNOPSIS Emit a SessionStart / SubagentStart / UserPromptSubmit context payload.
    .PARAMETER EventName One of SessionStart | SubagentStart | UserPromptSubmit.
    .PARAMETER Context Markdown / plain text content to inject.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EventName,
        [Parameter(Mandatory)][string]$Context
    )
    $payload = [ordered]@{
        hookSpecificOutput = [ordered]@{
            hookEventName     = $EventName
            additionalContext = $Context
        }
    } | ConvertTo-Json -Depth 5 -Compress:$false
    Write-Output $payload
}

# ---------- Circuit breakers --------------------------------------------------

function Test-MMCircuitBreaker {
    <#
    .SYNOPSIS Check whether the named SKIP_<NAME> env var disables this hook.
    .PARAMETER EnvVar Name of the env var, e.g. 'SKIP_QUALITY_GATE'.
    #>
    param([Parameter(Mandatory)][string]$EnvVar)
    return ([Environment]::GetEnvironmentVariable($EnvVar)) -eq 'true'
}

# ---------- Repo helpers ------------------------------------------------------

function Get-MMRepoRoot {
    <#
    .SYNOPSIS Best-effort repository root resolution.
    .OUTPUTS Absolute path. Falls back to Get-Location when git is unavailable.
    .NOTES Path normalization is platform-aware: on POSIX systems forward slashes
           are preserved; on Windows they are converted to backslashes.
    #>
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $root = & git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $root) {
            $root = $root.Trim()
            if ($PSVersionTable.Platform -eq 'Unix') {
                return $root
            }
            return ($root -replace '/', '\')
        }
    }
    return (Get-Location).Path
}

# ---------- Cross-platform helpers -------------------------------------------

function Get-MMPythonCommand {
    <#
    .SYNOPSIS Resolve a working Python command for the current platform.
    .OUTPUTS 'python' or 'python3' or '' when neither is on PATH.
    .NOTES On most Linux distros 'python' is absent and 'python3' is required.
           On Windows 'python3' is usually absent. Try both, prefer 'python'.
    #>
    if (Get-Command python -ErrorAction SilentlyContinue) { return 'python' }
    if (Get-Command python3 -ErrorAction SilentlyContinue) { return 'python3' }
    return ''
}

# ---------- File locking ------------------------------------------------------

function Invoke-MMLockedFileOp {
    <#
    .SYNOPSIS Perform an atomic read-modify-write on a file via an exclusive
             FileStream lock. Prevents concurrent hook instances from racing
             on shared state files (e.g. subagent-budget.json).
    .PARAMETER Path Absolute path to the state file.
    .PARAMETER ScriptBlock Receives the file's current raw string content
                          (or $null if the file does not exist) and must
                          return the new string content to write.
    .OUTPUTS Whatever the ScriptBlock returns (after the write succeeds).
    .NOTES Uses [System.IO.FileStream] with FileShare.None for an exclusive
           lock. The lock is held only for the duration of the ScriptBlock.
           Never throws - on any error returns $null.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )
    $parent = Split-Path $Path -Parent
    if (-not $parent) { return $null }
    try {
        $null = New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop
    }
    catch { return $null }

    $stream = $null
    try {
        # Open or create the file with exclusive (FileShare.None) read/write.
        $stream = [System.IO.FileStream]::new(
            $Path,
            [System.IO.FileMode]::OpenOrCreate,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
        # Read current content using a StreamReader with leaveOpen=true so
        # disposing the reader does NOT close the underlying stream. The
        # 4-arg constructor (Stream, Encoding, detectBom, bufferSize, leaveOpen)
        # is the portable way to keep the stream alive across read/write phases.
        $current = $null
        $reader = [System.IO.StreamReader]::new(
            $stream,
            [System.Text.Encoding]::UTF8,
            $true,
            1024,
            $true
        )
        if ($stream.Length -gt 0) {
            $current = $reader.ReadToEnd()
        }
        $reader.Dispose()

        # Run the caller's operation. Capture output into a list so we can
        # distinguish stray pipeline output from the explicit return value.
        # The scriptblock's return value is the LAST object emitted.
        $output = & $ScriptBlock $current
        if ($null -eq $output) {
            $newContent = $null
        }
        elseif ($output -is [System.Array]) {
            # Use the last element as the return value; ignore stray output.
            $newContent = $output[-1]
        }
        else {
            $newContent = $output
        }

        # Write new content (truncate then write). leaveOpen=true keeps the
        # stream alive; the finally block disposes it.
        $stream.SetLength(0)
        $writer = [System.IO.StreamWriter]::new(
            $stream,
            [System.Text.Encoding]::UTF8,
            1024,
            $true
        )
        if ($null -ne $newContent) { $writer.Write([string]$newContent) }
        $writer.Flush()
        $writer.Dispose()

        return $newContent
    }
    catch {
        return $null
    }
    finally {
        if ($stream) { $stream.Dispose() }
    }
}

# Export-ModuleMember is unnecessary for dot-sourced scripts; every function above
# becomes available in the caller's scope automatically.
