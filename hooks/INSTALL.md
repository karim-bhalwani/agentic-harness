# Mega Minions - Hook Harness: Install Guide

**Architect:** Karim Bhalwani
**Version:** 8.0 | **Updated:** 2026-05-03
**Platform:** Windows (PowerShell)

---

## What Are These Hooks?

This directory mirrors `~/.copilot/hooks/` - the user-global hook location that VS Code Copilot auto-discovers. Copying these files to your user directory means every workspace you open gets the same quality gates, safety guards, and context injection automatically.

For a comprehensive guide to what each hook does, lifecycle coverage, and configuration modes, see [README.md](README.md).

---

## Hooks Included

This package includes 11 hook scripts plus `hooks.json` configuration. See [README.md](README.md) for the complete hook inventory and what each one does.

## Installation

### Step 1: Create the hooks directory

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.copilot\hooks"
```

### Step 2: Copy all hook files

From the repo root, run:

```powershell
Copy-Item -Path "hooks\*" -Destination "$env:USERPROFILE\.copilot\hooks\" -Force
```

Or copy the files manually using Explorer to `C:\Users\<you>\.copilot\hooks\`.

### Step 3: Verify PowerShell execution policy

Hooks run as unsigned PowerShell scripts. Your execution policy must allow this.

```powershell
# Check current policy
Get-ExecutionPolicy -List

# Option A: Permanent fix (recommended - set for current user)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Option B: Temporary fix (current session only - useful for testing)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

`RemoteSigned` allows local scripts to run unsigned, which is required for hook scripts.

- **Use Option A** for a persistent solution that applies to all PowerShell sessions and VS Code instances
- **Use Option B** for a temporary test or if you need a session-specific override (resets when terminal closes)

> **Important: Unblock downloaded files.** If you cloned or downloaded the repo from GitHub, Windows marks the files with a "Zone.Identifier" (Mark of the Web). `RemoteSigned` blocks these even though they are local. Run this after copying hooks (and after every re-copy):
>
> ```powershell
> Get-ChildItem "$env:USERPROFILE\.copilot\hooks\*" | Unblock-File
> ```

### Step 4: Enable hooks in VS Code settings

Add these to your VS Code `settings.json` (`Ctrl+Shift+P` → "Open User Settings JSON"):

```json
{
  "chat.hookFilesLocations": {
    "~/.copilot/hooks": true
  }
}
```

> **Recommended.** VS Code discovers `~/.copilot/hooks` under "User" hook locations automatically. However, if you have customized `chat.hookFilesLocations`, custom values override the defaults, so you must include this path explicitly. Adding it is safe regardless.
> `chat.hooks.enabled` defaults to `true` - no need to set that separately.

### Step 5: Verify hooks are loaded

1. Open VS Code Copilot Chat
2. Type `/hooks` in chat, or
3. Open Command Palette (`Ctrl+Shift+P`) → "Chat: Configure Hooks"

You should see the 11 hooks listed (Stop x2, PreToolUse x3, PostToolUse x1, SessionStart x1, SubagentStart x1, PreCompact x1, UserPromptSubmit x1, SubagentStop x1).

---

## Hook Behaviour Reference

### quality-gate.ps1 (Stop)

Runs `ruff check .` and `mypy . --quiet` before the agent session can close. If either fails, the agent is blocked and told to fix the errors first.

**Env vars:**

| Variable            | Default | Effect                                    |
| ------------------- | ------- | ----------------------------------------- |
| `SKIP_QUALITY_GATE` | `false` | Set `true` to skip entirely               |
| `GUARD_MODE`        | `block` | Set `warn` to log errors without blocking |

holdout.ps1 (PreToolUse)

Denies file-read tool calls targeting `.copilot/holdout/` when the calling agent is a BUILD agent (senior-developer, data-engineer, ai-engineer). Converts the instruction-level holdout access boundary from the holdout-validation skill into a deterministic enforcement gate. Guardian, architect, holdout-validation, and other non-BUILD agents pass through. Unknown agent types also pass through (cannot enforce without identity).

**Intercepted tools:** `read_file`, `list_dir`, `grep_search`, `file_search`, `run_in_terminal`

**Env vars:**

