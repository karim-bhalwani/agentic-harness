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

[CmdletBinding()]
param()

# --- Circuit breaker ---
if ($env:SKIP_AUTO_FORMAT -eq 'true') { exit 0 }

# --- Resolve file path ---
$filePath = $env:TOOL_INPUT_FILE_PATH

if (-not $filePath) {
    # Fallback: parse file path from stdin JSON
    $rawInput = [Console]::In.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
        try {
            $inputData = $rawInput | ConvertFrom-Json
            $filePath = $inputData.tool_input.filePath
        }
        catch {
            exit 0
        }
    }
}

# Nothing to format
if (-not $filePath) { exit 0 }

# Path traversal guard
if ($filePath -match '\.\.') {
    [Console]::Error.WriteLine("auto-format: path traversal detected in file path, skipping.")
    exit 0
}

if (-not (Test-Path $filePath -PathType Leaf)) { exit 0 }

# --- Python: ruff format ---
if ($filePath -match '\.py$') {
    if (Get-Command ruff -ErrorAction SilentlyContinue) {
        $null = & ruff format $filePath 2>&1
    }
}
# --- JS / TS / JSON / CSS / Markdown: prettier ---
elseif ($filePath -match '\.(js|ts|jsx|tsx|json|css|md)$') {
    if (Get-Command npx -ErrorAction SilentlyContinue) {
        $null = & npx prettier --write $filePath 2>&1
    }
}

exit 0
