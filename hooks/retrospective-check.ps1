# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# retrospective-check.ps1
# Stop hook: count completed workflow cycles and emit a visible reminder when a
# retrospective is due. Closes the "self-measurement requires human discipline"
# gap (CORE_PRINCIPLES Principle 6) by converting the manual retrospective loop
# into a prompted one. Non-blocking: it only nudges, never stops the session.
#
# Signal: each closed story produces a report under
#   .copilot/stories/reports/US-{id}-report.md
# The number of report files is used as the completed-cycle counter. After every
# 5th completed cycle the hook prints a "retrospective due" banner exactly once
# per threshold crossing (tracked in .copilot/state/retrospective-counter.txt).
#
# Direct-path (non-PLAN) work does not produce story reports; for that path the
# retrospective stays manually triggered via the /retrospective prompt.
#
# Env vars:
#   SKIP_RETROSPECTIVE_CHECK=true  - bypass entirely (emergency circuit breaker)
#   RETROSPECTIVE_INTERVAL=<int>    - cycles between reminders (default: 5)
#
# Output: Write-Host banner on threshold crossing. Exit 0 always (non-blocking).

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_RETROSPECTIVE_CHECK -eq 'true') { exit 0 }

# --- Read stdin; bail on re-entrant Stop to avoid duplicate banners ---
$rawInput = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
    try {
        $inputData = $rawInput | ConvertFrom-Json
        if ($inputData.stop_hook_active -eq $true) { exit 0 }
    }
    catch {
        # Malformed JSON is non-fatal; continue.
    }
}

# --- Resolve interval ---
$interval = 5
if ($env:RETROSPECTIVE_INTERVAL) {
    $parsed = 0
    if ([int]::TryParse($env:RETROSPECTIVE_INTERVAL, [ref]$parsed) -and $parsed -gt 0) {
        $interval = $parsed
    }
}

# --- Count completed cycles (story reports) ---
$root = (Get-Location).Path
$reportsDir = Join-Path $root '.copilot\stories\reports'
if (-not (Test-Path $reportsDir)) { exit 0 }

$completed = @(Get-ChildItem -Path $reportsDir -Filter '*-report.md' -File -ErrorAction SilentlyContinue).Count
if ($completed -lt $interval) { exit 0 }

# --- Load last-reminded count ---
$stateDir = Join-Path $root '.copilot\state'
$counterPath = Join-Path $stateDir 'retrospective-counter.txt'
$lastReminded = 0
if (Test-Path $counterPath) {
    $raw = Get-Content $counterPath -Raw -ErrorAction SilentlyContinue
    $tmp = 0
    if ($raw -and [int]::TryParse($raw.Trim(), [ref]$tmp)) { $lastReminded = $tmp }
}

# --- Emit only when a new interval boundary has been crossed ---
$currentBucket = [math]::Floor($completed / $interval)
$lastBucket = [math]::Floor($lastReminded / $interval)
if ($currentBucket -le $lastBucket) { exit 0 }

# --- Persist the new high-water mark ---
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}
Set-Content -Path $counterPath -Value $completed -NoNewline -ErrorAction SilentlyContinue

# --- Banner ---
Write-Host ''
Write-Host '=== Retrospective Due (retrospective-check) ==='
Write-Host "  $completed workflow cycles completed (reminder every $interval)."
Write-Host '  The system measures itself only when you run the loop.'
Write-Host '  Action: run the /retrospective prompt to capture what worked,'
Write-Host '  what was reworked, and whether each agent earned its coordination cost.'
Write-Host '==============================================='
Write-Host ''

exit 0
