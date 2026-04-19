---
agent: architect
description: Kick off the full design spec for a feature or system using the Architect agent. Produces a spec.md covering module boundaries, API contracts, data models, error handling, security, and acceptance scenarios. Use when the change is architectural - new modules, API surface changes, cross-cutting concerns, or anything too complex for /feature-plan.
argument-hint: "[feature or system to design]"
tools:
  - read
  - search
version: "7.0"
updated: "2026-04-12"
---

Design: **${input:feature}**

**Before starting**, read:

- `.copilot/context/PROJECT_CONTEXT.md` (Project Bible - required; if not found, ask the user to run `brownfield-discovery` or `greenfield-interview` first)
- Any existing specs in `.copilot/specs/`

**Scope mode** - identify the one that applies and confirm with the user if unsure:

- **REDUCTION** - simplifying or removing existing functionality
- **HOLD** - new feature within existing architecture (no new modules, no new API surface)
- **EXPANSION** - new module, new API contract, or cross-cutting change

Run the full Architect workflow per the `architect` skill. Produce the specification at `.copilot/specs/SPEC.md`.

Do NOT begin implementation. The spec must be reviewed and approved before any code is written.

