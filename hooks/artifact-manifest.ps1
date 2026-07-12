# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# artifact-manifest.ps1
# PostToolUse hook: append an entry to .copilot/state/artifact-manifest.jsonl
# whenever an agent writes or edits a file.
#
# Purpose: Gives future sessions a cheap grep-able index of what was produced,
# so they can find artifacts by path, role, agent, or session without re-reading
# files. Zero LLM tokens - runs entirely outside the model.
#
# Entry schema:
#   { "timestamp": ISO8601, "session": string, "agent": string, "op": "create|edit",
#     "tool": string, "path": repo-relative string, "role": string, "bytes": int|null }
#
# Role assignment (first match wins):
#   artifact     = files under artifacts/
#   state        = files under .copilot/state/, SESSION_STATE.md
#   scratch      = files under scratch/, tmp/, temp/, *.tmp
#   test         = files under tests/, *.Tests.ps1, test_*.py, *_test.py
#   hook         = files under hooks/
#   agent-asset  = files under prompts/, instructions/, skills/
#   doc          = files under docs/, *.md
#   source       = *.py, *.ts(x), *.js(x), *.ps1, *.sql, *.sh
#   unknown      = everything else (agent can reclassify later)
#
# Agent identity (first non-empty wins):
#   $env:AGENT_ID -> tool_input.agent_type / agent_type / agent_name / agent_id
#   -> .copilot/state/.active-agent -> 'unknown'
#
# Env vars:
#   SKIP_ARTIFACT_MANIFEST=true     - bypass entirely (emergency circuit breaker)
#   ARTIFACT_MANIFEST_PATH=<path>   - override manifest location (used by tests so
#                                     they never pollute the real manifest)

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

if (Test-MMCircuitBreaker -EnvVar 'SKIP_ARTIFACT_MANIFEST') { exit 0 }

# --- Read stdin (PostToolUse provides tool_use data) ---
$inputData = Read-MMHookInput

# Only act on file-write tools
$writingTools = @('write_file', 'create_file', 'replace_string_in_file',
    'multi_replace_string_in_file', 'insert_edit_into_file')
$toolName = if ($inputData -and (Get-MMProp $inputData 'tool_name')) { (Get-MMProp $inputData 'tool_name') } else { '' }
if ($toolName -notin $writingTools) { exit 0 }

# Extract the file path from the tool input. Handle both the single-file shape
# (filePath / file_path / path) and the multi_replace_string_in_file shape
# (tool_input.replacements[].filePath). A multi-replace payload may touch
# several files; emit one manifest entry per distinct file path.
$filePaths = [System.Collections.Generic.List[string]]::new()
if ($inputData -and (Get-MMProp $inputData 'tool_input')) {
    $ti = Get-MMProp $inputData 'tool_input' $null
    $single = Get-MMProp $ti 'filePath' $null
    if (-not $single) { $single = Get-MMProp $ti 'file_path' $null }
    if (-not $single) { $single = Get-MMProp $ti 'path' $null }
    if ($single) { $filePaths.Add($single) }
    $replacements = Get-MMProp $ti 'replacements' $null
    if ($replacements) {
        foreach ($rep in $replacements) {
            $rp = Get-MMProp $rep 'filePath' $null
            if (-not $rp) { $rp = Get-MMProp $rep 'file_path' $null }
            if ($rp -and $filePaths -notcontains $rp) { $filePaths.Add($rp) }
        }
    }
}
if ($filePaths.Count -eq 0) { exit 0 }

# --- Resolve project root (forward-slash form for comparison) ---
$projectRoot = Get-MMRepoRoot
$projectRootFwd = ($projectRoot -replace '\\', '/').TrimEnd('/')

# --- Operation type from the tool ---
$op = if ($toolName -in @('write_file', 'create_file')) { 'create' } else { 'edit' }

