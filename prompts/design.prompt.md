---
agent: architect
description: Kick off the full design spec for a feature or system using the Architect agent. Produces a spec.md covering module boundaries, API contracts, data models, error handling, security, and acceptance scenarios. Use when the change is architectural - new modules, API surface changes, cross-cutting concerns, or anything too complex for /feature-plan.
argument-hint: "[feature or system to design]"
tools:
  - read
  - search
  - edit
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

## Intent Contract

When this prompt completes, these conditions must be true:

- A `SPEC.md` exists with all 13 required sections populated
- Two independent teams could implement both sides of any module boundary and integrate on the first attempt
- Every design decision includes a rationale and the alternatives that were considered

Design: **${input:feature}**

## Step 1: Gather Context

Read the following files:

- `.copilot/context/PROJECT_CONTEXT.md` (Project Bible - required; if not found, ask the user to run `brownfield-discovery` or `greenfield-interview` first)
- Any existing specs in `.copilot/specs/`

## Step 2: Determine Scope Mode

Identify which scope mode applies:

- **REDUCTION** - simplifying or removing existing functionality
- **HOLD** - new feature within existing architecture (no new modules, no new API surface)
- **EXPANSION** - new module, new API contract, or cross-cutting change

If the appropriate scope mode cannot be determined confidently, ask the user to confirm by providing additional context.

## Step 3: Run Architect Workflow

Produce a comprehensive specification covering:

- Module boundaries
- API contracts
- Data models
- Error handling
- Security
- Acceptance scenarios

## Step 4: Produce and Review

Write the specification to `.copilot/specs/SPEC.md`. If a SPEC.md already exists, ask the user whether to overwrite or archive it to `.copilot/specs/archive/SPEC-<date>.md` first. If file writing is not available, output the full specification as a fenced Markdown code block in the chat for the user to save manually.

**Do NOT begin implementation.** The spec must be reviewed and approved before any code is written.
