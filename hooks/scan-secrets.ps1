# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# scan-secrets.ps1
# Stop hook: scan all files modified in this session for leaked credentials.
#
# Scans 14 credential patterns: AWS, GCP, Azure, GitHub PATs, private keys,
# Stripe, Slack tokens, npm tokens, JWTs, DB connection strings, generic secrets.
# Skips obvious placeholder values (example, dummy, changeme, etc.).
#
# Env vars:
#   SKIP_SECRETS_SCAN=true  - bypass entirely (emergency circuit breaker)
#   SCAN_MODE=warn           - log findings without blocking
#   SCAN_MODE=block          - block agent from finishing when secrets detected (default) (default)
#   GOVERNANCE_LEVEL=open|standard|strict|locked (defaults to standard behavior)
#   HOOK_LOG_DIR=<path>      - override structured hook log directory
#
# Lifecycle: fires on Stop event. Checks stop_hook_active to avoid infinite loops.
# Requires git — skips gracefully if not in a git repository.

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

# --- Circuit breaker ---
if (Test-MMCircuitBreaker -EnvVar 'SKIP_SECRETS_SCAN') {
    Write-Host 'Secrets scan skipped (SKIP_SECRETS_SCAN=true)'
    exit 0
}

# --- Read stdin and check infinite loop guard ---
$inputData = Read-MMHookInput
if ($inputData -and (Test-MMStopReentry -InputData $inputData)) { exit 0 }

$governanceLevel = Get-MMGovernanceLevel
$mode = Resolve-MMMode -OverrideEnvVar 'SCAN_MODE' -GovernanceLevel $governanceLevel `
    -StrictDefault 'block' -StandardDefault 'block' -OpenDefault 'warn'

# --- Require git ---
$null = & git rev-parse --is-inside-work-tree 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Secrets scan: not in a git repository, skipping'
    exit 0
}

# --- Credential patterns: shared catalogue from _lib.ps1 ---
$patterns = Get-MMSecretPatterns

# Placeholder filter — skip obvious example / test values
$placeholderPattern = Get-MMSecretPlaceholderPattern

# --- Collect modified + new (untracked) files ---
$gitDiff = & git diff --name-only --diff-filter=ACMR HEAD 2>$null
$untracked = & git ls-files --others --exclude-standard 2>$null
$allFiles = @($gitDiff) + @($untracked) |
Where-Object { $_ -and (Test-Path $_ -PathType Leaf) } |
Select-Object -Unique

if ($allFiles.Count -eq 0) {
    Write-Host 'Secrets scan: no modified files to scan'
    Write-MMHookLog -HookName 'scan-secrets' -Event 'scan_complete' -Decision 'allow' `
        -Extra @{ mode = $mode; files_scanned = 0; finding_count = 0 }
    exit 0
}

Write-Host "Secrets scan: scanning $($allFiles.Count) file(s)..."
$findingCount = 0
# Build combined regex once for single-pass pre-filter (avoids 14 per-line match calls when no pattern matches)
$combinedPattern = ($patterns.Regex -join '|')
# Skip files larger than 10MB to avoid OOM / 30s timeout on huge generated
# files (e.g. lockfiles, minified bundles). 10MB is well above any reasonable
# source file and keeps the scan deterministic.
$maxScanBytes = if ($env:SCAN_SECRETS_MAX_BYTES) { [int64]$env:SCAN_SECRETS_MAX_BYTES } else { 10485760 }

foreach ($file in $allFiles) {
    # Path traversal guard
    if ($file -match '\.\.') { continue }

    # File-size guard
    try {
        $fileInfo = Get-Item -LiteralPath $file -ErrorAction Stop
        if ($fileInfo.Length -gt $maxScanBytes) {
            Write-Host "  $file  skipped (>$($maxScanBytes / 1MB)MB)"
            continue
        }
    }
    catch { continue }

    $lines = Get-Content -Path $file -ErrorAction SilentlyContinue
    if (-not $lines) { continue }

    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        # Fast pre-filter: single combined regex check before per-pattern matching
        if ($line -notmatch $combinedPattern) { continue }
        foreach ($pat in $patterns) {
            if ($line -match $pat.Regex) {
                $match = [regex]::Match($line, $pat.Regex).Value
                if (-not $match) { continue }

                # Skip placeholders
                if ($match -imatch $placeholderPattern) { continue }

                # Redact for safe output — show first 4 and last 4 chars only
                $redacted = if ($match.Length -gt 12) {
                    "$($match.Substring(0, 4))...$($match.Substring($match.Length - 4))"
                }
                else {
                    '[REDACTED]'
                }

                Write-Host "  $file`:$lineNum  [$($pat.Severity.ToUpper())] $($pat.Name): $redacted"
                $findingCount++
            }
        }
    }
}

# --- Report ---
if ($findingCount -gt 0) {
    Write-Host ''
    if ($mode -eq 'block') {
        $reason = "Secrets scan: $findingCount potential secret(s) detected. Resolve before finishing. " +
        "Set SCAN_MODE=warn to log without blocking, or SKIP_SECRETS_SCAN=true to bypass."

        Write-MMHookLog -HookName 'scan-secrets' -Event 'secrets_found' -Decision 'deny' `
            -Extra @{ mode = $mode; files_scanned = $allFiles.Count; finding_count = $findingCount }

        $output = [ordered]@{
            hookSpecificOutput = [ordered]@{
                hookEventName = 'Stop'
                decision      = 'block'
                reason        = $reason
            }
        } | ConvertTo-Json -Depth 5 -Compress:$false

        Write-Output $output
        exit 0   # exit 0 so VS Code parses the JSON; decision=block prevents close
    }
    else {
        Write-MMHookLog -HookName 'scan-secrets' -Event 'secrets_found' -Decision 'allow' `
            -Extra @{ mode = $mode; files_scanned = $allFiles.Count; finding_count = $findingCount }
        Write-Host "Secrets scan: $findingCount potential secret(s) found (warn mode). Set SCAN_MODE=block to enforce blocking."
    }
}
else {
    Write-MMHookLog -HookName 'scan-secrets' -Event 'scan_complete' -Decision 'allow' `
        -Extra @{ mode = $mode; files_scanned = $allFiles.Count; finding_count = 0 }
    Write-Host 'Secrets scan: no secrets detected'
}

exit 0