# --- Agent identity (first non-empty wins) ---
$agentId = ''
if ($env:AGENT_ID) { $agentId = $env:AGENT_ID }
elseif ($inputData -and (Get-MMProp $inputData 'tool_input') -and (Get-MMProp (Get-MMProp $inputData 'tool_input') 'agent_type')) { $agentId = (Get-MMProp (Get-MMProp $inputData 'tool_input') 'agent_type') }
elseif ($inputData -and (Get-MMProp $inputData 'agent_type')) { $agentId = (Get-MMProp $inputData 'agent_type') }
elseif ($inputData -and (Get-MMProp $inputData 'agent_name')) { $agentId = (Get-MMProp $inputData 'agent_name') }
elseif ($inputData -and (Get-MMProp $inputData 'agent_id')) { $agentId = (Get-MMProp $inputData 'agent_id') }
if ([string]::IsNullOrWhiteSpace($agentId)) {
    $activeAgentPath = Join-Path $projectRoot '.copilot\state\.active-agent'
    if (Test-Path $activeAgentPath) {
        $candidate = (Get-Content $activeAgentPath -Raw -ErrorAction SilentlyContinue)
        if ($candidate) { $agentId = $candidate.Trim() }
    }
}
if ([string]::IsNullOrWhiteSpace($agentId)) { $agentId = 'unknown' }

# --- Session id (short) ---
$session = ''
if ($inputData -and (Get-MMProp $inputData 'session_id')) { $session = [string](Get-MMProp $inputData 'session_id') }
elseif ($env:COPILOT_SESSION_ID) { $session = $env:COPILOT_SESSION_ID }
if ($session.Length -gt 8) { $session = $session.Substring(0, 8) }
if ([string]::IsNullOrWhiteSpace($session)) { $session = 'unknown' }

# --- Resolve manifest path (env override lets tests redirect output) ---
if ($env:ARTIFACT_MANIFEST_PATH) {
    $manifest = $env:ARTIFACT_MANIFEST_PATH
    $stateDir = Split-Path -Parent $manifest
}
else {
    $stateDir = Join-Path $projectRoot '.copilot\state'
    $manifest = Join-Path $stateDir 'artifact-manifest.jsonl'
}

if ($stateDir -and -not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

# --- Emit one manifest entry per touched file path ---
foreach ($filePath in $filePaths) {
    # --- Normalise path: forward slashes + make repo-relative + strip drive leak ---
    $filePathNorm = $filePath -replace '\\', '/'
    if ($projectRootFwd -and $filePathNorm.ToLower().StartsWith(($projectRootFwd.ToLower() + '/'))) {
        # Case-insensitive prefix strip for Windows drive letters
        $filePathNorm = $filePathNorm.Substring($projectRootFwd.Length + 1)
    }

    # --- Assign role (first match wins) ---
    $role = switch -Regex ($filePathNorm) {
        '(^|/)artifacts/' { 'artifact'; break }
        '(^|/)\.copilot/state/|SESSION_STATE' { 'state'; break }
        '(^|/)(scratch|tmp|temp)/|\.tmp$' { 'scratch'; break }
        '(^|/)tests?/|\.Tests\.ps1$|(^|/)test_.*\.py$|_test\.py$' { 'test'; break }
        '(^|/)hooks/' { 'hook'; break }
        '(^|/)(prompts|instructions|skills)/' { 'agent-asset'; break }
        '(^|/)docs/|\.md$' { 'doc'; break }
        '\.(py|ts|tsx|js|jsx|ps1|sql|sh)$' { 'source'; break }
        default { 'unknown' }
    }

    # --- Byte size (best-effort; resolve relative paths against project root) ---
    $bytes = $null
    $absForStat = if ([System.IO.Path]::IsPathRooted($filePath)) { $filePath } else { Join-Path $projectRoot ($filePathNorm -replace '/', '\') }
    if (Test-Path $absForStat -PathType Leaf) {
        try { $bytes = (Get-Item $absForStat).Length } catch { $bytes = $null }
    }

    # --- Build the JSONL entry ---
    # manifest never leaks local filesystem layout. Repo-relative paths are kept.
    $manifestPath = $filePathNorm
    if ([System.IO.Path]::IsPathRooted($filePathNorm) -and -not (Test-MMPathUnderRoot -Path $filePathNorm -Root $projectRoot)) {
        $manifestPath = '[REDACTED:EXTERNAL_PATH]'
    }
    $entry = [PSCustomObject]@{
        timestamp = (Get-Date -Format 'o')
        session   = $session
        agent     = $agentId
        op        = $op
        tool      = $toolName
        path      = $manifestPath
        role      = $role
        bytes     = $bytes
    } | ConvertTo-Json -Compress

    # Append entry (JSONL = one JSON object per line). Guarded so a disk error
    # never crashes the agent harness (STYLE-GUIDE rule: never fail the decision path).
    try {
        Add-Content -Path $manifest -Value $entry -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        # Logging failure must never break the agent's write flow.
    }
}

exit 0
