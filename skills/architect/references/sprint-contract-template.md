# Sprint Contract Template

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Used by [`/sprint-contract`](../../../prompts/sprint-contract.prompt.md). The contract is a design-time simulation of the builder/Guardian negotiation that catches ambiguity before code is written. No code or review is produced here.

## Phase 1: Builder Proposes Contract

Acting as the **builder**, extract from the spec:

1. **Deliverables** - List each concrete output (file, endpoint, module, migration) the builder will produce.
2. **Acceptance criteria** - For each deliverable, write 2-4 testable conditions using the format:
   - `GIVEN [precondition] WHEN [action] THEN [observable result]`
3. **Out of scope** - Explicitly list what this sprint will NOT touch (prevents scope creep during implementation).
4. **Error scenarios** - For each deliverable, list at least one failure mode and how the system should behave.
5. **Verification method** - For each criterion: unit test, integration test, manual check, or lint rule.

## Phase 2: Guardian Reviews Contract

Switch perspective to **Guardian** and review the proposed contract against this checklist:

- [ ] **Coverage**: Does every spec requirement map to at least one acceptance criterion?
- [ ] **Testability**: Is every criterion objectively verifiable (no "should work well" or "handles errors appropriately")?
- [ ] **Completeness**: Are error paths and edge cases covered, not just happy paths?
- [ ] **Feasibility**: Can the verification methods actually be implemented with the project's test infrastructure?
- [ ] **Missing scenarios**: Are there spec requirements with no corresponding criterion?

For each gap found, propose a specific fix (add criterion, sharpen wording, add error scenario).

## Phase 3: Finalised Contract

Produce the agreed contract using the layout below. Save to `.copilot/specs/CONTRACT-<feature>.md` (alongside the spec).

```markdown
# Sprint Contract: <feature>

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

## After the Contract Is Agreed

- Builder references the contract during implementation (not just the spec).
- Guardian uses the Acceptance Criteria as the scope-audit checklist during review.
- After implementation, update each criterion's `Status` to `verified` or `failed`.
- Doer/Judge separation is preserved: this prompt only negotiates the contract; actual building and reviewing happen in their own agents.
