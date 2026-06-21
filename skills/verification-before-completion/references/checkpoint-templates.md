# Validation Checkpoint Templates

> v8.0 | 2026-05-03

Paste templates for agents to present verification evidence in a standardized format. Each checkpoint requires **actual tool output**, not assertions. Fill the sections that apply to your role; skip what doesn't.

---

## Implementation Checkpoint (senior-developer, data-engineer, data-scientist, ai-engineer)

Use after completing a feature, bug fix, or pipeline implementation.

````markdown
### Verification Evidence

**Lint/Type Check**

- Command: `<command executed>`
- Exit code: `<0 or error code>`
- Output (last 10 lines):

  ```text
  <paste actual output>
  ```

**Tests**

- Command: `<command executed>`
- Exit code: `<0 or error code>`
- Result: `<X passed, Y failed, Z skipped>`
- Output (failures only, if any):

  ```text
  <paste actual output>
  ```

**Build**

- Command: `<command executed>`
- Exit code: `<0 or error code>`

**Requirements Checklist**

- [ ] Requirement 1: <verified how>
- [ ] Requirement 2: <verified how>

**Regression (if bug fix)**

- Red phase (after reverting fix): `<test failed as expected? Y/N>`
- Green phase (fix restored): `<test passed? Y/N>`
````

---

## Code Review Checkpoint (guardian)

Use when completing a review pass.

````markdown
### Review Evidence

**Scope Drift Check**

- Spec/plan reference: `<file or PR description>`
- Files changed vs. files expected: `<match? Y/N>`
- Scope creep items found: `<list or "none">`
- Incomplete spec requirements found: `<list or "none">`

**Static Analysis**

- Command: `<linter/type checker command>`
- Issues found: `<count>`
- Output:

  ```text
  <paste actual output>
  ```

**Security Scan**

- Command: `<security scanner command>`
- Vulnerabilities found: `<count by severity>`
- Output:

  ```text
  <paste actual output>
  ```

**Test Verification**

- Command: `<test command>`
- Result: `<X passed, Y failed>`

**Review Verdict**: `PASS` | `NEEDS WORK`
**Blocking Issues**: `<list or "none">`
````

---

## Debug Investigation Checkpoint (debug-detective)

Use when presenting root cause analysis.

````markdown
### Investigation Evidence

**Failure Reproduction**

- Command/action to reproduce: `<what was done>`
- Observed behavior:

  ```text
  <paste error output or stack trace>
  ```

**Hypotheses Tested**

| #   | Hypothesis    | Evidence           | Result               |
| --- | ------------- | ------------------ | -------------------- |
| 1   | <description> | <what was checked> | Confirmed / Rejected |
| 2   | <description> | <what was checked> | Confirmed / Rejected |

**Root Cause**

- Component: `<module/file/function>`
- Mechanism: `<why it fails>`
- Evidence: `<the specific output proving this>`

**Fix Verification**

- Fix applied: `<description>`
- Original failure reproduced after fix? `NO` (must be NO)
- Test command: `<command>`
- Result: `<X passed>`
````

---

## Architecture Review Checkpoint (architect)

Use when validating a design specification.

```markdown
### Design Verification

**Scope Mode**: `REDUCTION` | `HOLD` | `EXPANSION`

**Contract Validation**

- [ ] All public interfaces defined with input/output types
- [ ] Error contracts specified (what errors, who handles them)
- [ ] No circular dependencies in module graph

**Replaceability Test**

- [ ] Each module can be described as a black box (inputs → outputs)
- [ ] Internal implementation details are not leaked through interfaces
- [ ] Removing any single module leaves the rest compilable (with a stub)

**Spec Completeness**

- [ ] Success criteria are testable (not vague)
- [ ] Edge cases documented
- [ ] Failure modes and recovery documented
```

---

## Data Pipeline Checkpoint (data-engineer)

Use in addition to the Implementation Checkpoint for pipeline work.

````markdown
### Pipeline Verification

**Schema Validation**

- Command: `<schema check command>`
- Result: `<pass/fail, mismatches>`

**Data Quality Checks**

- Null counts on key columns: `<paste output>`
- Row count delta (source vs. target): `<numbers>`
- Duplicate check (unique key violation count or 0 duplicates found): `<paste output>`

**Idempotency Test**

- Ran pipeline twice with same input? `Y/N`
- Output identical? `Y/N`

**Sample Output**

```text
<paste first 5 rows of output>
```
````

---

## Usage Notes

- **Fill what applies, skip what doesn't.** Not every checkpoint section is relevant to every task.
- **Actual output only.** Never fill a template with expected results. Paste what the tool actually returned.
- **Timestamp is implicit.** If the evidence is in this message, it was gathered in this session.
- **Failure is acceptable; fabrication is not.** If lint finds 3 errors, report 3 errors. Do not claim zero.
