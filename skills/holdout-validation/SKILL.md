---
name: holdout-validation
description: "Structural separation of test authorship from code authorship. Produces behavioral acceptance scenarios that implementation agents cannot see, evaluated independently by Guardian. Use when designing acceptance criteria, validating implementations against intent, or enforcing holdout-set discipline. DO NOT USE FOR: unit test writing (use guardian), implementation (use implementer), verifying task completion (use verification-before-completion), or general test strategy."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code, Claude Code"
metadata:
  version: "7.0"
  updated: "2026-04-12"
  dependencies: ["architect", "guardian", "verification-before-completion"]
---

# Holdout Validation Skill - Structural Test Separation

> Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani | Deps: architect, guardian, verification-before-completion

## Dependencies

Load the following via `read_file` before using this skill. Skills marked ★ have `disable-model-invocation: true` and cannot self-invoke - they **must** be loaded explicitly.

- `skills/architect/SKILL.md` - spec and holdout scenario authoring patterns (required for the Architect role in this workflow)
- `skills/guardian/SKILL.md` - holdout evaluation is a Guardian-owned phase; QA patterns apply
- `skills/verification-before-completion/SKILL.md` ★ - completion gate; confirm all holdout scenarios are evaluated before declaring review complete

## When to Load This Skill

Load this skill when:

- Architect is producing a specification and needs to write holdout acceptance scenarios
- Guardian is reviewing an implementation that has associated holdout files in `.copilot/holdout/`
- Validating that structural blindness between implementation and evaluation is maintained
- Setting up a new project's holdout directory structure

## Overview

When the entity writing the code can also read the tests, the separation between implementation and validation is no longer optional. This skill enforces **holdout-set discipline**: behavioral acceptance scenarios are authored during design, stored separately from the codebase, and evaluated by a structurally independent reviewer (Guardian).

This addresses the documented pattern where reasoning models engage in test gaming - hardcoding return values, rewriting tests to match buggy code, and optimizing for "tests pass" rather than "software works."

## Core Principle

**A model that can see the answer key will use it. Design the system so it cannot.**

## Agent Access Rules

These rules are **structural constraints**, not behavioral suggestions. Reasoning models will use available information regardless of instructions.

| Agent Role                                                                     | Access     | Rationale                                                                                                               |
| ------------------------------------------------------------------------------ | ---------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Architect**                                                                  | WRITE only | Authors holdout scenarios during specification. Spec references the holdout file but does NOT include scenarios inline. |
| **Implementation agents** (`senior-developer`, `data-engineer`, `ai-engineer`) | **NONE**   | MUST NOT read files in `.copilot/holdout/`. If requested, deny access.                                                  |
| **Guardian**                                                                   | READ only  | Loads holdout scenarios during review and evaluates implementation against them.                                        |
| **Context-engineer**                                                           | READ only  | Tracks holdout pass rates in retrospective documents.                                                                   |

**When holdouts don't exist**: Implementation agents proceed normally with spec-based testing. Guardian notes "No holdout scenarios found" in the review and recommends Architect provide them for future iterations.

## Holdout Scenario Structure

### What Is a Holdout Scenario?

A holdout scenario is an **intent-level validation statement**, not a unit test. It describes what must be true from the perspective of a real user, not what a function should return.

| Unit Test (Instruction)              | Holdout Scenario (Intent)                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `assert calculate_tax(100) == 7.5`   | A customer in Ontario adding a $100 item to cart sees $107.50 at checkout                            |
| `assert response.status_code == 200` | A logged-in user requesting their profile receives their data within 2 seconds                       |
| `assert len(results) > 0`            | A compliance officer searching for "GDPR violations" finds all flagged records from the last 90 days |

### Scenario Format

```markdown
## Holdout Scenario: [ID]

**Actor:** [Who is performing the action]
**Intent:** [What they are trying to accomplish]
**Preconditions:** [What must be true before the scenario starts]
**Action:** [What the actor does]
**Success Criteria:**

- [Observable outcome 1]
- [Observable outcome 2]
  **Failure Modes:**
- [What should NOT happen]
  **Priority:** [Critical | High | Medium]
```

## Workflow

### During Design (Architect Produces)

