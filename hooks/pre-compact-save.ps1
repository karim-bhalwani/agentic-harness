# Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |
#
# pre-compact-save.ps1
# PreCompact hook: checkpoint session state before context compaction discards
# conversation history. Writes .copilot/state/SESSION_STATE.md in the project root.
#
# Why this matters: compaction silently truncates the context window mid-session.
# Without this hook the agent loses all record of what it was doing. With it,
# the next turn (or next session) can read the state file and resume cleanly.
#
# NEVER exits 2. Purpose is to SAVE state, not block compaction.
# Always exits 0 regardless of errors — a failed checkpoint must not break the agent.
#
# Output: JSON with systemMessage so the model sees a confirmation in chat.

[CmdletBinding()]
param()

# --- Circuit breaker ---
# Set $env:SKIP_PRE_COMPACT_SAVE = 'true' to disable state checkpointing for this session.
if ($env:SKIP_PRE_COMPACT_SAVE -eq 'true') {
    exit 0
}

# --- Read stdin ---
$rawInput = [Console]::In.ReadToEnd()
$inputData = $null
if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
    try { $inputData = $rawInput | ConvertFrom-Json } catch { }
}

# --- Resolve paths ---
$cwd = if ($inputData -and $inputData.cwd) { $inputData.cwd } else { (Get-Location).Path }
$sessionId = if ($inputData -and $inputData.sessionId) { $inputData.sessionId }      else { 'unknown' }
$transcriptPath = if ($inputData -and $inputData.transcript_path) { $inputData.transcript_path } else { $null }

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$timestampISO = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'

# Prefer git project root; fall back to workspace cwd
$projectRoot = & git -C $cwd rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $projectRoot) { $projectRoot = $cwd }
$projectRoot = $projectRoot -replace '/', '\'

# --- Git context ---
$branch = & git -C $cwd rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -ne 0 -or -not $branch) { $branch = 'unknown' }

$lastCommit = & git -C $cwd log -1 --oneline 2>$null
if ($LASTEXITCODE -ne 0 -or -not $lastCommit) { $lastCommit = 'none' }

# --- Parse transcript for last activity (best-effort, never fatal) ---
$lastTool = 'unknown'
$lastToolFile = ''

if ($transcriptPath -and (Test-Path $transcriptPath)) {
    try {
        $transcriptRaw = Get-Content $transcriptPath -Raw -ErrorAction Stop
        $transcript = $transcriptRaw | ConvertFrom-Json -ErrorAction Stop

        # VS Code transcript is an array of turn objects.
        # Each tool_use turn has: type="tool_use", name=<toolName>, input=<object>
        if ($transcript -is [array]) {
            # Walk backwards to find the last tool_use entry
            for ($i = $transcript.Count - 1; $i -ge 0; $i--) {
                $entry = $transcript[$i]
                if ($entry.type -eq 'tool_use' -and $entry.name) {
                    $lastTool = $entry.name
                    # Capture file path if it was a file-editing tool
                    if ($entry.input -and $entry.input.filePath) {
                        $lastToolFile = $entry.input.filePath
                    }
                    elseif ($entry.input -and $entry.input.command) {
                        $lastToolFile = $entry.input.command
                    }
                    break
                }
                # Also check content arrays inside assistant messages
                if ($entry.role -eq 'assistant' -and $entry.content -is [array]) {
                    $toolBlock = $entry.content | Where-Object { $_.type -eq 'tool_use' } | Select-Object -Last 1
                    if ($toolBlock -and $toolBlock.name) {
                        $lastTool = $toolBlock.name
                        if ($toolBlock.input -and $toolBlock.input.filePath) {
                            $lastToolFile = $toolBlock.input.filePath
                        }
                        break
                    }
                }
            }
        }
    }
    catch {
        # Transcript unreadable — proceed with defaults. Never fatal.
    }
}

$lastToolDesc = if ($lastToolFile) { "$lastTool ($lastToolFile)" } else { $lastTool }

# --- State file path ---
$stateDir = Join-Path $projectRoot '.copilot\state'
$statePath = Join-Path $stateDir 'SESSION_STATE.md'

# --- Merge: preserve existing Completed Steps and task description ---
$existingCompletedSteps = ''
$existingTask = 'Work in progress at time of compaction'
$completedStepsParseWarning = $null

if (Test-Path $statePath) {
    try {
        $existing = Get-Content $statePath -Raw -ErrorAction Stop
        if ($existing -match '(?s)## Completed Steps\s*\r?\n(.*?)\r?\n## Pending Steps') {
            $existingCompletedSteps = $matches[1].Trim()
        }
        elseif (-not [string]::IsNullOrWhiteSpace($existing)) {
            $completedStepsParseWarning = "- [warning] Existing SESSION_STATE.md could not be parsed for '## Completed Steps' section; prior steps may be missing due to unexpected header format. Manually review .copilot/state/SESSION_STATE.md to verify completed steps or reformat to match the expected schema."
        }
        if ($existing -match '\*\*Description:\*\*\s*(.+)') {
            $existingTask = $matches[1].Trim()
        }
    }
    catch { }
}

# Append new compaction checkpoint line
$newEntry = "- [$timestamp] [hook:pre-compact]: Compaction checkpoint. Last tool: $lastToolDesc. Branch: $branch"
$completedSection = if ($existingCompletedSteps) {
    "$existingCompletedSteps`n$newEntry"
}
else {
    if ($completedStepsParseWarning) {
        "$completedStepsParseWarning`n$newEntry"
    }
    else {
        $newEntry
    }
}

# --- Write SESSION_STATE.md (schema matches context-engineer/references/session_state_schema.md) ---
try {
    $null = New-Item -ItemType Directory -Force -Path $stateDir -ErrorAction Stop

    $stateContent = @"
# Session State

> **Last Updated:** $timestampISO
> **Last Agent:** hook:pre-compact
> **Status:** paused

## Pipeline Position

- **Current Phase:** (unknown — re-read conversation above to restore)
- **Current Agent:** (unknown — re-read conversation above to restore)
- **Pending Handoff:** none

## Active Task

- **Description:** $existingTask
- **Spec Reference:** (check .copilot/specs/SPEC.md if it exists)
- **Branch:** $branch

## Completed Steps

$completedSection

## Pending Steps

1. Re-read conversation above compaction point to re-establish task context.
2. Continue from last recorded activity: $lastToolDesc

## Blockers

- Context compaction occurred at $timestamp. Conversation history before this point was truncated.

## Context Pointers

- .copilot/context/PROJECT_CONTEXT.md
- .copilot/specs/SPEC.md

## Decisions Made This Session

- (Captured decisions not available — compaction occurred before summary could be written)

## Notes for Next Session

Compaction triggered at $timestamp (session: $sessionId, branch: $branch).
Last recorded tool: $lastToolDesc. Last commit: $lastCommit.
Re-read the conversation above this point before proceeding — the agent should have context
in the remaining window. If starting a fresh session, read Context Pointers above first.
"@

    Set-Content -Path $statePath -Value $stateContent -Encoding UTF8

    # Notify the model via systemMessage (shown in chat UI)
    $output = [ordered]@{
        systemMessage = "Pre-compact checkpoint saved to .copilot/state/SESSION_STATE.md | Branch: $branch | Last tool: $lastToolDesc | $timestamp"
    } | ConvertTo-Json -Depth 3 -Compress:$false

    Write-Output $output

}
catch {
    # Write failure must never crash the hook or block the agent
    Write-Host "pre-compact-save: failed to write state file - $($_.Exception.Message)"
}

exit 0
