# Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |
#
# scan-secrets.ps1
# Stop hook: scan all files modified in this session for leaked credentials.
#
# Scans 13 credential patterns: AWS, GCP, Azure, GitHub PATs, private keys,
# Stripe, Slack tokens, npm tokens, JWTs, DB connection strings, generic secrets.
# Skips obvious placeholder values (example, dummy, changeme, etc.).
#
# Env vars:
#   SKIP_SECRETS_SCAN=true  - bypass entirely (emergency circuit breaker)
#   SCAN_MODE=warn           - log findings without blocking
#   SCAN_MODE=block          - block agent from finishing when secrets detected (default) (default)
#
# Lifecycle: fires on Stop event. Checks stop_hook_active to avoid infinite loops.
# Requires git — skips gracefully if not in a git repository.

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_SECRETS_SCAN -eq 'true') {
    Write-Host 'Secrets scan skipped (SKIP_SECRETS_SCAN=true)'
    exit 0
}

# --- Read stdin and check infinite loop guard ---
$rawInput = [Console]::In.ReadToEnd()
if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
    try {
        $inputData = $rawInput | ConvertFrom-Json
        if ($inputData.stop_hook_active -eq $true) { exit 0 }
    }
    catch {
        # Non-fatal: continue scan even if JSON parse fails
    }
}

$mode = if ($env:SCAN_MODE) { $env:SCAN_MODE } else { 'block' }

# --- Require git ---
$null = & git rev-parse --is-inside-work-tree 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Secrets scan: not in a git repository, skipping'
    exit 0
}

# --- Credential patterns: Name | Severity | Regex ---
$patterns = @(
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
    @{ Name = 'GENERIC_SECRET'; Severity = 'high'; Regex = '(secret|token|password|api[_\-]?key)\s*[:=]\s*[''"]?[A-Za-z0-9_/+=~.\-]{16,}' }
)

# Placeholder filter — skip obvious example / test values
$placeholderPattern = 'example|placeholder|your[_\-]|xxx|changeme|TODO|FIXME|replace[_\-]?me|dummy|fake|test[_\-]?key|sample'

# --- Collect modified + new (untracked) files ---
$gitDiff = & git diff --name-only --diff-filter=ACMR HEAD 2>$null
$untracked = & git ls-files --others --exclude-standard 2>$null
$allFiles = @($gitDiff) + @($untracked) |
Where-Object { $_ -and (Test-Path $_ -PathType Leaf) } |
Select-Object -Unique

if ($allFiles.Count -eq 0) {
    Write-Host 'Secrets scan: no modified files to scan'
    exit 0
}

Write-Host "Secrets scan: scanning $($allFiles.Count) file(s)..."
$findingCount = 0

foreach ($file in $allFiles) {
    # Path traversal guard
    if ($file -match '\.\.') { continue }

    $lines = Get-Content -Path $file -ErrorAction SilentlyContinue
    if (-not $lines) { continue }

    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
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
        Write-Host "Secrets scan: $findingCount potential secret(s) found (warn mode). Set SCAN_MODE=block to enforce blocking."
    }
}
else {
    Write-Host 'Secrets scan: no secrets detected'
}

exit 0
