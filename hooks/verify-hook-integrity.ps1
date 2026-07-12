#Requires -Version 7.0
<#
.SYNOPSIS
    Generates or verifies the SHA-256 integrity manifest for hook files.

.DESCRIPTION
    Computes SHA-256 hashes of all .ps1 files in HooksDir (excluding the tests/
    subdirectory) plus hooks.json. On first run (no manifest), creates
    hooks.manifest.json. On subsequent runs, compares disk hashes against the
    manifest and exits 1 if any file has been added, removed, or tampered with.

.PARAMETER ManifestPath
    Path to the manifest JSON file.
    Default: hooks.manifest.json inside the script's parent directory.

.PARAMETER HooksDir
    Directory containing the hook files to hash.
    Default: the script's parent directory.

.EXAMPLE
    pwsh -NoProfile -File hooks/verify-hook-integrity.ps1
    # First run  : creates hooks/hooks.manifest.json, exits 0.
    # Subsequent : verifies all hashes, exits 0 (OK) or 1 (tampered).

.EXAMPLE
    pwsh -NoProfile -File hooks/verify-hook-integrity.ps1 `
        -HooksDir "$env:USERPROFILE\.copilot\hooks" `
        -ManifestPath hooks/hooks.manifest.json
    # Verify deployed user-global hooks against the repo manifest.
#>

[CmdletBinding()]
param(
    [string]$ManifestPath = '',
    [string]$HooksDir = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Shared helpers (logging, governance) from _lib.ps1 so the re-baseline branch
# can emit a structured JSONL log entry via Write-MMHookLog.
. (Join-Path $PSScriptRoot '_lib.ps1')

# ---------------------------------------------------------------------------
# Resolve defaults relative to the script's own location
# ---------------------------------------------------------------------------
if ([string]::IsNullOrEmpty($ManifestPath)) {
    $ManifestPath = Join-Path $PSScriptRoot 'hooks.manifest.json'
}
if ([string]::IsNullOrEmpty($HooksDir)) {
    $HooksDir = $PSScriptRoot
}

$resolvedHooksDir = (Resolve-Path -Path $HooksDir).Path
$testsSubdir = Join-Path $resolvedHooksDir 'tests'

# ---------------------------------------------------------------------------
# Collect files: all .ps1 in HooksDir (excluding tests/) plus hooks.json
# ---------------------------------------------------------------------------
function Get-TargetFiles {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [string]$Directory,
        [string]$ExcludeDir
    )

    $separator = [IO.Path]::DirectorySeparatorChar
    $excludePrefix = $ExcludeDir.TrimEnd($separator) + $separator

    $ps1Files = Get-ChildItem -Path $Directory -Filter '*.ps1' -File |
    Where-Object {
        -not $_.FullName.StartsWith($excludePrefix, [StringComparison]::OrdinalIgnoreCase)
    } |
    Sort-Object -Property Name

    $hooksJson = Get-Item -Path (Join-Path $Directory 'hooks.json') -ErrorAction SilentlyContinue

    $result = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($f in $ps1Files) { [void]$result.Add($f) }
    if ($null -ne $hooksJson) { [void]$result.Add($hooksJson) }
    return $result.ToArray()
}

# ---------------------------------------------------------------------------
# Convert absolute path to forward-slash relative path
# ---------------------------------------------------------------------------
function ConvertTo-RelativePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Base,
        [string]$Full
    )

    $separator = [IO.Path]::DirectorySeparatorChar
    $baseWithSlash = $Base.TrimEnd($separator) + $separator
    if ($Full.StartsWith($baseWithSlash, [StringComparison]::OrdinalIgnoreCase)) {
        return $Full.Substring($baseWithSlash.Length).Replace('\', '/')
    }
    return $Full.Replace('\', '/')
}

# ---------------------------------------------------------------------------
# Produce 2-space-indented JSON (ConvertTo-Json defaults to 4-space)
# ---------------------------------------------------------------------------
function Format-Json {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][object]$InputObject)

    $raw = $InputObject | ConvertTo-Json -Depth 10
    # Normalize 4-space indentation to 2-space
    return ($raw -replace '(?m)^( {4})+', { '  ' * ($_.Value.Length / 4) })
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
try {
    $files = Get-TargetFiles -Directory $resolvedHooksDir -ExcludeDir $testsSubdir

    if ($files.Count -eq 0) {
        Write-Error "No hook files found in '$resolvedHooksDir'."
        exit 1
    }

    # Compute current hashes keyed by forward-slash relative path
    $currentHashes = [ordered]@{}
    foreach ($file in ($files | Sort-Object -Property Name)) {
        $rel = ConvertTo-RelativePath -Base $resolvedHooksDir -Full $file.FullName
        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        $currentHashes[$rel] = $hash
    }

    if (-not (Test-Path -Path $ManifestPath)) {
        # ---- First run: create manifest ----
        # Loud re-baseline (H-09 fix): a missing manifest triggers a silent
        # clean re-baseline (TOFU) that lets tampering + manifest deletion go
        # unnoticed. When the manifest is missing and gets recreated, log a
        # 'manifest_rebaselined' warn event AND print a prominent warning to
        # stdout so the operator is forced to notice.
        $manifest = [ordered]@{
            generated = (Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')
            files     = $currentHashes
        }
        Set-Content -Path $ManifestPath -Value (Format-Json -InputObject $manifest) -Encoding UTF8
        Write-MMHookLog -HookName 'verify-hook-integrity' -Event 'manifest_rebaselined' -Decision 'warn' `
            -Extra @{ note = 'manifest was missing and has been re-baselined'; file_count = $currentHashes.Count }
        Write-Host "WARNING: hook integrity manifest was missing and has been re-baselined. If you did not intentionally delete hooks.manifest.json, verify hook contents manually before trusting this session."
        exit 0
    }

    # ---- Subsequent runs: verify ----
    $parsed = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
    $storedHashes = [hashtable]@{}
    foreach ($prop in $parsed.files.PSObject.Properties) {
        $storedHashes[$prop.Name] = $prop.Value
    }

    $mismatches = [System.Collections.Generic.List[string]]::new()
    $newFiles = [System.Collections.Generic.List[string]]::new()
    $gone = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $currentHashes.Keys) {
        if (-not $storedHashes.Contains($key)) {
            $newFiles.Add($key)
        }
        elseif ($currentHashes[$key] -ne $storedHashes[$key]) {
            $mismatches.Add(
                "  CHANGED  $key`n    stored: $($storedHashes[$key])`n    disk:   $($currentHashes[$key])"
            )
        }
    }
    foreach ($key in $storedHashes.Keys) {
        if (-not $currentHashes.Contains($key)) {
            $gone.Add($key)
        }
    }

    if ($mismatches.Count -eq 0 -and $newFiles.Count -eq 0 -and $gone.Count -eq 0) {
        Write-Host "Integrity OK: all $($currentHashes.Count) files match $ManifestPath"
        exit 0
    }

    Write-Host 'INTEGRITY FAILURE' -ForegroundColor Red
    foreach ($msg in $mismatches) { Write-Host $msg -ForegroundColor Red }
    if ($newFiles.Count -gt 0) {
        Write-Host "  NOT IN MANIFEST (new files): $($newFiles -join ', ')" -ForegroundColor Yellow
    }
    if ($gone.Count -gt 0) {
        Write-Host "  MISSING FROM DISK: $($gone -join ', ')" -ForegroundColor Yellow
    }
    exit 1
}
catch {
    Write-Error "verify-hook-integrity: $_"
    exit 1
}
