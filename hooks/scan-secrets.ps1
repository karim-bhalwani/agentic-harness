# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# scan-secrets.ps1
# Stop hook: scan all files modified in this session for leaked credentials.
#
# Scans 18 credential patterns: AWS, GCP, Azure, GitHub PATs, private keys,
# Stripe, Slack tokens, npm tokens, JWTs, DB connection strings, Databricks,
# HuggingFace, SendGrid, Twilio, generic secrets.
# Skips obvious placeholder values (example, dummy, changeme, etc.).
#
# Env vars:
#   SKIP_SECRETS_SCAN=true  - bypass entirely (emergency circuit breaker)
#   SCAN_MODE=warn           - log findings without blocking
#   SCAN_MODE=block          - block agent from finishing when secrets detected (default)
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

try {
    # --- Main body: a crash below must NOT let the Stop gate pass silently ---
    # (fail-closed envelope per upgrade-plan 2.1.3; catch is at end of file).
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
    # @(...) wrapper: an empty pipeline yields $null, and $null.Count throws under
    # StrictMode (fail-closed envelope would then block a clean repo).
    $allFiles = @(@($gitDiff) + @($untracked) |
        Where-Object { $_ -and (Test-Path $_ -PathType Leaf) } |
        Select-Object -Unique)

    # --- Gitignored secret-bearing files ---
    $repoRoot = Get-MMRepoRoot
    # The --exclude-standard pass above intentionally honours .gitignore, which
    # means the most common secret-hiding spots (.env, secrets.json, *.pem) are
    # NEVER scanned. Add an explicit pass over high-risk filenames that exist on
    # disk regardless of git status. This closes the gap where a leaked credential
    # in a gitignored file passes the Stop gate silently.
    $secretFileNames = @(
        '.env', '.env.local', '.env.*', '*.env', 'secrets.json', 'secrets.yaml',
        'secrets.yml', 'credentials.json', 'credentials.yaml', '*.pem', '*.key',
        '*.pfx', '*.p12', 'id_rsa', 'id_ed25519', 'id_dsa', 'id_ecdsa',
        'service-account.json', '*.tfvars', '*.tfstate'
    )
    $gitIgnoredSecrets = @()
    foreach ($glob in $secretFileNames) {
        try {
            $gitIgnoredSecrets += @(Get-ChildItem -Path $repoRoot -Recurse -File -Force `
                    -ErrorAction SilentlyContinue -Filter $glob |
                Where-Object { -not ($_.FullName -match '[\\/](node_modules|\.git|\.venv|venv|dist|build)[\\/]') } |
                ForEach-Object { $_.FullName })
        }
        catch { }
    }
    $allFiles = @(@($allFiles) + @($gitIgnoredSecrets) |
        Where-Object { $_ -and (Test-Path $_ -PathType Leaf) } |
        Select-Object -Unique)

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
        # NOTE: a filename containing '..' (e.g. config..json) is NOT skipped. The
        # old `if ($file -match '\.\.') { continue }` excluded such files from
        # scanning, which is an evasion channel. Scanning a weird filename is safe.

        # File-size guard (H-05 fix): instead of skipping oversized files entirely
        # (which let a padded secret-bearing file bypass the gate), stream the file
        # line-by-line and scan bounded head AND tail chunks. Files above the
        # threshold are still scanned; only the unbounded middle is sampled. The
        # old estimate of "lines = bytes / 80" was wrong and could miss a real
        # secret padded into the tail, so we now read the actual head (first 2000
        # lines) and tail (last 2000 lines) and scan both.
        $isOversized = $false
        try {
            $fileInfo = Get-Item -LiteralPath $file -ErrorAction Stop
            if ($fileInfo.Length -gt $maxScanBytes) { $isOversized = $true }
        }
        catch { continue }

        $lines = @()
        try {
            if ($isOversized) {
                # Deterministic head + tail sampling: read the first 2000 lines and
                # the last 2000 lines, then scan both. This catches secrets padded
                # into either end of a large file (the common evasion: a 5000-line
                # file with the secret on line 4999).
                $head = @(Get-Content -Path $file -TotalCount 2000 -ErrorAction SilentlyContinue)
                $tail = @(Get-Content -Path $file -Tail 2000 -ErrorAction SilentlyContinue)
                $lines = @($head) + @($tail)
                Write-Host "  $file  streamed (>$(([int]($maxScanBytes / 1MB)))MB; scanned head+tail)"
            }
            else {
                $lines = Get-Content -Path $file -ErrorAction SilentlyContinue
            }
        }
        catch { continue }
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

                    # Skip placeholders — whole-value anchored rule so a real
                    # credential containing a sentinel word (e.g. 'sample') is NOT
                    # suppressed (H-03 fix).
                    if ($match -imatch $placeholderPattern) { continue }

                    # Redact for safe output — never echo any secret characters.
                    $redacted = '[REDACTED:<' + $pat.Name + '>]'

                    Write-Host "  $file`:$lineNum  [$($pat.Severity.ToUpper())] $redacted"
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
}
catch {
    # A crash in the scanner must NOT let the Stop gate pass silently
    # (that would bypass the secrets gate). Fail closed with a Stop-shaped block.
    Write-MMHookFailClosedDeny -HookName 'scan-secrets' -Exception $_ -HookEvent 'Stop'
}
