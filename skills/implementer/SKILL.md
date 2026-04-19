---
name: implementer
description: "Specialized in high-quality implementation, test-driven development, and clean code practices. Use when writing features, fixing bugs, implementing architectural specifications, refactoring code, or ensuring code quality. DO NOT USE FOR: system design or specs (use architect), code review (use guardian), exploring requirements (use brainstorming), debugging unknown errors (use systematic-debugging), or deployment automation (use ops)."
argument-hint: "[feature or code to implement]"
license: MIT
compatibility: "VS Code, Claude Code"
metadata:
  version: "7.0"
  updated: "2026-04-12"
  dependencies: ["architect", "guardian", "verification-before-completion"]
---

# Implementer Skill - High-Integrity Development

> Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani | Deps: architect, guardian, verification-before-completion

## Dependencies

Load the following via `read_file` before using this skill. Skills marked ★ have `disable-model-invocation: true` and cannot self-invoke - they **must** be loaded explicitly.

- `skills/architect/SKILL.md` - spec authoring and module design patterns; required to understand what you are implementing
- `skills/guardian/SKILL.md` - quality gate definitions; sets the acceptance bar your implementation must meet
- `skills/verification-before-completion/SKILL.md` ★ - completion gate; must be loaded before entering the VERIFY phase

## Overview

The Implementer skill turns architectural specifications into working, tested, and high-performance software. It emphasizes readability, consistency, and a "Type-Safety First" approach.

## Core Principles

1. **Readability First**: Optimize code for the reader, not the writer.
2. **Consistency**: Adhere strictly to existing project patterns and coding standards.
3. **Simplicity**: Straightforward solutions over clever ones. Refactor complexity into focused functions.
4. **Fail Fast & Explicitly**: Validate boundaries and use custom exceptions.
5. **Test-Driven Reliability**: Write tests alongside implementation. Target 80%+ coverage.
6. **Type Safety**: Use complete type annotations (Python 3.11+) for documentation and bug prevention.

## Coding Standards (Python)

- **Imports**: Grouped by Future, StdLib, Third-Party, and Local.
- **Naming**: `Upper_Case` for constants, `CapWords` for classes, `snake_case` for functions/variables.
- **Paths**: Use `pathlib.Path` exclusively.
- **Strings**: Use f-strings for formatting (except logging).
- **Docstrings**: Google Style required for all public APIs.
- **Exceptions**: Define custom hierarchies (e.g., `ApplicationError` -> `ValidationError`).

## Mini-Contract (Lightweight Pre-Flight)

For tasks too small for a full `SPEC.md` (bug fixes, small features, refactors), write a 2-4 bullet contract before coding:

- **Inputs/Outputs**: what data goes in, what comes out
- **Data shapes**: key types, schemas, or models involved
- **Error modes**: what can fail, how it should fail
- **Success criteria**: how to verify it works

This replaces "Read Spec" for small tasks. For anything with architectural implications, still require a full `SPEC.md`.

## Workflow

1. **Read Spec / Write Mini-Contract**: Full spec for features, mini-contract for fixes and small tasks. If a sprint contract exists at `.copilot/specs/CONTRACT-<feature>.md`, read it and use its acceptance criteria as your implementation targets (the contract supersedes your own interpretation of the spec).
2. **Setup Tests**: Write unit tests for expected behavior before implementation. Use the sprint contract's acceptance criteria and error scenarios to derive test cases.
3. **Draft Code**: Implement business logic according to architecture boundaries.
4. **Validate**: Run lints, type checks, and tests.
5. **Self-Review** (before handoff): Re-read every changed file as a reviewer would. Check against the original spec/mini-contract. Fix issues in-place before requesting external review. See checklist below.
6. **Refactor**: Simplify and clean up code while maintaining test passes.

### Self-Review Checklist (Step 5)

Before declaring work done or handing off to Guardian:

