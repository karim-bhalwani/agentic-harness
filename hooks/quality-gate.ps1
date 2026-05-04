# Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |
#
# quality-gate.ps1
# Stop hook: enforce ruff lint + ty type check before agent declares done,
# plus PLAN-phase story invariant checks (plan present, tasks ticked, report present).
#
# Env vars:
#   SKIP_QUALITY_GATE=true   - bypass entirely (emergency circuit breaker)
#   GUARD_MODE=warn           - log errors without blocking (default: block)
#   STORY_ID                  - active story override (precedence: env > .active-story file)
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

# --- PLAN-phase story invariant checks (file-based; no git dependency) ---
# Detect active story: STORY_ID env var takes precedence, then .active-story file.
$storyId = $null
if ($env:STORY_ID) {
    $storyId = $env:STORY_ID.Trim()
}
else {
    $activeStoryPath = Join-Path (Get-Location).Path '.copilot\stories\.active-story'
    if (Test-Path $activeStoryPath) {
        $candidate = Get-Content $activeStoryPath -Raw -ErrorAction SilentlyContinue
        if ($candidate) { $storyId = $candidate.Trim() }
    }
}

if ($storyId) {
    $planPath = Join-Path (Get-Location).Path ".copilot\stories\$storyId-PLAN.md"
    $reportPath = Join-Path (Get-Location).Path ".copilot\stories\reports\$storyId-report.md"

    if (-not (Test-Path $planPath)) {
        $errors.Add("ERROR (quality-gate): Active story is $storyId but no plan exists at .copilot/stories/$storyId-PLAN.md. Fix: run story-planner with story id $storyId before writing any code. Next agent: story-planner.")
    }
    else {
        # Plan exists: check unchecked tasks
        $planContent = Get-Content $planPath -Raw -ErrorAction SilentlyContinue
        if ($planContent) {
            $uncheckedMatches = [regex]::Matches($planContent, '(?m)^\s*-\s*\[\s*\]\s*(T-[\w-]+)')
            if ($uncheckedMatches.Count -gt 0) {
                $taskIds = ($uncheckedMatches | ForEach-Object { $_.Groups[1].Value }) -join ', '
                $errors.Add("ERROR (quality-gate): Story $storyId has unchecked tasks: $taskIds. Fix: complete the tasks or document deviations in the plan's 'Deviations from Plan' section, then retry. Next agent: senior-developer (or data-engineer / ai-engineer).")
            }
            elseif (-not (Test-Path $reportPath)) {
                # All tasks checked but no report
                $errors.Add("ERROR (quality-gate): Story $storyId has no implementation report. Fix: write .copilot/stories/reports/$storyId-report.md (see enhancement.md section 3.3 schema). Next agent: same BUILD agent.")
            }
        }
    }
}

# --- Skip remaining lint/type checks if no Python files were modified ---
# Lints/types are scoped to Python. If the agent did not touch any .py files
# in the working tree (staged, unstaged, or untracked), skip the gate to avoid
# noisy failures on doc-only or non-Python work.
$pythonTouched = $false
if (Get-Command git -ErrorAction SilentlyContinue) {
    $changed = & git status --porcelain 2>$null
    if ($LASTEXITCODE -eq 0 -and $changed) {
        foreach ($line in ($changed -split "`n")) {
            if ($line -match '\.py(\s|$)') { $pythonTouched = $true; break }
        }
    }
}
if (-not $pythonTouched -and $env:QUALITY_GATE_FORCE -ne 'true') {
    if ($errors.Count -eq 0) {
        Write-Host 'Quality gate skipped (no .py files modified). Set QUALITY_GATE_FORCE=true to override.'
        exit 0
    }
    # Story errors collected: skip lint/type but still report below.
    $skipLintType = $true
}
else {
    $skipLintType = $false
}

# --- ruff lint (Python) ---
if (-not $skipLintType -and (Get-Command ruff -ErrorAction SilentlyContinue)) {
    $null = & ruff check . --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        $errors.Add("Lint errors found: run 'ruff check .' to see details")
    }
}

# --- ty type check (Python) ---
if (-not $skipLintType -and (Get-Command ty -ErrorAction SilentlyContinue)) {
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
