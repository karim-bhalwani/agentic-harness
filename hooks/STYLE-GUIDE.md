# Hooks Coding Standards

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

All hook scripts in this directory follow a single shared style. New hooks
copy this layout exactly. Existing hooks are being migrated to use
[`_lib.ps1`](_lib.ps1); pull requests that touch a hook MUST migrate any
boilerplate left behind.

## Mandatory header

```powershell
# Version: <X.Y> | Updated: <DD-Month-YYYY> | Architect: Karim Bhalwani |
#
# <hook-name>.ps1
# <Event> hook: <one-sentence purpose>.
#
# Env vars:
#   SKIP_<NAME>=true              - emergency circuit breaker
#   GOVERNANCE_LEVEL=open|standard|strict|locked  - shared policy switch
#   <HOOK_NAME>_MODE=block|warn  - per-hook mode override (where applicable)
#   HOOK_LOG_DIR=<path>           - structured log override

[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_lib.ps1')
```

## Required boilerplate

Every hook MUST:

1. Dot-source `_lib.ps1` immediately after the param block.
2. Check the circuit breaker via `Test-MMCircuitBreaker -EnvVar 'SKIP_*'` before any work.
3. Read stdin via `Read-MMHookInput`. Pass through (exit 0) on `$null`.
4. For Stop hooks, check `Test-MMStopReentry` and no-op when re-entered.
5. Resolve governance via `Get-MMGovernanceLevel` and mode via `Resolve-MMMode`.
6. Log every decision via `Write-MMHookLog`. Never log secrets or full payloads.
7. Exit 0 when emitting structured JSON. Exit 2 only for hard UserPromptSubmit rejection.

## Naming

| Concept | Pattern | Example |
|---|---|---|
| Hook script | kebab-case, single purpose | `scan-secrets.ps1` |
| Library function | `Verb-MM<Noun>` | `Read-MMHookInput`, `Write-MMHookLog` |
| Circuit-breaker env var | `SKIP_<UPPER_SNAKE>` | `SKIP_SCAN_USER_PROMPT` |
| Mode env var | `<HOOK>_MODE` | `SCAN_MODE`, `PROMPT_SCAN_MODE` |
| Log file | `<hook-name>.jsonl` in `.copilot/state/hook-logs/` | `block-holdout.jsonl` |

## Logging schema

Every JSONL log line MUST conform to:

```json
{
  "timestamp": "<ISO-8601 UTC>",
  "hook": "<hook-name>",
  "event": "<short tag>",
  "decision": "allow|deny|warn|block|skip",
  "governance": "open|standard|strict|locked",
  "<extra fields ...>": "..."
}
```

`Write-MMHookLog` produces this shape automatically; do not hand-roll JSON.

## Anti-patterns

* Inline `if ($env:GOVERNANCE_LEVEL ...)` resolution. Always call `Get-MMGovernanceLevel`.
* Hand-rolled stdin parsing with bespoke try/catch. Always call `Read-MMHookInput`.
* Per-hook log writers. Always call `Write-MMHookLog`.
* `Write-Error` or `throw` at the top level. Hooks must never crash the agent harness.
* Non-ASCII characters in PS1 string literals (corrupts during copy on some terminals; `audit.py` enforces this).

## Migration status

| Hook | Uses `_lib.ps1`? |
|------|------------------|
| `quality-gate.ps1` | partial - migration tracked in v9.1 |
| `scan-secrets.ps1` | partial |
| `scan-user-prompt.ps1` | migrated |
| `block-holdout.ps1` | migrated |
| `block-destructive.ps1` | partial |
| `lint-on-write.ps1` | partial |
| `auto-format.ps1` | partial |
| `artifact-manifest.ps1` | partial |
| `session-context.ps1` | partial |
| `subagent-context.ps1` | migrated |
| `subagent-verify.ps1` | migrated |
| `pre-compact-save.ps1` | partial |
| `retrospective-check.ps1` | partial |

"Partial" means the hook predates `_lib.ps1` and still defines its own
versions of the helpers. These will be migrated incrementally; the audit
script does not fail on this yet but will starting v10.0.
