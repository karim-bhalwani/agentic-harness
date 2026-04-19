# Pre-Landing Review Checklist

> Reusable checklist for pre-merge code review. Used by `guardian`, `release-manager`, and any agent performing pre-landing quality checks.

## Instructions

Review the diff (e.g., `git diff origin/main`) for the issues listed below. Be specific: cite `file:line` and suggest fixes. Skip anything that is fine. Only flag real problems.

**Three-phase review:**

- **Phase 0 (SCOPE AUDIT):** Run Scope Drift Detection first (see guardian SKILL.md). Informational, does not block merge.
- **Phase 1 (CRITICAL):** Run these categories next. These block merge.
- **Phase 2 (INFORMATIONAL):** Run remaining categories. These are advisory and go in the PR body but do not block merge.

**Output format:**

```text
Pre-Landing Review: N issues (X critical, Y informational)

**CRITICAL** (blocking merge):
- [file:line] Problem description
  Fix: suggested fix

**INFORMATIONAL** (non-blocking):
- [file:line] Problem description
  Fix: suggested fix
```

If no issues found: `Pre-Landing Review: No issues found.`

Be terse. For each issue: one line describing the problem, one line with the fix. No preamble, no summaries, no "looks good overall."

---

## Phase 1 - CRITICAL (Blocks Merge)

### SQL & Data Safety

- String interpolation in SQL queries (use parameterized queries or ORM methods exclusively)
- TOCTOU races: check-then-set patterns that should be atomic operations
- `UPDATE` or direct writes bypassing validation on fields that have constraints
- N+1 queries: missing eager loading for associations used in loops
- Raw SQL without parameterization in any ORM bypass

### Race Conditions & Concurrency

- Read-check-write without uniqueness constraint or retry on conflict
- Concurrent access to shared state without locking or atomic operations
- Status transitions that lack atomic compare-and-swap guards
- Unsanitized user input rendered as HTML/JS (XSS via `html_safe`, `raw()`, `Markup()`, `|safe`)

### LLM Output Trust Boundary

- LLM-generated values (emails, URLs, names) written to DB or used in operations without format validation
- Structured tool output (arrays, dicts) accepted without type/shape checks before database writes
- LLM output used in shell commands, SQL queries, or file paths without sanitization (injection via LLM)
- Prompt injection vectors: user input concatenated directly into system prompts without escaping

### Authentication & Authorization

- Missing authorization checks on new endpoints or data access paths
- Direct object reference without ownership validation (IDOR)
- Secrets, tokens, or API keys hardcoded in source or committed to config files
- Authentication bypass: endpoints accessible without valid session/token

---

## Phase 2 - INFORMATIONAL (Non-Blocking)

### Conditional Side Effects

- Code paths that branch on a condition but forget to apply a side effect on one branch, creating inconsistent state
- Log messages that claim an action happened but the action was conditionally skipped

### Magic Numbers & String Coupling

- Bare numeric literals used in multiple files that should be named constants
- Error message strings used as query filters elsewhere (tight string coupling)

### Dead Code & Consistency

- Variables assigned but never read
- Comments/docstrings that describe old behavior after the code changed
- Inconsistent naming, logging, or error handling patterns across modules
- Abandoned feature flags or stale configuration

### Test Gaps

- Missing negative-path tests (error cases, boundary conditions, empty inputs)
- Security enforcement features (auth, rate limiting) without integration tests verifying the enforcement path
- Assertions on presence without checking format or value constraints
- Missing mock assertions to verify side effects that should NOT happen

### Type Safety & Coercion

- Missing type hints on new public functions or method signatures
- Values crossing serialization boundaries (Python to JSON to JS) where type could silently change
- Hash/digest inputs that don't normalize types before serialization

### Performance Signals

- O(n*m) lookups in loops instead of indexed lookups (dict/set)
- In-memory filtering of full result sets that could be a database WHERE clause
- Missing pagination on endpoints that return unbounded collections
- Synchronous I/O in async contexts

### Crypto & Entropy

- `random.random()` for security-sensitive values (use `secrets` module instead)
- Non-constant-time comparisons (`==`) on secrets or tokens (use `hmac.compare_digest`)
- Truncation of data instead of hashing (less entropy, easier collisions)

---

## Gate Classification Summary

```text
CRITICAL (blocks merge):               INFORMATIONAL (in PR body):
├─ SQL & Data Safety                    ├─ Conditional Side Effects
├─ Race Conditions & Concurrency        ├─ Magic Numbers & String Coupling
├─ LLM Output Trust Boundary            ├─ Dead Code & Consistency
└─ Authentication & Authorization       ├─ Test Gaps
                                        ├─ Type Safety & Coercion
                                        ├─ Performance Signals
                                        └─ Crypto & Entropy
```

---

## Suppressions - DO NOT Flag These

The following patterns are explicitly suppressed. Flagging them wastes reviewer and author time.

- **Redundant but readable guards**: e.g., `if x is not None` when `x` is already guaranteed non-None by a prior check, but the guard aids readability
- **Threshold/constant values without comments**: thresholds change during tuning, comments rot faster than the values
- **Assertions that could be marginally tighter**: if the assertion already covers the behavior under test, don't recommend tightening
- **Consistency-only suggestions**: wrapping a value in a conditional just to match how another constant is guarded elsewhere
- **Regex edge cases for constrained inputs**: if the input is already validated upstream, don't flag theoretical regex bypasses
- **Tests that exercise multiple guards simultaneously**: tests don't need to isolate every guard into a separate case
- **Harmless no-ops**: e.g., filtering for an element that is never present in the collection
- **Changes already addressed in the diff**: read the FULL diff before commenting. If the author already fixed an issue in a later hunk, don't flag the earlier state.
- **Import ordering quibbles**: these are enforced by linters (`ruff`, `isort`), not by reviewers
- **Type hint completeness on private/internal functions**: focus type hint enforcement on public interfaces only


