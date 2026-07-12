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

#Requires -Version 7.0
Set-StrictMode -Version Latest

# Hook wall-clock timer: started when the hook dot-sources this library (the
# first statement in every hook), read by Write-MMHookLog as duration_ms.
$script:MMHookStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
# Last parsed stdin payload, stashed by Read-MMHookInput so Write-MMHookLog
# can enrich entries with session/agent/tool without new parameters at every
# call site.
$script:MMHookInputData = $null

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
    # Strip a UTF-8/UTF-16 BOM if the caller's pipe encoding prepended one.
    # ConvertFrom-Json fails on a BOM-prefixed string, which previously made
    # every guard hook return $null here and FAIL OPEN (H-F1 fix).
    $raw = $raw.TrimStart([char]0xFEFF)
    try {
        $parsed = $raw | ConvertFrom-Json
        $script:MMHookInputData = $parsed
        return $parsed
    }
    catch { return $null }
}

function Test-MMStopReentry {
    <#
    .SYNOPSIS True if the Stop hook is being re-entered (must no-op).
    #>
    param([Parameter(Mandatory)]$InputData)
    if (-not $InputData) { return $false }
    # Strict mode throws on missing-property access, so test existence first.
    if (-not ($InputData.PSObject.Properties['stop_hook_active'])) { return $false }
    return [bool]($InputData.stop_hook_active)
}

function Get-MMAgentType {
    <#
    .SYNOPSIS Extract the calling agent name from a hook event payload.
    .OUTPUTS Lowercase string, or empty string when not present.
    #>
    param([Parameter(Mandatory)]$InputData)
    if (-not $InputData) { return '' }
    if (($InputData.PSObject.Properties['agent_type']) -and $InputData.agent_type) { return ([string]$InputData.agent_type).ToLower().Trim() }
    if (($InputData.PSObject.Properties['agent_name']) -and $inputData.agent_name) { return ([string]$InputData.agent_name).ToLower().Trim() }
    return ''
}

# ---------- Safe property access (H-08) -------------------------------------
#
# StrictMode throws on access to a property that does not exist on an object.
# Hook payloads are untrusted and frequently omit optional fields, so every
# optional-property read must go through this helper instead of `$obj.Field`.
# A missing/null field returns $Default rather than throwing, which keeps
# non-blocking hooks from crashing (and bypassing) on partial payloads.