| Variable             | Default | Effect                                                                         |
| -------------------- | ------- | ------------------------------------------------------------------------------ |
| `SKIP_HOLDOUT_GUARD` | `false` | Set `true` to bypass entirely (invalidates holdout evaluation for the session) |

### block-

### block-holdout.ps1 (PreToolUse)

Denies file-read tool calls targeting `.copilot/holdout/` when the calling agent is a BUILD agent (senior-developer, data-engineer, ai-engineer). Converts the instruction-level holdout access boundary from the holdout-validation skill into a deterministic enforcement gate. Guardian, architect, holdout-validation, and other non-BUILD agents pass through. Unknown agent types also pass through (cannot enforce without identity).

**Intercepted tools:** `read_file`, `list_dir`, `grep_search`, `file_search`, `run_in_terminal`

**Env vars:**

| Variable             | Default | Effect                                                                         |
| -------------------- | ------- | ------------------------------------------------------------------------------ |
| `SKIP_HOLDOUT_GUARD` | `false` | Set `true` to bypass entirely (invalidates holdout evaluation for the session) |

### block-destructive.ps1 (PreToolUse)

Intercepts every `run_in_terminal` call and blocks any command matching a dangerous pattern before it executes.

**Blocked patterns:** `rm -rf`, `Remove-Item -Recurse -Force`, `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`, `git push --force`, `git push -f`, `git reset --hard`, `Format-Volume`, `del /s /q`

**Env vars:**

| Variable                 | Default   | Effect                                                                           |
| ------------------------ | --------- | -------------------------------------------------------------------------------- |
| `SKIP_DESTRUCTIVE_GUARD` | `false`   | Set `true` to skip entirely                                                      |
| `TOOL_GUARD_ALLOWLIST`   | _(empty)_ | Comma-separated substrings to allow through (e.g. `my-safe-script,test-cleanup`) |

### auto-format.ps1 (PostToolUse)

After every file write by the agent, runs `ruff format` on `.py` files. Runs `npx prettier --write` on `.js/.ts/.json/.css/.md` files if npx is available.

**Env vars:**

| Variable           | Default | Effect                      |
| ------------------ | ------- | --------------------------- |
| `SKIP_AUTO_FORMAT` | `false` | Set `true` to skip entirely |

### session-context.ps1 (SessionStart)

At the start of every agent session, injects: git branch, last commit, Python version, project root, Project Bible status (`~/.copilot/context/PROJECT_CONTEXT.md` check), and active venv.

**No configurable env vars** - always runs unless VS Code hooks are disabled.

### scan-secrets.ps1 (Stop)

At session end, scans all files modified since last commit for 13 credential patterns (AWS, GCP, Azure, GitHub PATs, private keys, Stripe, Slack, npm tokens, JWTs, connection strings). Skips obvious placeholder values (example, dummy, changeme, etc.).

**Default mode is `warn`** - findings are logged but do not block the session.

**Env vars:**

| Variable            | Default | Effect                                                       |
| ------------------- | ------- | ------------------------------------------------------------ |
| `SKIP_SECRETS_SCAN` | `false` | Set `true` to skip entirely                                  |
| `SCAN_MODE`         | `warn`  | Set `block` to prevent agent finishing when secrets detected |

### lint-on-write.ps1 (PreToolUse)

Intercepts `create_file` and `replace_string_in_file` calls for `.py` files and runs `ruff check` on the proposed content before the write is allowed. If ruff finds errors, the write is denied and the agent is told exactly what to fix first.

For `replace_string_in_file`, reconstructs the full file by applying the proposed replacement to existing disk content, then lints the reconstructed result. This catches errors introduced by the partial change.

**Env vars:**

| Variable             | Default | Effect                                             |
| -------------------- | ------- | -------------------------------------------------- |
| `SKIP_LINT_ON_WRITE` | `false` | Set `true` to skip entirely                        |
| `LINT_MODE`          | `block` | Set `warn` to log errors without denying the write |

### pre-compact-save.ps1 (PreCompact)

Fires before VS Code compacts (truncates) the context window. Writes `.copilot/state/SESSION_STATE.md` in the project root with a structured checkpoint: current task, completed steps, pending steps, and context pointers. Merges with any existing state file to preserve history.

The agent sees a confirmation in chat via `systemMessage`. Never blocks compaction (always exits 0).

**Env vars:**

