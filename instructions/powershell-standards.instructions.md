---
name: "PowerShell Coding Standards"
description: "PowerShell 7 conventions for hooks and tooling: approved verbs, strict mode, parameter typing, error handling, and shared library usage."
applyTo: "**/*.ps1"
version: "9.0"
updated: "01-July-2026"
---

# PowerShell Coding Standards

## Style

- Target PowerShell 7+ (`pwsh`). No Windows-PowerShell-only cmdlets.
- Use approved verbs (`Get-`, `Set-`, `Test-`, `Invoke-`, `New-`, `Write-`). Run `Get-Verb` to verify.
- Function names: `Verb-MMNoun` for shared helpers (the `MM` prefix scopes them to mega-minions).
- Use full cmdlet names, not aliases (`Get-ChildItem` not `gci`, `ForEach-Object` not `%`).
- 4-space indentation. Opening brace on the same line.
- Quote string literals with single quotes unless interpolation is needed.

## Strictness & Errors

- Start scripts with `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` where appropriate.
- Hooks should be tolerant: prefer `-ErrorAction SilentlyContinue` on best-effort calls (logging, optional reads) and let the explicit policy decisions drive `exit` codes.
- Never swallow errors silently in business logic; always `Write-MMHookLog` or rethrow.

## Parameters

- Type every parameter (`[string]`, `[hashtable]`, `[switch]`). Mark required params with `[Parameter(Mandatory)]`.
- Prefer `[switch]` over `[bool]` for flags.
- Use `param()` blocks at the top of scripts and functions; do not parse `$args` manually.

## Hook Conventions (this repo)

- Every hook MUST dot-source `_lib.ps1`: `. "$PSScriptRoot/_lib.ps1"`.
- Read JSON input via `Read-MMHookInput`; never read `$input` directly.
- Use `Get-MMGovernanceLevel` and `Resolve-MMMode` to determine policy posture.
- Emit decisions via `Write-MMHookDecision` / `Write-MMHookContext`; do not hand-roll JSON output.
- Log to JSONL via `Write-MMHookLog`. One event per line, structured fields only.
- Respect the `SKIP_<HOOK>` circuit-breaker env vars defined per hook.

## Testing

- Tests live in `hooks/tests/*.Tests.ps1` using Pester 5.
- Use the `Invoke-Hook` helper pattern (BeforeAll) with `cmd /c "type tmp | pwsh -NoProfile -File $HookPath"` for cross-platform stdin piping.
- Isolate filesystem state in `$env:TEMP` subfolders; clean up in `finally` blocks.
