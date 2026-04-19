---
agent: architect
description: Negotiate a sprint contract between the builder and Guardian before coding starts. The builder proposes testable acceptance criteria from the spec, and Guardian reviews them for completeness. Catches ambiguity early when fixing it is free. Use after /design produces a spec and before the builder starts implementation.
argument-hint: "[feature name or spec reference]"
tools:
  - read
  - search
version: "7.0"
updated: "2026-04-12"
---

Negotiate a sprint contract for: **${input:feature}**

**Before starting**, read:

- `.copilot/specs/SPEC.md` (or `.copilot/specs/SPEC-${input:feature}.md` if parallel workstreams)
- `.copilot/context/PROJECT_CONTEXT.md` (for project constraints and non-negotiables)

## Phase 1: Builder Proposes Contract

> **Note**: This is a design-time simulation, not actual building or reviewing. The Architect role-plays both perspectives to surface ambiguity before implementation begins. This does not violate Doer/Judge separation because no code is written or reviewed here.

Acting as the **builder**, extract from the spec:

1. **Deliverables**  -  List each concrete output (file, endpoint, module, migration) the builder will produce.
2. **Acceptance criteria**  -  For each deliverable, write 2-4 testable conditions using the format:
   - `GIVEN [precondition] WHEN [action] THEN [observable result]`
3. **Out of scope**  -  Explicitly list what this sprint will NOT touch (prevents scope creep during implementation).
4. **Error scenarios**  -  For each deliverable, list at least one failure mode and how the system should behave.
5. **Verification method**  -  For each criterion: unit test, integration test, manual check, or lint rule.

## Phase 2: Guardian Reviews Contract

Switch perspective to **Guardian** and review the proposed contract:

- [ ] **Coverage**: Does every spec requirement map to at least one acceptance criterion?
- [ ] **Testability**: Is every criterion objectively verifiable (no "should work well" or "handles errors appropriately")?
- [ ] **Completeness**: Are error paths and edge cases covered, not just happy paths?
- [ ] **Feasibility**: Can the verification methods actually be implemented with the project's test infrastructure?
- [ ] **Missing scenarios**: Are there spec requirements with no corresponding criterion?

For each gap found, propose a specific fix (add criterion, sharpen wording, add error scenario).

## Phase 3: Finalized Contract

Produce the agreed contract in this format:

```markdown
# Sprint Contract: ${input:feature}

**Date**: YYYY-MM-DD
**Spec**: [path to spec file]
**Builder**: [agent name]
**Reviewer**: Guardian

## Deliverables

| #   | Deliverable | Files   | Status      |
| --- | ----------- | ------- | ----------- |
| 1   | [name]      | [paths] | not-started |

## Acceptance Criteria

| #   | Deliverable | Criterion                | Verification | Status       |
| --- | ----------- | ------------------------ | ------------ | ------------ |
| 1   | [ref]       | GIVEN... WHEN... THEN... | unit test    | not-verified |

## Out of Scope

- [item 1]

## Error Scenarios

| #   | Scenario | Expected Behavior | Verification |
| --- | -------- | ----------------- | ------------ |
| 1   | [desc]   | [behavior]        | [method]     |
```

## After Contract Is Agreed

- Save to `.copilot/specs/CONTRACT-${input:feature}.md` (alongside the spec).
- The builder references the contract during implementation (not just the spec).
- Guardian references the contract during review (acceptance criteria become the scope audit checklist).
- After implementation, update each criterion's `Status` to `verified` or `failed`.