function Get-MMProp {
    <#
    .SYNOPSIS Safely read an optional property from an object.
    .PARAMETER Object The object to read from (may be $null).
    .PARAMETER Name The property name to read.
    .PARAMETER Default Value returned when the property is absent or $null.
    .OUTPUTS The property value, or $Default when absent/null.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowNull()]$Object,
        [Parameter(Mandatory)][string]$Name,
        $Default = $null
    )
    if ($null -ne $Object -and $Object.PSObject.Properties[$Name]) {
        return $Object.$Name
    }
    return $Default
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

        Entries are automatically enriched with correlation and performance
        fields:
          session     - 8-char session id from stdin payload / COPILOT_SESSION_ID
          agent       - agent identity from stdin payload / AGENT_ID / .active-agent
          duration_ms - wall-clock ms since the hook dot-sourced _lib.ps1
          tool        - tool_name from the stdin payload, when present
          tokens_in / tokens_out / cost_usd - populated only when the host
            payload carries usage data (VS Code does not emit this today);
            omitted otherwise. Never fabricated.
    .PARAMETER HookName e.g. 'scan-secrets'
    .PARAMETER Event Short event tag, e.g. 'scan_complete' or 'findings_detected'.
    .PARAMETER Decision One of: allow | deny | warn | skip.
    .PARAMETER Extra Hashtable of extra structured fields.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HookName,
        [Parameter(Mandatory)][string]$Event,
        [Parameter(Mandatory)][ValidateSet('allow', 'deny', 'warn', 'skip')][string]$Decision,
        [hashtable]$Extra
    )
    $path = Get-MMHookLogPath -HookName $HookName
    if (-not $path) { return }

    $inputData = $script:MMHookInputData

    # Session id: stdin payload first, env fallback, 8-char prefix (mirrors
    # artifact-manifest.ps1 so log entries join to manifest rows).
    $session = ''
    if ($inputData -and ($inputData.PSObject.Properties['session_id']) -and $inputData.session_id) { $session = [string]$inputData.session_id }
    elseif ($inputData -and ($inputData.PSObject.Properties['sessionId']) -and $inputData.sessionId) { $session = [string]$inputData.sessionId }
    elseif ($env:COPILOT_SESSION_ID) { $session = $env:COPILOT_SESSION_ID }
    if ($session.Length -gt 8) { $session = $session.Substring(0, 8) }
    if ([string]::IsNullOrWhiteSpace($session)) { $session = 'unknown' }

    # Agent identity: same precedence chain as artifact-manifest.ps1
    # (AGENT_ID -> tool_input.agent_type -> agent_type -> agent_name ->
    # agent_id -> .active-agent -> unknown) so log rows join manifest rows.
    $agent = ''
    if ($env:AGENT_ID) { $agent = $env:AGENT_ID }
    elseif ($inputData -and ($inputData.PSObject.Properties['tool_input']) -and $inputData.tool_input -and
        ($inputData.tool_input.PSObject.Properties['agent_type']) -and $inputData.tool_input.agent_type) { $agent = [string]$inputData.tool_input.agent_type }
    elseif ($inputData -and ($inputData.PSObject.Properties['agent_type']) -and $inputData.agent_type) { $agent = [string]$inputData.agent_type }
    elseif ($inputData -and ($inputData.PSObject.Properties['agent_name']) -and $inputData.agent_name) { $agent = [string]$inputData.agent_name }
    elseif ($inputData -and ($inputData.PSObject.Properties['agent_id']) -and $inputData.agent_id) { $agent = [string]$inputData.agent_id }
    if ([string]::IsNullOrWhiteSpace($agent)) {
        try {
            $activeAgentPath = Join-Path (Get-MMRepoRoot) '.copilot\state\.active-agent'
            if (Test-Path $activeAgentPath) {
                $candidate = Get-Content $activeAgentPath -Raw -ErrorAction SilentlyContinue
                if ($candidate) { $agent = $candidate.Trim() }
            }
        }
        catch { }
    }
    if ([string]::IsNullOrWhiteSpace($agent)) { $agent = 'unknown' }

    $entry = [ordered]@{
        timestamp   = (Get-Date).ToUniversalTime().ToString('o')
        hook        = $HookName
        event       = $Event
        decision    = $Decision
        governance  = (Get-MMGovernanceLevel)
        session     = $session
        agent       = $agent
        duration_ms = if ($script:MMHookStopwatch) { $script:MMHookStopwatch.ElapsedMilliseconds } else { $null }
    }

    # Standardized tool field (previously ad hoc per hook via -Extra).
    if ($inputData -and ($inputData.PSObject.Properties['tool_name']) -and $inputData.tool_name) {
        $entry['tool'] = [string]$inputData.tool_name
    }

    # Opportunistic token/cost capture: only when the host payload carries a
    # usage object (e.g. a future SubagentStop/Stop envelope). Never fabricated.
    if ($inputData -and ($inputData.PSObject.Properties['usage']) -and $inputData.usage) {
        $usage = $inputData.usage
        if ($usage.PSObject.Properties['input_tokens']) { $entry['tokens_in'] = $usage.input_tokens }
        if ($usage.PSObject.Properties['output_tokens']) { $entry['tokens_out'] = $usage.output_tokens }
        if ($usage.PSObject.Properties['cost_usd']) { $entry['cost_usd'] = $usage.cost_usd }
    }

    if ($Extra) {
        foreach ($key in $Extra.Keys) { $entry[$key] = $Extra[$key] }
    }
    try {
        # Size guard: rotate once past 5 MB so a runaway session cannot exhaust
        # disk between external compaction runs. One .old generation is kept
        # (bounded at ~2x cap); ci/compact-hook-logs.py remains the real
        # retention mechanism.
        $maxBytes = 5MB
        $fileInfo = Get-Item -Path $path -ErrorAction SilentlyContinue
        if ($fileInfo -and $fileInfo.Length -gt $maxBytes) {
            Move-Item -Path $path -Destination "$path.old" -Force -ErrorAction Stop
        }
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

# ---------- Credential / injection pattern catalogues ------------------------
#
# Single source of truth for the patterns consumed by both scan-secrets.ps1
# (file-level Stop scan) and scan-user-prompt.ps1 (prompt-level
# UserPromptSubmit scan). Adding a new credential type only needs an edit
# here; both hooks pick it up automatically.

function Get-MMSecretPatterns {
    <#
    .SYNOPSIS Canonical list of credential / secret regex patterns.
    .OUTPUTS Array of @{ Name; Severity; Regex } hashtables.
    .NOTES Severity is one of: critical | high | medium.
    #>
    return @(
        @{ Name = 'AWS_ACCESS_KEY'; Severity = 'critical'; Regex = 'AKIA[0-9A-Z]{16}' }
        @{ Name = 'AWS_SECRET_KEY'; Severity = 'critical'; Regex = 'aws_secret_access_key\s*[:=]\s*[''"]?[A-Za-z0-9/+=]{40}' }
        @{ Name = 'GCP_API_KEY'; Severity = 'high'; Regex = 'AIza[0-9A-Za-z_\-]{35}' }
        @{ Name = 'AZURE_CLIENT_SECRET'; Severity = 'critical'; Regex = 'azure[_\-]?client[_\-]?secret\s*[:=]\s*[''"]?[A-Za-z0-9_~.\-]{34,}' }
        @{ Name = 'GITHUB_PAT'; Severity = 'critical'; Regex = 'ghp_[0-9A-Za-z]{36}' }
        @{ Name = 'GITHUB_FINE_GRAINED'; Severity = 'critical'; Regex = 'github_pat_[0-9A-Za-z_]{82}' }
        @{ Name = 'OPENAI_API_KEY'; Severity = 'critical'; Regex = 'sk-[A-Za-z0-9]{20,}' }
        @{ Name = 'PRIVATE_KEY'; Severity = 'critical'; Regex = '\-\-\-\-\-BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY\-\-\-\-\-' }
        @{ Name = 'STRIPE_SECRET'; Severity = 'critical'; Regex = 'sk_live_[0-9A-Za-z]{24,}' }
        @{ Name = 'SLACK_TOKEN'; Severity = 'high'; Regex = 'xox[baprs]-[0-9]{10,}-[0-9A-Za-z\-]+' }
        @{ Name = 'NPM_TOKEN'; Severity = 'high'; Regex = 'npm_[0-9A-Za-z]{36}' }
        @{ Name = 'JWT_TOKEN'; Severity = 'medium'; Regex = 'eyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}' }
        @{ Name = 'CONNECTION_STRING'; Severity = 'high'; Regex = '(mongodb|postgres|mysql|redis|mssql)://[^\s''\"]{10,}' }
        @{ Name = 'DATABRICKS_TOKEN'; Severity = 'critical'; Regex = 'dapi[0-9a-f]{32}' }
        @{ Name = 'HUGGINGFACE_TOKEN'; Severity = 'high'; Regex = 'hf_[A-Za-z0-9]{30,}' }
        @{ Name = 'SENDGRID_KEY'; Severity = 'critical'; Regex = 'SG\.[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{20,}' }
        @{ Name = 'TWILIO_API_KEY'; Severity = 'high'; Regex = '\bSK[0-9a-f]{32}\b' }
        @{ Name = 'GENERIC_SECRET'; Severity = 'high'; Regex = '(secret|token|password|api[_\-]?key)\s*[:=]\s*[''"]?[A-Za-z0-9_/+=~.\-]{16,}' }
    )
}

function Get-MMSecretPlaceholderPattern {
    <#
    .SYNOPSIS Single regex that matches obvious placeholder / example values
             so both secret scanners can suppress false positives uniformly.
    .NOTES The rule is WHOLE-VALUE anchored (^...$): a value is treated as a
           placeholder only when the ENTIRE matched secret equals one of the
           sentinel forms. A real credential that merely CONTAINS a sentinel
           word (e.g. a key whose body includes 'sample') is NOT suppressed,
           which closes the placeholder-substring evasion channel. The bare word
           'example' is deliberately NOT included: many real credential-shaped
           strings contain it as a substring (AWS's canonical 'AKIAIOSFODNN7EXAMPLE'
           key, the 'example.com' reserved TLD inside a connection string), and
           silently suppressing those produces a false negative on the security
           corpus. Placeholder markers must be deliberate sentinels (brackets,
           your_/YOUR_ prefix, xxxx runs, changeme, TODO/FIXME, replace_me, dummy,
           fake, sample, placeholder).
    #>
    return '^(x+|0+|\*+|<[^>]+>|\$\{[^}]+\}|%[A-Z_]+%|your[_-][a-z_]+|changeme|change[_-]me|replace[_-]?me|placeholder|dummy|fake|sample|todo|fixme)$'
}

function Get-MMInjectionPatterns {
    <#
    .SYNOPSIS Canonical list of prompt-injection marker phrases.
    .OUTPUTS Array of lowercase substrings to match case-insensitively.
    #>
    return @(
        'ignore previous instructions',
        'ignore all previous',
        'disregard the above',
        'disregard previous',
        'forget what you were told',
        'forget your instructions',
        'system prompt',
        'reveal your instructions',
        'print your system prompt',
        'you are now',
        'act as if you have no restrictions',
        'jailbreak',
        'developer mode enabled'
    )
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
        # Open or create the file with an exclusive *writer* lock. We use
        # FileShare.Read so concurrent readers (editor, file watchers, other
        # hook instances reading the file) do NOT block acquisition, while
        # concurrent writers are still serialised (the security-relevant
        # guarantee: the read-modify-write cannot race). Transient sharing
        # violations (two hook instances racing, a briefly-held reader handle,
        # an antivirus/indexer touch) are retried with backoff rather than
        # failing closed, because they are contention, not corruption. Only a
        # genuinely persistent lock (a stuck handle) exhausts the retries and
        # returns $null, letting the caller fail closed as designed.
        $maxAttempts = 5
        $attempt = 0
        $backoffMs = 20
        while ($attempt -lt $maxAttempts) {
            $attempt++
            try {
                $stream = [System.IO.FileStream]::new(
                    $Path,
                    [System.IO.FileMode]::OpenOrCreate,
                    [System.IO.FileAccess]::ReadWrite,
                    [System.IO.FileShare]::Read
                )
                break
            }
            catch [System.IO.IOException] {
                # Sharing violation / lock held by another process. Retry
                # unless this was the final attempt, then re-throw so the
                # outer catch returns $null (caller fails closed).
                if ($attempt -ge $maxAttempts) { throw }
                Start-Sleep -Milliseconds $backoffMs
                $backoffMs = [Math]::Min($backoffMs * 2, 300)
            }
        }
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

# ---------- Tool capability registry (M-02) --------------------------------
#
# Single source of truth for what each tool is allowed to do. Every hook that
# gates a write-capable tool must consult this registry so equivalent mutations
# receive identical policy regardless of which tool performs them.

function Get-MMWriteCapableTools {
    <#
    .SYNOPSIS The set of tools that can mutate files, state, or the environment.
    #>
    return @(
        'write_file', 'create_file', 'replace_string_in_file',
        'multi_replace_string_in_file', 'insert_edit_into_file',
        'edit_notebook_file', 'run_in_terminal', 'run_notebook_cell'
    )
}

function Get-MMToolCapability {
    <#
    .SYNOPSIS Return the capability classification for a tool name.
    .OUTPUTS One of: read | write | execute | delegate | destructive | unknown
    #>
    param([Parameter(Mandatory)][string]$ToolName)
    $map = [ordered]@{
        read_file                    = 'read'
        list_dir                     = 'read'
        grep_search                  = 'read'
        file_search                  = 'read'
        read_notebook_cell_output    = 'read'
        write_file                   = 'write'
        create_file                  = 'write'
        replace_string_in_file       = 'write'
        multi_replace_string_in_file = 'write'
        insert_edit_into_file        = 'write'
        edit_notebook_file           = 'write'
        run_in_terminal              = 'destructive'
        run_notebook_cell            = 'execute'
        runSubagent                  = 'delegate'
    }
    if ($map.ContainsKey($ToolName)) { return $map[$ToolName] }
    return 'unknown'
}

# ---------- Untrusted agent identity (M-01) ---------------------------------
#
# VS Code hook payloads do not currently provide a cryptographically
# authenticated agent identity. Until that changes, every identity field is
# treated as untrusted display data, never as an authorization credential.

function Get-MMUntrustedAgentIdentity {
    <#
    .SYNOPSIS Extract the self-asserted agent identity, explicitly marked untrusted.
    .OUTPUTS PSCustomObject with .Name (lowercase) and .Trusted = $false.
    #>
    param([Parameter(Mandatory)]$InputData)
    $name = if (-not $InputData) { '' }
    elseif (($InputData.PSObject.Properties['agent_type']) -and $InputData.agent_type) { $InputData.agent_type }
    elseif (($InputData.PSObject.Properties['agent_name']) -and $InputData.agent_name) { $InputData.agent_name }
    else { '' }
    return [PSCustomObject]@{
        Name    = ($name -as [string]).ToLower().Trim()
        Trusted = $false
    }
}

# ---------- Path canonicalization (H-01, H-02) ------------------------------
#
# Resolve path-bearing tool inputs to a canonical, absolute form so traversal,
# relative segments, and (where supported) symlinks cannot evade policy.

function Resolve-MMCanonicalPath {
    <#
    .SYNOPSIS Best-effort canonical absolute path for a tool input value.
    .OUTPUTS String absolute path, or $null when resolution fails.
    .NOTES Handles both rooted and relative paths (including `..` traversal
             segments) by resolving against the current location.
    #>
    param([Parameter(Mandatory)][string]$Value)
    try {
        $v = $Value.Trim().Trim('"', "'")
        if ([string]::IsNullOrWhiteSpace($v)) { return $null }
        # Normalize backslashes to the platform directory separator so paths
        # authored with Windows separators still resolve correctly on Linux.
        $v = $v.Replace('\', [System.IO.Path]::DirectorySeparatorChar)
        # Resolve-Path correctly collapses `..` and relative segments for both
        # existing and (with -ErrorAction SilentlyContinue) non-existing paths.
        $resolved = Resolve-Path -Path $v -ErrorAction SilentlyContinue
        if ($resolved) { return $resolved.ProviderPath }
        # Fallback for paths that do not yet exist: build from current location
        # and collapse `..` / relative segments with GetFullPath.
        $base = if ([System.IO.Path]::IsPathRooted($v)) { $v } else { Join-Path (Get-Location).Path $v }
        return [System.IO.Path]::GetFullPath($base)
    }
    catch { return $null }
}

function Test-MMPathUnderRoot {
    <#
    .SYNOPSIS True when the resolved path is at or beneath the canonical root.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root
    )
    try {
        $p = Resolve-MMCanonicalPath -Value $Path
        $r = Resolve-MMCanonicalPath -Value $Root
        if (-not $p -or -not $r) { return $false }
        $sep = [System.IO.Path]::DirectorySeparatorChar
        $pNorm = $p.TrimEnd($sep)
        $rNorm = $r.TrimEnd($sep)
        # On case-insensitive filesystems (Windows) the containment check must
        # ignore case, otherwise `.copilot\HOLDOUT` evades a root of
        # `.copilot\holdout` (S2 fix). Linux stays ordinal: /TMP and /tmp are
        # genuinely different directories there.
        $cmp = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
        return $pNorm.Equals($rNorm, $cmp) -or $pNorm.StartsWith($rNorm + $sep, $cmp)
    }
    catch { return $false }
}

# ---------- Secret / command redaction (H-06) ------------------------------
#
# Persisted state, logs, manifests, and injected context must never contain
# raw terminal commands or external absolute paths. Centralize the redaction
# so every hook applies identical rules.

function Get-MMRedactedCommand {
    <#
    .SYNOPSIS Replace credential-shaped substrings and external absolute paths
             in a command with redaction markers. Returns safe text suitable
             for logs (never for persisted state, which should use the
             operation category instead).
    #>
    param([Parameter(Mandatory)][string]$Command)
    $redacted = $Command
    foreach ($s in (Get-MMSecretPatterns)) {
        # The replacement must be built per-pattern with double-quoted string
        # interpolation so $($s.Name) expands to the actual pattern name. A
        # single-quoted replacement literal would emit the text
        # '[REDACTED:$($s.Name)]' verbatim for every match (H-07 fix).
        $replacement = "[REDACTED:$($s.Name)]"
        $redacted = [regex]::Replace($redacted, $s.Regex, $replacement, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    # Redact external absolute paths (outside the current working directory).
    $redacted = [regex]::Replace($redacted, '(?i)([a-z]:\\[^\s''"]+|/[^\s''"]+)', {
            param($m)
            $p = $m.Value
            if (Test-MMPathUnderRoot -Path $p -Root (Get-Location).Path) { return $p }
            return '[REDACTED:PATH]'
        })
    return $redacted
}

function Get-MMRedactedOperationCategory {
    <#
    .SYNOPSIS A short, non-sensitive category describing the operation, e.g.
             'terminal:delete', 'terminal:git', 'file:write'. Never includes
             arguments or raw command text. Safe to persist to state/logs.
    #>
    param([Parameter(Mandatory)][string]$ToolName, [string]$Command = '')
    switch ($ToolName) {
        'run_in_terminal' {
            $c = $Command.ToLower()
            if ($c -match 'rm\b|remove-item|del\b|format-volume|diskpart') { return 'terminal:delete' }
            if ($c -match 'drop\b|truncate\b|delete\b') { return 'terminal:db-destructive' }
            if ($c -match 'git ') { return 'terminal:git' }
            if ($c -match 'chmod|chown|icacls|takeown') { return 'terminal:permissions' }
            return 'terminal:execute'
        }
        default { return "file:$ToolName" }
    }
}

# ---------- Fail-closed governance helper (H-08) ----------------------------
#
# Returns $true when a governance control must DENY on infrastructure failure
# (missing dependency, lock/parse error) rather than fail open. Open governance
# is the only tier that may degrade to allow for local recovery.

function Test-MMFailClosed {
    <#
    .SYNOPSIS True when governance-critical controls must fail closed.
    #>
    param([Parameter(Mandatory)][string]$GovernanceLevel)
    return $GovernanceLevel -ne 'open'
}

function Write-MMHookFailClosedDeny {
    <#
    .SYNOPSIS Emit a deny decision when a blocking guard crashes unexpectedly.
    .DESCRIPTION
        Used by the BLOCKING PreToolUse guards (block-destructive, block-holdout,
        cap-subagent-budget, scan-secrets). When the guard's main body throws,
        we must NOT let the tool call proceed silently (that would bypass the
        guard). Under standard/strict/locked governance we emit the standard
        PreToolUse deny JSON with reason 'hook_error_fail_closed' and exit 0.
        Under open governance we log a warning and allow, so a local hook bug
        does not hard-block a developer's session.
    .PARAMETER HookName e.g. 'block-destructive'
    .PARAMETER Exception The caught exception object (its message is surfaced).
    .PARAMETER HookEvent The lifecycle event shape to emit: 'PreToolUse' (default,
        permissionDecision envelope) or 'Stop' (decision=block envelope).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HookName,
        [Parameter(Mandatory)]$Exception,
        [ValidateSet('PreToolUse', 'Stop')][string]$HookEvent = 'PreToolUse'
    )
    $governanceLevel = Get-MMGovernanceLevel
    $message = if ($Exception -and $Exception.Exception -and $Exception.Exception.Message) {
        $Exception.Exception.Message
    }
    elseif ($Exception -and $Exception.Message) {
        $Exception.Message
    }
    else {
        'unknown error'
    }
    if (Test-MMFailClosed -GovernanceLevel $governanceLevel) {
        Write-MMHookLog -HookName $HookName -Event 'hook_error_fail_closed' -Decision 'deny' `
            -Extra @{ note = "guard crashed; failing closed"; error = $message }
        $failReason = "BLOCKED ($HookName): hook encountered an internal error and GOVERNANCE_LEVEL=$governanceLevel fails closed. Error: $message"
        if ($HookEvent -eq 'Stop') {
            $payload = [ordered]@{
                hookSpecificOutput = [ordered]@{
                    hookEventName = 'Stop'
                    decision      = 'block'
                    reason        = $failReason
                }
            } | ConvertTo-Json -Depth 5 -Compress:$false
            Write-Output $payload
        }
        else {
            Write-MMHookDecision -Decision 'deny' -Reason $failReason
        }
        exit 0
    }
    Write-MMHookLog -HookName $HookName -Event 'hook_error_fail_closed' -Decision 'warn' `
        -Extra @{ note = "guard crashed; failing open (open governance)"; error = $message }
    Write-Host "WARNING ($HookName): hook encountered an internal error but GOVERNANCE_LEVEL=open allows the call to proceed. Error: $message"
    exit 0
}

# Export-ModuleMember is unnecessary for dot-sourced scripts; every function above
# becomes available in the caller's scope automatically.
