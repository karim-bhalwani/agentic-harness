# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# quality-gate.ps1
# Stop hook: enforce ruff lint + ty type check (Python), sqlfluff lint (SQL),
# and yamllint (YAML) before agent declares done, plus PLAN-phase story invariant checks.
#
# Env vars:
#   SKIP_QUALITY_GATE=true   - bypass entirely (emergency circuit breaker)
#   SKIP_WAVE_GATE=true       - bypass only the PLAN-phase wave parallelism check
#   GUARD_MODE=warn           - log errors without blocking (default: block)
#   GOVERNANCE_LEVEL=open|standard|strict|locked (default: standard; open => warn)
#   STORY_ID                  - active story override (precedence: env > .active-story file)
#   QUALITY_GATE_FORCE=true   - run lint/type checks even when no lintable files changed
#
# Lifecycle: fires on Stop event. Always checks stop_hook_active to avoid
# infinite loops (required — see HOOKS-GUIDE.md anti-patterns).

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

# --- Circuit breaker ---
if (Test-MMCircuitBreaker -EnvVar 'SKIP_QUALITY_GATE') {
    Write-Host 'Quality gate skipped (SKIP_QUALITY_GATE=true)'
    exit 0
}

# --- Read stdin (VS Code pipes JSON event data) ---
$inputData = Read-MMHookInput
# CRITICAL: prevent infinite loop. `stop_hook_active` is set by the hook runner
# in the Stop-event JSON payload when the agent is re-entering after a prior
# Stop hook decision. In that re-entrant path, this hook must no-op and exit.
if ($inputData -and (Test-MMStopReentry -InputData $inputData)) { exit 0 }