1. **Re-read changed files** - scan the actual diff, not just tool output
2. **Intent check** - does the change solve the problem stated in the spec/mini-contract, not a different problem?
3. **Debris sweep** - remove dead imports, commented-out code, debug prints, unresolved TODOs
4. **Readability gut-check** - would a new team member understand this without asking the author?
5. **Fix in-place** - if any issue is found, fix it now (don't log it for later)

This is a semantic review ("did I do the right thing well?"), not a mechanical gate ("did the linter pass?"). It complements, not replaces, the verification-before-completion skill.

## Enforce Invariants, Not Implementations

- Define **what** constraints must hold (e.g., "validate inputs at the boundary", "structured logging on every endpoint"), not **how** to implement them.
- Within enforced guardrails, allow freedom in implementation approach.
- Prefer declarative rules (type annotations, schema validators, linter configs) over procedural instructions.
- When invariants are violated, the error message should explain the constraint and how to satisfy it (agent-legible errors).

## Struggle-as-Signal Protocol

- If you repeatedly fail at a pattern or the same kind of task keeps requiring rework, treat it as a **missing capability signal**, not a reason to "try harder."
- Ask: "What knowledge, abstraction, or tool is missing that would make this trivial?"
- Surface the gap: recommend a new skill, a project convention doc update, or a shared utility that encodes the missing pattern.
- Encode the fix into the repo (skill file, shared module, linter rule) so future runs succeed without the same struggle.

## Feature Progress Tracker Updates

When `.copilot/state/FEATURE_PROGRESS.json` exists, update it as you work:

1. **Before starting a task**: Set the matching task's `status` to `"in-progress"` and `started` to today's date. Update `summary` counts and `updated` date.
2. **After completing a task**: Set `status` to `"completed"` and `completed` to today's date. Update `summary` counts and `updated` date.
3. **If blocked**: Set `status` to `"blocked"` and add the reason to `notes`.

**Rules**: Only modify `status`, `started`, `completed`, `notes`, `summary`, and `updated`. Never rewrite `title`, `id`, or `depends_on`.

**Skip signal**: If the file does not exist, skip silently. Do not create it (that is the planner's job).

## When to Use

- Implementing features from a design specification.
- Bug fixing and refactoring.
- Creating data access layers, service logic, or API handlers.

## Outputs & Deliverables

- **Primary Output**: Production-ready code with tests
- **Secondary Output**: Updated test suite and documentation
- **Success Criteria**: All tests pass, code passes linting and type checking
- **Quality Gate**: Code passes guardian review before merge

## Subagent Status Contract

When this skill is invoked as a subagent (dispatched by an orchestrator), return exactly one of these statuses at the end of your response:

| Status               | When to Use                                                                                                                                 |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `DONE`               | Task complete, all tests pass, ready for review                                                                                             |
| `DONE_WITH_CONCERNS` | Complete but you flagged issues (technical debt, risky change, ambiguous spec section) - list each concern                                  |
| `NEEDS_CONTEXT`      | Cannot complete without additional information - specify exactly what is missing                                                            |
| `BLOCKED`            | Architectural conflict, missing capability, or the spec requires changes to components outside the task scope - do not attempt a workaround |

**Rules:**

- Never return `DONE` if any test is failing.
- Never return `DONE` if a spec requirement was skipped or deferred.
- `BLOCKED` is not a failure - it is the correct response when proceeding would require unauthorized architectural decisions. Escalate clearly.
- `NEEDS_CONTEXT` must name the exact missing information (file path, schema, decision). "Needs more information" is not a valid needs-context response.

## Standards & Best Practices

### Code Quality Standards

- **Readability First**: Optimize code for human readers, not machines
- **Type Safety**: Use complete type annotations (Python 3.11+)
- **Fail Fast**: Validate inputs and fail explicitly with custom exceptions
- **Test-Driven**: Write tests before implementation, target 80%+ coverage

### Python Standards

- **Imports**: Group by Standard Library, Third-party, Local with blank lines
- **Naming**: `snake_case` for functions/variables, `PascalCase` for classes
- **Docstrings**: Google-style for all public APIs
- **Error Handling**: Custom exception hierarchies with meaningful messages

## Definition of Done

### Procedural Checks (Mechanism)

- [ ] All tests pass (unit + integration where applicable)
- [ ] Type hints present on all public interfaces
- [ ] Linter and type checker report zero errors
- [ ] Code follows existing project patterns and naming conventions
- [ ] No deviations from `SPEC.md` without architect approval

### Intent Checks (Outcome)

- [ ] A user performing the core workflow succeeds without unexpected errors
- [ ] Edge cases a real user would encounter are handled, not just happy-path cases
- [ ] The change does not break any existing user workflow (not just existing tests)
- [ ] A new team member can read the code and understand its purpose without asking the author

## Constraints

- **NO architectural changes.** Follow the `architect`'s spec strictly.
- **NO deployment management.**
- **NO code without tests.**

## Common Pitfalls

- **Skipping Tests**: "I'll test it manually" leads to regressions. Write tests first, always.
- **Ignoring Type Hints**: Skipping annotations makes code fragile and self-documenting. Type safety prevents 40% of bugs.
- **Over-Clever Code**: Smart code is hard to maintain. Choose readability over cleverness every time.
- **Deviating from Spec**: "Just a small change" breaks the contract. If the spec is wrong, escalate to `architect`, don't improvise.
- **Not Handling Errors**: Silent failures or generic exceptions hide problems. Fail fast with specific, descriptive errors.
- **Mixing Concerns**: Business logic in controllers or data access in services. Respect module boundaries.
- **No Regression Tests**: Fixing one bug while introducing another. Red-Green testing prevents this.

## Integration Points

| Phase         | Input From             | Output To                        | Context                                   |
| ------------- | ---------------------- | -------------------------------- | ----------------------------------------- |
| Design        | `architect`            | Implementation                   | Receive approved `SPEC.md`                |
| Testing       | Test requirements      | Local verification               | Run all tests before commit               |
| Review        | Code ready             | `guardian`                       | Request quality/security review           |
| Documentation | Implementation details | `ops`                            | API docs, deployment instructions         |
| Verification  | Completion claims      | `verification-before-completion` | Confirm all tests pass, type checks clean |

## References

Load these when implementing to calibrate style, structure, and conventions:

- [authentication-service.py](./references/authentication-service.py) - Sample service implementation. Load when writing new service classes, repositories, or handlers to match established patterns.
- [product_model.md](./references/product_model.md) - Reference domain model with field types, validation rules, and relationships. Load when designing or implementing data models.
