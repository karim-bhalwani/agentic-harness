---
name: context-engineer
description: "Initialize project infrastructure, generate context files, maintain project memory, and track decisions. Covers Project Bible generation, tiered context loading, bug-solution tracking, architectural decision records, and cross-session memory. Use when setting up projects, auditing environments, generating context documentation, maintaining project memory, or tracking decisions. DO NOT USE FOR: system architecture design (use architect), wiki knowledge persistence (use llm-mem), implementation tasks (use implementer), or debugging errors (use systematic-debugging)."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: []
---

# Context Engineer Skill - Project Context & Memory

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani | Tiered: core (~150 lines) + on-demand references

Unified reference for project initialization, context management, and persistent memory.

## Project Bible Structure

```text
.copilot/context/
  PROJECT_CONTEXT.md   -- Tier 1: always loaded (< 200 lines)
  ORIENTATION.md       -- Tier 1: 5-minute quick-start summary
  ARCHITECTURE.md      -- Tier 2: loaded by task match
  CODEBASE_PATTERNS.md -- Tier 2: loaded by task match
  AGENT_GUIDE.md       -- Tier 2: loaded by task match
  DECISIONS.md         -- Tier 3: loaded on reference

.copilot/state/
  SESSION_STATE.md     -- Pipeline checkpoint for cross-session resume

.copilot/specs/
  SPEC.md              -- Written by Architect; consumed by Developer and Guardian

.copilot/holdout/     -- Written by Architect; read only by Guardian

.copilot/artifacts/
  review-report.md     -- Written by Guardian; consumed by Release Manager
```

### Artifact Directory Convention

| Path                                    | Producer  | Consumer(s)         | Overwrite Policy               |
| --------------------------------------- | --------- | ------------------- | ------------------------------ |
| `.copilot/specs/SPEC.md`                | Architect | Developer, Guardian | Overwritten per spec cycle     |
| `.copilot/specs/SPEC-<feature-name>.md` | Architect | Developer, Guardian | Parallel workstream convention |
| `.copilot/holdout/`                     | Architect | Guardian            | Per Architect convention       |
| `.copilot/artifacts/review-report.md`   | Guardian  | Release Manager     | Overwritten per review         |

Producers create directories if needed. Files always reflect "latest" (no versioning).

### Tiered Loading

- **Tier 1** (< 200 lines): Identity, tech stack, critical rules. Loaded at session start.
- **Tier 2**: Architecture, patterns, agent guide. Loaded when task matches domain.
- **Tier 3**: Decision log, historical context. Loaded only when referenced.

## Smart Project Initialization

### Scan Phase

1. Detect frameworks: `pyproject.toml`, `package.json`, `requirements.txt`, `Cargo.toml`
2. Detect test runners: pytest, jest, go test
3. Detect CI: `.github/workflows/`, `Jenkinsfile`, `azure-pipelines.yml`
4. Detect infrastructure: `Dockerfile`, `docker-compose.yml`, `terraform/`, `bicep/`

### Draft Phase

- Generate Tier 1 context from scan results
- Mark items as `[CONFIRMED]`, `[INFERRED]`, or `[UNKNOWN]`

### Validate Phase

- Cross-reference context with actual code
- Verify build/test commands actually work
- Flag stale or contradictory information

## Session State Management

Agents persist pipeline progress to `.copilot/state/SESSION_STATE.md` for cross-session resume.

1. **On startup**: check for `SESSION_STATE.md`; if `active`/`paused`, summarize and ask to resume
2. **At breakpoints**: write/update the state file
3. **On completion**: mark status `completed`

Load [session_state_schema.md](./references/session_state_schema.md) for the full schema. Keep under 60 lines.

## Context Evolution Rules

### Update Protocol

1. Read existing context first (never overwrite blindly)
2. Mark changes with date and reason
3. Move deprecated decisions to `[SUPERSEDED]` with link to replacement

### Merge Rules

- `[CONFIRMED]` (code-verified) overrides `[DECLARED]` (user-stated)
- `[DECLARED]` overrides `[INFERRED]` (auto-detected)
- `[UNKNOWN]` items always surfaced to user

## Definition of Done

- [ ] Tier 1 `PROJECT_CONTEXT.md` exists and is under 200 lines
- [ ] All detected items marked `[CONFIRMED]`, `[INFERRED]`, or `[UNKNOWN]`
- [ ] Build and test commands verified (actually run, not assumed)
- [ ] No `[UNKNOWN]` items remain without a documented reason
- [ ] Context files are consistent with actual codebase state

## Constraints

- Does NOT write application code or tests
- Does NOT override `[CONFIRMED]` context with `[DECLARED]` or `[INFERRED]`
- Does NOT generate speculative documentation (everything must have a source)

## Integration Points

- **brownfield-discovery**: Produces `[CONFIRMED]` findings for the Project Bible
- **greenfield-interview**: Produces `[DECLARED]` founding documents
- **architect**: Consumes the Project Bible as primary input
- **holdout-validation**: Evaluation reports feed into retrospective tracking
- **memory tool**: Cross-session facts stored via Copilot Memory

## Scripts

- [scripts/scaffold_bible.py](./scripts/scaffold_bible.py) - Create stub files for all 6 Project Bible documents. Run at the start of the documentation phase. Mode: `--mode greenfield` or `--mode brownfield`.
- [scripts/verify_bible.py](./scripts/verify_bible.py) - Verification gate for the Project Bible. Exits 1 if any of the 6 files is still a stub or missing.
- [scripts/scaffold_session_state.py](./scripts/scaffold_session_state.py) - Create `.copilot/state/SESSION_STATE.md` from the schema template. Idempotent; does not overwrite existing files.
- [scripts/verify_session_state.py](./scripts/verify_session_state.py) - Verify `SESSION_STATE.md` exists and contains all required schema sections and a valid `Status:` value.

## References

Load on demand for specific sub-tasks:

- [templates-and-retrospectives.md](./references/templates-and-retrospectives.md) - Memory system templates (bug log, ADR, key facts, work history), retrospective workflow, rework tracking, workflow effectiveness audit, environment auditing, 5-minute orientation details. **Load for retrospectives or project memory work.**
- [context_snippet.md](./references/context_snippet.md) - Context snippet template for consistent format and tiered citations.
- [orientation_template.md](./references/orientation_template.md) - 5-Minute Orientation template.
- [session_state_schema.md](./references/session_state_schema.md) - Session State schema for cross-session resume.
- [entropy_audit.md](./references/entropy_audit.md) - Entropy Audit checklist for quarterly audits.
- [pipeline-loop.md](./references/pipeline-loop.md) - Cross-session iteration tracking and 3-strike circuit breaker for the Release Manager / Senior Developer / Guardian review cycle.