| Variable                | Default | Effect                                    |
| ----------------------- | ------- | ----------------------------------------- |
| `SKIP_PRE_COMPACT_SAVE` | `false` | Set `true` to disable state checkpointing |

### subagent-context.ps1 (SubagentStart)

Fires when a subagent is spawned. Subagents run in isolated context windows and do not inherit the SessionStart hook's context injection, so without this hook a subagent has no knowledge of the branch, Python version, venv status, or Project Bible location. This hook injects a compact version of the same environment facts.

Lightweight (~10ms, no external commands beyond `git` and `python --version`). Always exits 0.

**Env vars:**

| Variable                | Default | Effect                                           |
| ----------------------- | ------- | ------------------------------------------------ |
| `SKIP_SUBAGENT_CONTEXT` | `false` | Set `true` to disable subagent context injection |

### scan-user-prompt.ps1 (UserPromptSubmit)

Inspects every user-submitted prompt before the model sees it. Detects two classes of risk:

- **Prompt injection markers**: substrings like `ignore previous instructions`, `jailbreak`, `system prompt`, `disregard the above`.
- **Credential patterns**: AWS access keys, GitHub PATs, OpenAI keys, Slack tokens, JWTs, private key blocks.

In `warn` mode (default, registered in `hooks.json`) the hook injects a security notice via `additionalContext` so the model treats the flagged content as data, never instructions. In `block` mode the hook exits 2 to reject the prompt.

**Env vars:**

| Variable                | Default | Effect                                                                 |
| ----------------------- | ------- | ---------------------------------------------------------------------- |
| `SKIP_SCAN_USER_PROMPT` | `false` | Set `true` to disable scanning                                         |
| `PROMPT_SCAN_MODE`      | `warn`  | Set to `block` to reject suspicious prompts (high false-positive risk) |

### subagent-verify.ps1 (SubagentStop)

Runs after a subagent finishes. Looks at the subagent's `agent_type` and runs the relevant `verify_*.py` script(s) to confirm the subagent actually produced its expected artifact (spec, holdout, review report, session state). On verifier failure, returns `decision=block` so the orchestrating agent knows to retry rather than continuing with a missing artifact.

The hook is conservative: it only runs a verifier if the artifact directory already exists, avoiding false negatives when the subagent was not in a producing phase.

**Env vars:**

| Variable               | Default             | Effect                                                     |
| ---------------------- | ------------------- | ---------------------------------------------------------- |
| `SKIP_SUBAGENT_VERIFY` | `false`             | Set `true` to disable post-subagent verification           |
| `SUBAGENT_VERIFY_MODE` | `warn` (registered) | Set to `block` to enforce blocking on verification failure |

---

## Upgrading

When a new version of this hook harness is published, re-run Step 2 to overwrite existing files:

```powershell
Copy-Item -Path "hooks\*" -Destination "$env:USERPROFILE\.copilot\hooks\" -Force
```

---

## Troubleshooting

**Hook not executing:**

- Confirm files are in `%USERPROFILE%\.copilot\hooks\` (not a subfolder)
- Check Output panel → select "GitHub Copilot Chat Hooks" for errors
- Run `/hooks` in chat to inspect registered hooks

**Permission denied / script not running:**

- Verify execution policy: `Get-ExecutionPolicy -Scope CurrentUser` should return `RemoteSigned` or `Unrestricted`

**Quality gate blocks with no ruff/mypy installed:**

- This is safe to ignore - the hook skips checks for tools not installed
- Install dev tools: `uv add --dev ruff mypy`

**Infinite Stop hook loop:**

- Both Stop hooks check `stop_hook_active` and exit immediately if `true`
- If looping somehow occurs, set `SKIP_QUALITY_GATE=true` or `SKIP_SECRETS_SCAN=true` in your shell session to break the loop

**Secrets scanner false positives:**

- Add the substring to `TOOL_GUARD_ALLOWLIST` or set `SKIP_SECRETS_SCAN=true` temporarily
- Placeholder values matching patterns like `example`, `changeme`, `your_`, `fake` are automatically skipped

---

## Project-Level Override

If a specific project needs different hook behaviour, create `.github/hooks/hooks.json` in that workspace. Workspace-level hooks take precedence over user-level hooks for the same event.

Reference: [VS Code Agent Hooks documentation](https://code.visualstudio.com/docs/copilot/customization/hooks)