# Resolve mode: GUARD_MODE overrides; otherwise governance open => warn, else block.
$governanceLevel = Get-MMGovernanceLevel
$mode = Resolve-MMMode -OverrideEnvVar 'GUARD_MODE' -GovernanceLevel $governanceLevel `
    -StrictDefault 'block' -StandardDefault 'block' -OpenDefault 'warn'
$errors = [System.Collections.Generic.List[string]]::new()

# --- PLAN-phase story invariant checks (file-based; no git dependency) ---
# Detect active story: STORY_ID env var takes precedence, then .active-story file.
$repoRoot = Get-MMRepoRoot
$storyId = $null
if ($env:STORY_ID) {
    $storyId = $env:STORY_ID.Trim()
}
else {
    $activeStoryPath = Join-Path $repoRoot '.copilot\stories\.active-story'
    if (Test-Path $activeStoryPath) {
        $candidate = Get-Content $activeStoryPath -Raw -ErrorAction SilentlyContinue
        if ($candidate) { $storyId = $candidate.Trim() }
    }
}

if ($storyId) {
    $planPath = Join-Path $repoRoot ".copilot\stories\$storyId-PLAN.md"
    $reportPath = Join-Path $repoRoot ".copilot\stories\reports\$storyId-report.md"

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

# --- Wave-gating (PLAN-phase parallelism enforcement) ---
# STORIES.md declares wave numbers per story. Story N+1 cannot be 'in-progress'
# or 'done' until every story in wave N is 'done'. This prevents the BUILD
# phase from skipping waves and silently violating the agreed dependency order.
#
# Activation: only runs when .copilot/stories/STORIES.md exists.
# Bypass: SKIP_WAVE_GATE=true.
# Format expected: the §3.1 Summary Table (canonical) - column order:
#   ID | Title | Type | Wave | Depends On | Priority | Effort | Security | Holdout | Risk | Status | Owner
# Also accepts a bullet-list fallback for ad-hoc usage:
#   - **US-001** | wave: 1 | status: done | <title>
if ($env:SKIP_WAVE_GATE -ne 'true') {
    $storiesPath = Join-Path $repoRoot '.copilot\stories\STORIES.md'
    if (Test-Path $storiesPath) {
        $storiesContent = Get-Content $storiesPath -Raw -ErrorAction SilentlyContinue
        if ($storiesContent) {
            # Build {wave -> [{id, status}]}
            $byWave = @{}
            $foundAnyRow = $false

            # Primary parser: Summary Table rows (12 pipe-separated cells starting with US-id).
            $tableRowRegex = '(?im)^\s*\|\s*(US-[\w-]+)\s*\|[^\|\r\n]*\|[^\|\r\n]*\|\s*(\d+)\s*\|[^\|\r\n]*\|[^\|\r\n]*\|[^\|\r\n]*\|[^\|\r\n]*\|[^\|\r\n]*\|[^\|\r\n]*\|\s*([\w-]+)\s*\|'
            $tableRows = [regex]::Matches($storiesContent, $tableRowRegex)
            foreach ($m in $tableRows) {
                $sid = $m.Groups[1].Value
                $wave = [int]$m.Groups[2].Value
                $status = $m.Groups[3].Value.ToLowerInvariant()
                if (-not $byWave.ContainsKey($wave)) { $byWave[$wave] = @() }
                $byWave[$wave] += @{ id = $sid; status = $status }
                $foundAnyRow = $true
            }

            # Fallback parser: bullet-list pattern.
            if (-not $foundAnyRow) {
                $bulletRegex = '(?im)^\s*[-*]\s*\*\*?\s*(US-[\w-]+)\s*\*\*?\s*\|\s*wave\s*:\s*(\d+)\s*\|\s*status\s*:\s*([\w-]+)'
                $bulletRows = [regex]::Matches($storiesContent, $bulletRegex)
                foreach ($m in $bulletRows) {
                    $sid = $m.Groups[1].Value
                    $wave = [int]$m.Groups[2].Value
                    $status = $m.Groups[3].Value.ToLowerInvariant()
                    if (-not $byWave.ContainsKey($wave)) { $byWave[$wave] = @() }
                    $byWave[$wave] += @{ id = $sid; status = $status }
                    $foundAnyRow = $true
                }
            }

            if ($foundAnyRow) {
                # Walk waves in ascending order. For each wave w, if any later
                # wave w' > w has a story whose status is not 'not-started',
                # then every wave-w story MUST already be 'done'.
                $sortedWaves = $byWave.Keys | Sort-Object
                $violations = [System.Collections.Generic.List[string]]::new()
                foreach ($w in $sortedWaves) {
                    $laterStarted = $false
                    foreach ($wl in $sortedWaves) {
                        if ($wl -le $w) { continue }
                        foreach ($s in $byWave[$wl]) {
                            if ($s.status -ne 'not-started') { $laterStarted = $true; break }
                        }
                        if ($laterStarted) { break }
                    }
                    if ($laterStarted) {
                        $unfinished = @($byWave[$w] | Where-Object { $_.status -ne 'done' })
                        foreach ($u in $unfinished) {
                            $violations.Add("Wave $w story $($u.id) is '$($u.status)' but a later wave already started. Finish wave $w before opening the next wave.")
                        }
                    }
                }

                if ($violations.Count -gt 0) {
                    $errors.Add("ERROR (quality-gate / wave-gating): " + ($violations -join ' | ') + " Bypass with SKIP_WAVE_GATE=true if you accept the risk. Next agent: story-master (re-sequence) or finish blocking wave first.")
                }
            }
            elseif (-not $foundAnyRow) {
                # STORIES.md exists but no rows parsed. Warn so the silent-skip
                # failure mode (column count change, renamed headers) is visible.
                Write-Host "WARNING (quality-gate / wave-gating): STORIES.md exists but no story rows were parsed. Verify the Summary Table column order matches the expected 12-column schema (ID | Title | Type | Wave | Depends On | Priority | Effort | Security | Holdout | Risk | Status | Owner). Wave-gating skipped."
            }
        }
    }
}

# --- Detect modified file types (Python / SQL / YAML) ---
# Collect explicit changed-file lists so linters scope to changed files only
# (running `ruff check .` on a large repo can exceed the 60s Stop timeout).
$pythonFiles = [System.Collections.Generic.List[string]]::new()
$sqlFiles = [System.Collections.Generic.List[string]]::new()
$yamlFiles = [System.Collections.Generic.List[string]]::new()
if (Get-Command git -ErrorAction SilentlyContinue) {
    $changed = & git status --porcelain 2>$null
    if ($LASTEXITCODE -eq 0 -and $changed) {
        foreach ($line in ($changed -split "`n")) {
            # porcelain format: XY <path>; path starts at column 4
            $filePath = $line.Substring(3).Trim().Trim('"')
            if ($filePath -match '\.py$') { $pythonFiles.Add($filePath) }
            elseif ($filePath -match '\.sql$') { $sqlFiles.Add($filePath) }
            elseif ($filePath -match '\.(yaml|yml)$') { $yamlFiles.Add($filePath) }
        }
    }
}
$pythonTouched = $pythonFiles.Count -gt 0
$sqlTouched = $sqlFiles.Count -gt 0
$yamlTouched = $yamlFiles.Count -gt 0

