# Hook Tests

> Version: 8.0 | Updated: 2026-05-03

[Pester](https://pester.dev/) tests for the PowerShell hook scripts in this directory.

## Run

```powershell
# All tests
Invoke-Pester ./hooks/tests

# A single hook
Invoke-Pester ./hooks/tests/block-destructive.Tests.ps1

# Verbose output
Invoke-Pester ./hooks/tests -Output Detailed
```

## Conventions

- One `*.Tests.ps1` per hook script under test
- Each test pipes a JSON fixture to the hook via `[Console]::In` and asserts on stdout/exit code
- `It` blocks describe single behaviors (one assertion family each)
- No external network or filesystem mutation outside `TestDrive:`

## Fixture format

Hook scripts read a JSON event payload from stdin. Tests build the payload as a PowerShell hashtable and pipe `ConvertTo-Json` output to the script:

```powershell
$payload = @{ tool_name = 'run_in_terminal'; tool_input = @{ command = 'rm -rf /' } }
$result = $payload | ConvertTo-Json | & pwsh -File ./hooks/block-destructive.ps1
```

## What is covered

| Hook | Test file | Cases |
|---|---|---|
| `block-destructive.ps1` | `block-destructive.Tests.ps1` | blocks dangerous commands; bypasses temp-dir paths; respects `SKIP_DESTRUCTIVE_GUARD`; honors allowlist |
| `scan-user-prompt.ps1` | `scan-user-prompt.Tests.ps1` | warns on injection markers; warns on credential patterns; clean prompt passes through |
