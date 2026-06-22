---
name: implementer
description: "PIPELINE POSITION: build (step 4 of 4: brainstorming → architect → concise-planning → implementer). Write features, fix bugs, refactor, and produce tests against an approved design or plan. Output is working, tested code. DO NOT USE FOR: deciding what to build (use brainstorming), designing system architecture or API contracts (use architect), generating the task checklist itself (use concise-planning), code review (use guardian), debugging unknown errors (use systematic-debugging), or deployment automation (use ops)."
argument-hint: "[feature or code to implement]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: ["architect", "guardian", "verification-before-completion"]
---

# Implementer Skill - High-Integrity Development

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani | Deps: architect, guardian, verification-before-completion

> **Pipeline position**: **build** (4 of 4) - `brainstorming` -> `architect` -> `concise-planning` -> **`implementer`**. This skill produces working, tested code. It runs LAST. Earlier steps may be compressed for localized changes affecting fewer than 10 lines and not impacting external APIs (use `/quick-fix`) but never skipped for non-trivial work.

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

- **Imports**: Grouped by Standard Library, Third-Party, and Local (add a Future group only when a `__future__` import is explicitly required).
- **Naming**: `UPPER_CASE` for constants, `CapWords` for classes, `snake_case` for functions/variables.
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

1. **Read Planning Artifacts (or Write Mini-Contract)**:

- **Use `SPEC.md`** for feature work and any task with architectural impact.
- **Use the mini-contract** (2-4 bullets above) for small fixes/refactors that do not require a full spec.
- **Use `.copilot/specs/CONTRACT-<feature>.md`** when present as the sprint planning artifact that translates the spec into implementable acceptance criteria.
- **Apply precedence rules**:
- If both `SPEC.md` and `CONTRACT-<feature>.md` exist, use `SPEC.md` for architecture/intent and `CONTRACT-<feature>.md` for sprint scope and acceptance criteria.
- If no sprint contract exists, implement directly from `SPEC.md` (or from the mini-contract for small tasks).

2. **Setup Tests**: Write unit tests for expected behavior before implementation. Use the sprint contract's acceptance criteria and error scenarios to derive test cases.

   #### TDD Discipline (Red-Green-Refactor)

   Work in **vertical slices** (tracer bullets): one test → minimal code to pass → repeat. Each cycle teaches what the next test should cover.

   > **Anti-pattern: horizontal slices**: Do NOT write all tests first, then all code. Tests written in bulk test _imagined_ behavior, not actual behavior. They become insensitive to real changes and break on refactors that don't change behavior.

   **Per-cycle checklist:**
   - [ ] Test describes behavior (WHAT), not implementation (HOW)
   - [ ] Test uses the public interface only (no mocking of internal collaborators)
   - [ ] Code is minimal to pass this test (no speculative features)
   - [ ] Tests pass before any refactoring (**never refactor while RED**)

3. **Pre-Write Gate (Simplicity Ladder)**: Before writing any code for a task, stop at the first rung that holds. Do not proceed past the rung that resolves the need:

   ```
   1. Does this need to exist at all?          → no: skip it (YAGNI)
   2. Does the stdlib already do this?         → use it
   3. Does a native platform feature cover it? → use it
   4. Does an already-installed dep solve it?  → use it
   5. Is this one line?                        → write one line
   6. Only then: write the minimum that works
   ```

   **Not negotiable** regardless of rung: input validation at trust boundaries, error handling that prevents data loss, security checks, accessibility, and anything the spec explicitly requires. The ladder reduces volume, never correctness.

   When you intentionally stop at an early rung and a known ceiling exists (e.g., O(n²) scan, global lock, naive heuristic), mark it with a `minion:` comment naming the ceiling and upgrade path:

   ```python
   # minion: linear scan sufficient for now; upgrade to binary search if list > 1000 items
   ```

4. **Draft Code**: Implement business logic according to architecture boundaries.
5. **Validate**: Run lints, type checks, and tests.
6. **Self-Review** (before handoff): Re-read every changed file as a reviewer would. Check against the original spec/mini-contract. Fix issues in-place before requesting external review. See checklist below.
7. **Refactor**: Simplify and clean up code while maintaining test passes.

### Self-Review Checklist (Step 5)

Before declaring work done or handing off to Guardian:

1. **Re-read changed files** - scan the actual diff, not just tool output
2. **Intent check** - does the change solve the problem stated in the spec/mini-contract, not a different problem?
3. **Debris sweep** - remove dead imports, commented-out code, debug prints, unresolved TODOs
4. **Readability gut-check** - would a new team member understand this without asking the author?
5. **Fix in-place** - if any issue is found, fix it now (don't log it for later)

This is a semantic review ("did I do the right thing well?"), not a mechanical gate ("did the linter pass?"). It complements, not replaces, the verification-before-completion skill.

## Failure Taxonomy

| Failure Mode              | Symptom                                                    | Immediate Recovery                                                                     |
| ------------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `stale_file_content`      | `replace_string_in_file` fails to match                    | Re-read the file first. Never retry an edit on content you read more than 2 steps ago. |
| `scope_overreach`         | Touching files not in the spec or task scope               | Revert. Edit only what the spec explicitly requires.                                   |
| `placeholder_code`        | Writing `# TODO`, `pass`, or `...` in production paths     | Replace before declaring done. No placeholders in deliverables.                        |
| `test_written_after_code` | Tests written after implementation (not TDD)               | Acceptable only for obvious bug fixes. For features, write RED test first.             |
| `convention_mismatch`     | New code uses different naming/style than surrounding code | Re-read 2-3 neighboring files. Match existing conventions exactly.                     |

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

**Skip signal**: If the file does not exist, skip silently. Do not create it (that is handled by the `architect` skill during planning/initialization).

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

When invoked as a subagent, return exactly one status (`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`) per the canonical protocol in `skills/subagent-execution/SKILL.md` Section Subagent Status Protocol.

**Implementer-specific rules:**

- Never return `DONE` if any test is failing.
- Never return `DONE` if a spec requirement was skipped or deferred.

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

> Note: These are optional reference examples. Some projects may not include them; if missing, treat them as templates and create equivalent project-specific references as needed.

- [authentication-service.md](./references/authentication-service.md) - Sample service implementation (if present). Load when writing new service classes, repositories, or handlers to match established patterns.
- [product_model.md](./references/product_model.md) - Reference domain model (if present) with field types, validation rules, and relationships. Load when designing or implementing data models.