# Skip lint/type checks when no lintable files were touched.
if (-not $pythonTouched -and -not $sqlTouched -and -not $yamlTouched -and $env:QUALITY_GATE_FORCE -ne 'true') {
    if ($errors.Count -eq 0) {
        Write-Host 'Quality gate skipped (no .py, .sql, or .yaml/.yml files modified). Set QUALITY_GATE_FORCE=true to override.'
        exit 0
    }
    # Story errors collected: skip lint/type but still report below.
    $skipLintType = $true
}
else {
    $skipLintType = $false
}

# --- ruff lint (Python) - scoped to changed files ---
if (-not $skipLintType -and $pythonTouched -and (Get-Command ruff -ErrorAction SilentlyContinue)) {
    # Filter to files that still exist (deletions would otherwise error).
    $targets = $pythonFiles | Where-Object { Test-Path $_ -PathType Leaf }
    if ($targets) {
        $null = & ruff check $targets --quiet 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errors.Add("Lint errors found: run 'ruff check $($targets -join ' ')' to see details")
        }
    }
}

# --- ty type check (Python) - scoped to changed files ---
if (-not $skipLintType -and $pythonTouched -and (Get-Command ty -ErrorAction SilentlyContinue)) {
    $targets = $pythonFiles | Where-Object { Test-Path $_ -PathType Leaf }
    if ($targets) {
        $null = & ty check $targets 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errors.Add("Type errors found: run 'ty check $($targets -join ' ')' to see details")
        }
    }
}

# --- sqlfluff lint (SQL) - scoped to changed files ---
# Only fires when .sql files were modified and sqlfluff is installed.
# Dialect and rules are configured in .sqlfluff at the repo root.
if (-not $skipLintType -and $sqlTouched -and (Get-Command sqlfluff -ErrorAction SilentlyContinue)) {
    $targets = $sqlFiles | Where-Object { Test-Path $_ -PathType Leaf }
    if ($targets) {
        $null = & sqlfluff lint $targets --quiet 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errors.Add("SQL lint errors found: run 'sqlfluff lint $($targets -join ' ')' to see details")
        }
    }
}

# --- yamllint (YAML) - scoped to changed files ---
# Only fires when .yaml/.yml files were modified and yamllint is installed.
# Rules are configured in .yamllint at the repo root (aligned with yaml-standards.instructions.md).
if (-not $skipLintType -and $yamlTouched -and (Get-Command yamllint -ErrorAction SilentlyContinue)) {
    $targets = $yamlFiles | Where-Object { Test-Path $_ -PathType Leaf }
    if ($targets) {
        $null = & yamllint $targets 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errors.Add("YAML lint errors found: run 'yamllint $($targets -join ' ')' to see details")
        }
    }
}

# --- Report ---
if ($errors.Count -gt 0) {
    $msg = "Quality gate failed. Fix the issues listed below, then re-run/continue the agent to proceed:`n" + ($errors -join "`n")
    Write-MMHookLog -HookName 'quality-gate' -Event 'gate_failed' -Decision 'deny' `
        -Extra @{ mode = $mode; error_count = $errors.Count; python_files = $pythonFiles.Count; sql_files = $sqlFiles.Count; yaml_files = $yamlFiles.Count }
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
else {
    Write-MMHookLog -HookName 'quality-gate' -Event 'gate_passed' -Decision 'allow' `
        -Extra @{ mode = $mode; python_files = $pythonFiles.Count; sql_files = $sqlFiles.Count; yaml_files = $yamlFiles.Count }
}

exit 0
