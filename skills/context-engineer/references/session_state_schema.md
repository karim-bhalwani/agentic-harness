# Session State Schema

> **Purpose:** Define the format for `.copilot/state/SESSION_STATE.md` which enables agents to resume interrupted work across sessions. Acts as a checkpoint file that any agent can read on startup.

---

## File Location

```text
.copilot/state/SESSION_STATE.md
```

## Canonical Frontmatter (machine contract)

The first block of the file MUST be a YAML frontmatter delimited by `---`
fences. This is the machine-readable contract validated by
`verify_session_state.py` and `tests/contracts/schemas/session_state.schema.json`.
The markdown body below remains for humans.

```yaml
---
session_state_schema_version: 1   # integer; must be in SUPPORTED_SCHEMA_VERSIONS
status: active                     # active | paused | completed | blocked
agent: senior-developer            # name of the agent that last wrote the file
spec_path: ".copilot/specs/SPEC.md"   # optional
active_story: "US-04"                  # optional
---
```

`scaffold_session_state.py` emits this block automatically. A file without a
valid frontmatter block FAILS verification.

## Schema

```markdown
# Session State

> **Last Updated:** [ISO 8601 timestamp]
> **Last Agent:** [agent name that last wrote this file]
> **Status:** [active | paused | completed | blocked]

## Pipeline Position

- **Current Phase:** [Discovery | Design | Build | Review | Ship]
- **Current Agent:** [agent name or "none"]
- **Pending Handoff:** [target agent | "none"]

## Active Task

- **Description:** [one-line summary of what is being worked on]
- **Spec Reference:** [path to spec.md if one exists, or "none"]
- **Branch:** [git branch name if applicable]

## Completed Steps

[Numbered list of completed pipeline steps with timestamps]

1. [YYYY-MM-DD HH:MM] [agent]: [what was completed]
2. [YYYY-MM-DD HH:MM] [agent]: [what was completed]

## Pending Steps

[Numbered list of remaining work]

1. [agent]: [what needs to happen next]
2. [agent]: [subsequent step]

## Blockers

[List any blockers preventing progress, or "None"]

- [blocker description + who can unblock it]

## Context Pointers

[Files the resuming agent should read first to regain context]

- [path/to/relevant/file]
- [path/to/another/file]

## Context Cache

> Check here before reading any file. Add an entry after reading to prevent redundant reads.
> Managed by `context_cache.py`. Format: `- [HASH]: path | L{start}-{end} | one-line summary`

-

## Decisions Made This Session

[Key decisions that affect downstream work]

- [decision]: [rationale, one sentence]

## Notes for Next Session

[Free-text notes from the last agent to whoever picks up next]

## Pipeline Loop

- **Iteration Count:** [integer, starts at 1 on first rework cycle, incremented by each agent in the loop]
- **Loop Agents:** [e.g., Release Manager → Senior Developer → Guardian]
- **Recurring Failures:** [list of findings/tests that have persisted across iterations]
```

---

## Rules

### Writing State

1. **Any agent** participating in a multi-phase pipeline **MUST** write `SESSION_STATE.md` at the end of its turn when work is incomplete or a handoff is pending. Writing state is mandatory, not optional.
2. **Overwrite, do not append.** The file always reflects current state, not history
3. **Completed Steps** is append-only within a session; overwritten across sessions
4. **Keep it short.** Target under 60 lines. This is a checkpoint, not a journal
5. **Context Pointers** are the most valuable section; accurate pointers save the resuming agent from re-exploring

### Reading State

1. **Check on startup.** Every agent should check for `.copilot/state/SESSION_STATE.md` before starting work
2. **If found and Status is "active" or "paused":** read it, summarize the state to the user, and ask whether to resume or start fresh
3. **If found and Status is "completed":** note it, do not prompt for resumption
4. **If not found:** proceed normally (no prior state)

### Lifecycle

```text
[Agent starts work] ──► [Writes SESSION_STATE.md at natural breakpoints]
       │
[Session ends / interrupted]
       │
[New session starts] ──► [Agent reads SESSION_STATE.md]
       │                         │
       │                 ┌───────┴────────┐
       │                 │                │
       ▼              Resume          Start Fresh
  [Continue from         │            [Archive old state,
   Pending Steps]        │             begin new work]
                         ▼
                  [Update SESSION_STATE.md
                   with resumed progress]
```

### Archival

When a pipeline run completes (all steps done):

1. Move `SESSION_STATE.md` to `.copilot/state/archive/[date]-[task-slug].md`
2. Create a clean `SESSION_STATE.md` with `Status: completed`
3. Archival is optional; deleting the file is also acceptable


