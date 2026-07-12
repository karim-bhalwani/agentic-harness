# Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
#
# auto-format.ps1
# PostToolUse hook: auto-format files after every agent file write.
#
# Supported formatters:
#   .py               - ruff format (must be in PATH / active venv)
#   .js .ts .jsx .tsx
#   .json .css .md    - npx prettier --write (requires node/npx in PATH)
#
# Env vars:
#   SKIP_AUTO_FORMAT=true  - bypass entirely (emergency circuit breaker)
#
# File path resolution order:
#   1. TOOL_INPUT_FILE_PATH env var (set by VS Code for file-writing tools)
#   2. tool_input.filePath from stdin JSON (fallback)
#
# Lifecycle: fires on every PostToolUse event. Silently exits 0 for non-file
# tool calls (no file path available).

#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

# Shared helpers (governance, logging, stdin, decisions) from _lib.ps1.
. (Join-Path $PSScriptRoot '_lib.ps1')

# Cache formatter availability for the session (avoid repeated Get-Command calls on every PostToolUse)
$script:ruffAvailable = $null
$script:prettierAvailable = $null

function Test-FormatterAvailable {
    param([string]$Name)
    switch ($Name) {
        'ruff' {
            if ($null -eq $script:ruffAvailable) {
                $script:ruffAvailable = [bool](Get-Command ruff -ErrorAction SilentlyContinue)
            }
            return $script:ruffAvailable
        }
        'prettier' {
            if ($null -eq $script:prettierAvailable) {
                $script:prettierAvailable = [bool](Get-Command npx -ErrorAction SilentlyContinue)
            }
            return $script:prettierAvailable
        }
    }
    return $false
}

# --- Circuit breaker ---
if (Test-MMCircuitBreaker -EnvVar 'SKIP_AUTO_FORMAT') { exit 0 }

# --- Resolve file path ---
$filePath = $env:TOOL_INPUT_FILE_PATH

if (-not $filePath) {
    # Fallback: parse file path from stdin JSON
    $inputData = Read-MMHookInput
    if ($inputData -and (Get-MMProp $inputData 'tool_input')) {
        $filePath = Get-MMProp (Get-MMProp $inputData 'tool_input') 'filePath' $null
    }
}

# Nothing to format
if (-not $filePath) { exit 0 }

# Path traversal guard. Test for a path SEGMENT equal to '..' (not a substring),
# so a benign filename like 'config..json' is formatted normally (H-03 fix).
if (($filePath -split '[\\/]') -contains '..') {
    Write-MMHookLog -HookName 'auto-format' -Event 'path_traversal_skipped' -Decision 'skip' `
        -Extra @{ file = $filePath }
    [Console]::Error.WriteLine("auto-format: path traversal detected in file path, skipping.")
    exit 0
}

if (-not (Test-Path $filePath -PathType Leaf)) { exit 0 }

# --- Python: ruff format ---
if ($filePath -match '\.py$') {
    if (Test-FormatterAvailable 'ruff') {
        $null = & ruff format $filePath 2>&1
        Write-MMHookLog -HookName 'auto-format' -Event 'formatted' -Decision 'allow' `
            -Extra @{ file = $filePath; formatter = 'ruff' }
    }
}
# --- JS / TS / JSON / CSS / Markdown: prettier ---
elseif ($filePath -match '\.(js|ts|jsx|tsx|json|css|md)$') {
    if (Test-FormatterAvailable 'prettier') {
        # --yes prevents npx from interactively prompting to install prettier
        # on first run (violates the non-interactive hook contract).
        $null = & npx --yes prettier --write $filePath 2>&1
        Write-MMHookLog -HookName 'auto-format' -Event 'formatted' -Decision 'allow' `
            -Extra @{ file = $filePath; formatter = 'prettier' }
    }
}

exit 0
