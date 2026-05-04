# Hook Harness

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani

Lifecycle hooks that automate, enforce, and extend the Mega Minions agent pipeline. Hooks are PowerShell scripts that fire at specific points in an agent session (before tools run, after files are written, when the session ends). They run **outside the model**, so they cannot be skipped by prompt manipulation.

For installation, see [INSTALL.md](INSTALL.md).

---

## Hook Inventory

| Script | Event | Mode | Purpose | Bypass env var |
|---|---|---|---|---|
| [block-destructive.ps1](block-destructive.ps1) | `PreToolUse` | block | Reject `rm -rf`, `DROP TABLE`, `git push --force`, etc. before they run | `SKIP_DESTRUCTIVE_GUARD` |
| [lint-on-write.ps1](lint-on-write.ps1) | `PreToolUse` | block | Deny Python file writes that fail `ruff check` | `SKIP_LINT_ON_WRITE` |
| [auto-format.ps1](auto-format.ps1) | `PostToolUse` | non-blocking | Run `ruff format` / `prettier` on every file the agent writes | `SKIP_AUTO_FORMAT` |
| [session-context.ps1](session-context.ps1) | `SessionStart` | inject only | Inject branch, Python version, Project Bible status, pipeline phase | `SKIP_SESSION_CONTEXT` |
| [subagent-context.ps1](subagent-context.ps1) | `SubagentStart` | inject only | Inject the same context into subagents (they don't inherit `SessionStart`) | `SKIP_SUBAGENT_CONTEXT` |
| [scan-user-prompt.ps1](scan-user-prompt.ps1) | `UserPromptSubmit` | warn (default) | Detect prompt-injection markers and credential patterns in pasted user input | `SKIP_SCAN_USER_PROMPT` |
| [pre-compact-save.ps1](pre-compact-save.ps1) | `PreCompact` | non-blocking | Checkpoint `.copilot/state/SESSION_STATE.md` before context compaction | `SKIP_PRE_COMPACT_SAVE` |
| [quality-gate.ps1](quality-gate.ps1) | `Stop` | block | Run `ruff check` + `ty check` (skipped if no `.py` modified in session) | `SKIP_QUALITY_GATE` |
| [scan-secrets.ps1](scan-secrets.ps1) | `Stop` | warn (default) | Scan modified files for leaked credentials | `SKIP_SECRETS_SCAN` |
| [subagent-verify.ps1](subagent-verify.ps1) | `SubagentStop` | block (default) | Run the relevant `verify_*.py` for each subagent's expected artifact | `SKIP_SUBAGENT_VERIFY` |

Total: 10 hook scripts across 8 lifecycle events. All are registered in [hooks.json](hooks.json).

---

## Lifecycle Coverage

```text
SessionStart  → session-context.ps1
              ↓
UserPromptSubmit → scan-user-prompt.ps1 (warn)
              ↓
PreToolUse    → block-destructive.ps1
              → lint-on-write.ps1
              ↓
[tool runs]
              ↓
PostToolUse   → auto-format.ps1
              ↓
SubagentStart → subagent-context.ps1   (subagent isolated context)
SubagentStop  → subagent-verify.ps1
              ↓
PreCompact    → pre-compact-save.ps1
              ↓
Stop          → quality-gate.ps1
              → scan-secrets.ps1
```

---

## Modes

Most enforcing hooks have a `*_MODE` env var with `block` and `warn` values:

| Hook | Mode env var | Default |
|---|---|---|
| `quality-gate.ps1` | `GUARD_MODE` | `block` |
| `scan-secrets.ps1` | `SCAN_MODE` | `warn` (registered in `hooks.json`) |
| `scan-user-prompt.ps1` | `PROMPT_SCAN_MODE` | `warn` (registered in `hooks.json`) |
| `subagent-verify.ps1` | `SUBAGENT_VERIFY_MODE` | `warn` (registered in `hooks.json`) |

Use `block` once you trust the heuristics. Use `warn` while iterating.

---

## Conventions

Every hook script in this directory:

1. Reads JSON event payload from stdin via `[Console]::In.ReadToEnd()`.
2. Has a `SKIP_<NAME>` circuit-breaker env var (enforced by `audit.py --lint`).
3. Exits **0 on every code path** when emitting JSON (VS Code requires exit 0 to parse `permissionDecision` / `decision` fields). Use exit 2 only for hard `UserPromptSubmit` rejections.
4. Never crashes the agent harness on internal errors (try/catch around stdin parse, fall back to exit 0).
5. Preserves `stop_hook_active` re-entry guards on `Stop` hooks to prevent infinite loops.