1. After completing the specification, the Architect writes 3-10 holdout scenarios per feature
2. Scenarios focus on **user-observable outcomes**, not implementation details
3. Scenarios are written to `.copilot/holdout/` (or a user-specified directory)
4. Each scenario file is named `HOLDOUT.md`
5. The spec references the holdout file but does NOT include the scenarios inline

### During Implementation (Developer Is Blind)

1. Implementation agents receive the spec but **never** receive the holdout scenarios
2. Implementation agents write their own unit and integration tests based on the spec
3. The structural separation ensures tests written by developers validate the spec, not the holdouts
4. If an implementation agent requests access to holdout files, the request is denied

### During Review (Guardian Evaluates)

1. Guardian loads the holdout scenarios from `.copilot/holdout/`
2. For each scenario, Guardian evaluates whether the implementation satisfies the intent
3. Guardian produces a **Holdout Evaluation Report** as part of its review
4. Holdout failures are rated as High severity (they indicate spec-to-intent gaps)

### Holdout Evaluation Report Format

```markdown
### Holdout Evaluation

| ID    | Actor    | Intent                            | Status | Evidence                                    |
| ----- | -------- | --------------------------------- | ------ | ------------------------------------------- |
| H-001 | Customer | Add item to cart with correct tax | PASS   | Tax calculation verified in checkout flow   |
| H-002 | Admin    | Export audit log for compliance   | FAIL   | Export function exists but omits timestamps |

**Holdout Pass Rate:** X/Y scenarios passed
**Findings:** [Specific gaps between implementation and user intent]
```

## File Layout

```text
.copilot/holdout/
  HOLDOUT-<feature-1>.md    -- Scenarios for feature 1
  HOLDOUT-<feature-2>.md    -- Scenarios for feature 2
  README.md                 -- Explains holdout directory purpose and access rules
```

The holdout `README.md` should contain:

```markdown
# Holdout Validation Scenarios

**Access Rule:** Implementation agents (senior-developer, data-engineer, ai-engineer)
MUST NOT read files in this directory. These scenarios are exclusively for
Guardian evaluation during review.

**Authored by:** Architect agent during specification phase.
**Evaluated by:** Guardian agent during review phase.
```

## When to Use

- Architect is producing a specification for a non-trivial feature
- Guardian is reviewing an implementation that has an associated spec
- Any time the same agent (or agent pipeline) is writing both code and tests
- When validating that software works for real users, not just for the test suite

## Definition of Done

- [ ] Holdout scenarios written for every feature with a specification
- [ ] Scenarios stored in `.copilot/holdout/`, not in the main codebase
- [ ] Implementation agents confirmed to have no access to holdout files
- [ ] Guardian evaluation report produced with pass/fail per scenario
- [ ] Holdout failures tracked as High severity findings

## Constraints

- Does NOT replace unit or integration tests (those are still written by implementation agents)
- Does NOT contain implementation details or code snippets
- Does NOT get loaded by implementation agents (structural blindness is the mechanism)
- Does NOT override Guardian's existing review process (it extends it)

## Common Pitfalls

- **Writing unit tests as holdouts**: Holdouts are intent-level, not instruction-level. "Function returns 200" is a unit test. "User can log in and see their dashboard" is a holdout.
- **Leaking holdouts into specs**: The spec should reference that holdouts exist, but never include them inline. If the developer can read the spec and infer the holdouts, the separation is weakened.
- **Skipping holdouts for "simple" features**: Simple features still have user intent. Even a config change has a holdout: "The system behaves differently after this config is changed."
- **Guardian skipping holdout evaluation**: If holdout files exist in `.copilot/holdout/`, Guardian MUST evaluate them. Skipping is a review gap.

## Integration Points

| Phase          | Input From                     | Output To                                            | Context                                            |
| -------------- | ------------------------------ | ---------------------------------------------------- | -------------------------------------------------- |
| Design         | `architect`                    | Holdout scenario files                               | Architect writes scenarios after spec              |
| Implementation | Spec (no holdouts)             | `senior-developer` / `data-engineer` / `ai-engineer` | Developers work from spec only                     |
| Review         | Holdout files + implementation | `guardian`                                           | Guardian evaluates implementation against holdouts |
| Tracking       | Holdout evaluation report      | `context-engineer`                                   | Track holdout pass rates over time                 |

## References

- [Example Holdout Scenario](./references/example-holdout-scenario.md) - Complete worked example showing 3 holdout scenarios for a user authentication feature
