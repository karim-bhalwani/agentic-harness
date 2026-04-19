# Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani |
#
# quality-gate.ps1
# Stop hook: enforce ruff lint + ty type check before agent declares done.
#
# Env vars:
#   SKIP_QUALITY_GATE=true   - bypass entirely (emergency circuit breaker)
#   GUARD_MODE=warn           - log errors without blocking (default: block)
#
# Lifecycle: fires on Stop event. Always checks stop_hook_active to avoid
# infinite loops (required — see HOOKS-GUIDE.md anti-patterns).

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_QUALITY_GATE -eq 'true') {
    Write-Host 'Quality gate skipped (SKIP_QUALITY_GATE=true)'
    exit 0
}

# --- Read stdin (VS Code pipes JSON event data) ---
$rawInput = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
    try {
        $inputData = $rawInput | ConvertFrom-Json
        # CRITICAL: prevent infinite loop.
        # `stop_hook_active` is set by the hook runner in the Stop-event JSON payload
        # when the agent is continuing/re-entering after a prior Stop hook decision.
        # In that re-entrant path, this hook must no-op and exit so it does not block
        # a second time and cause a continue->Stop-hook loop.
        if ($inputData.stop_hook_active -eq $true) { exit 0 }
    }
    catch {
        # Malformed JSON from VS Code is non-fatal; continue with checks.
    }
}

$mode = if ($env:GUARD_MODE) { $env:GUARD_MODE } else { 'block' }
$errors = [System.Collections.Generic.List[string]]::new()

# --- ruff lint (Python) ---
if (Get-Command ruff -ErrorAction SilentlyContinue) {
    $null = & ruff check . --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        $errors.Add("Lint errors found: run 'ruff check .' to see details")
    }
}

# --- ty type check (Python) ---
if (Get-Command ty -ErrorAction SilentlyContinue) {
    $null = & ty check . 2>&1
    if ($LASTEXITCODE -ne 0) {
        $errors.Add("Type errors found: run 'ty check .' to see details")
    }
}

# --- Report ---
if ($errors.Count -gt 0) {
    $msg = "Quality gate failed. Fix the issues listed below, then re-run/continue the agent to proceed:`n" + ($errors -join "`n")
    if ($mode -eq 'block') {
        $output = [ordered]@{
            hookSpecificOutput = [ordered]@{
                hookEventName = 'Stop'
                decision      = 'block'
                reason        = $msg
            }
        } | ConvertTo-Json -Depth 5 -Compress:$false

        Write-Output $output
        exit 0   # exit 0 so VS Code parses the JSON; decision=block prevents close
    }
    else {
        Write-Host "WARNING: $msg"
    }
}

exit 0
