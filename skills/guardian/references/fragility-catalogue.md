# Fragility Catalogue

> Deep-dive reference. Loaded on demand for pre-mortem analysis and fragility-aware code review.

Use this catalogue to identify code that is correct today but fragile against future edits. For each pattern, ask: "What change would a reasonable developer make here that would break this?" If you cannot imagine a plausible edit that causes a problem, move on.

## Calibration Rules

- **Not a bug hunt.** The code may be perfectly correct today. You are looking for places where a developer who lacks full context could make a seemingly reasonable change that breaks something non-obviously.
- **Plausible edits only.** The imagined change must be something a well-intentioned developer would do (refactoring, feature addition, performance tweak, dependency upgrade). No adversarial scenarios.
- **Specific, not generic.** Every finding must reference actual functions, variables, and file paths. "This function has no tests" is an observation, not a fragility.
- **Separate actual bugs.** If you discover a real, current bug while reading, flag it to the user immediately. Do not bury it in a fictional post-mortem.
- **Honest severity.** Silent data corruption is Critical. A clear error in an uncommon code path is Low. Do not inflate.

## Fragility Patterns

### 1. Implicit Ordering Dependencies

Code that must run in a specific order but does not enforce it. Setup methods that must be called before other methods. List processing that assumes elements arrive sorted. Initialization sequences where step 3 silently depends on step 1 having run.

**Future edit**: Someone reorders calls, adds a step between existing ones, or invokes a method before the object is fully initialized.

**Hardening**: Enforce ordering with state machine patterns, builder APIs that require sequential calls, or runtime assertions (`assert self._initialized`).

### 2. Semantic Coupling Through Shared Mutable State

Two components that communicate through a shared object (dict, list, module-level variable, attribute on a passed-in object) rather than through explicit arguments and return values. The reader of component A might not realize that component B reads or writes the same state.

**Future edit**: Someone modifies one component's use of the shared state without realizing the other depends on it. Or someone adds caching/memoization that prevents the shared state from updating.

**Hardening**: Replace shared mutable state with explicit function parameters and return values. If sharing is necessary, use immutable snapshots or observable patterns with clear ownership.

### 3. Stringly-Typed Contracts

Logic that depends on the exact value of strings: dict keys, status fields, format strings, column names, error messages. These create invisible contracts between producers and consumers that no type checker or test enforces.

**Future edit**: Someone renames a status string, adds a new enum variant that existing match/if-elif chains do not handle, or changes a dict key in one place but not another.

**Hardening**: Replace magic strings with enums, constants, or typed dataclasses. Add exhaustiveness checks (`match` with no default, or `assert_never`).

### 4. Assumptions Baked Into Data Transformations

A function that processes data assuming a particular shape, range, or distribution, e.g., assuming a list is non-empty, a value is positive, a string matches a pattern, or a column contains no nulls. These assumptions might be true today because of how the data is produced upstream, but nothing enforces them.

**Future edit**: Someone changes the upstream data source, adds a new code path that feeds different data into the function, or relaxes validation at the system boundary.

**Hardening**: Add explicit validation at function entry (`if not items: raise ValueError`). Use schema validation (Pydantic, StructType, dbt tests) at system boundaries.

### 5. Coincidental Correctness

Code that produces the right result for the wrong reason. A condition that happens to work because two variables are always equal today. A loop that does not handle the empty case but is never called with an empty input. An exception handler that catches too broadly but currently only encounters one exception type.

**Future edit**: The coincidence stops holding. The input space widens, a new exception type appears, or the previously-equal variables diverge.

**Hardening**: Add assertions that make the assumption explicit. Narrow exception handlers. Add test cases for edge inputs (empty, None, boundary values).

### 6. Non-Atomic Compound Operations

A sequence of operations that should be atomic but is not: "check then act" patterns, multi-step state updates with no rollback, or file operations that assume no concurrent access. Includes anything where a failure or interruption between steps leaves the system in an inconsistent state.

**Future edit**: Someone adds concurrency, moves the code to a context where interruption is possible, or adds an early return between the steps.

**Hardening**: Use transactions, context managers, or atomic operations. For check-then-act, use compare-and-swap or database-level constraints.

### 7. Invisible Invariants

Relationships between pieces of data that must be maintained but are enforced only by convention, e.g., "this list and that dict always have the same keys", "this counter equals len(that list)", "this field is non-None whenever that flag is True". No assertion, type, or test enforces the invariant.

**Future edit**: Someone updates one side of the invariant but not the other, especially when the two sides are in different functions or files.

**Hardening**: Encode invariants in types (e.g., a dataclass that derives one field from another). Add assertions. Write tests that verify the invariant after mutations.

### 8. Load-Bearing Defaults

Default values (function parameters, config settings, class attributes, environment variables) that the code subtly depends on. The default does not just provide convenience; the code would behave incorrectly or dangerously with a different value, and nothing documents this constraint.

**Future edit**: Someone changes the default to something that seems equally reasonable, or a caller starts passing an explicit value that nobody anticipated.

**Hardening**: Add a comment explaining why the default is what it is. Add validation that rejects dangerous values. Consider making the parameter required if any other value is unsafe.

### 9. Implicit Resource Lifecycle

Resources (connections, file handles, locks, temporary files, background threads) that are created but whose cleanup depends on a particular control flow. No context manager or finalizer guarantees cleanup.

**Future edit**: Someone adds an early return, raises an exception, or refactors the function into smaller pieces, and the cleanup code is no longer reached.

**Hardening**: Use context managers (`with` statements), `try/finally`, or `atexit` handlers. For long-lived resources, use a lifecycle manager class.

### 10. Version-Coupled Assumptions

Code that depends on the behavior of a specific version of a dependency, runtime, or protocol, e.g., relying on dict ordering (pre-3.7), assuming a library function's undocumented side effect, or depending on the exact format of an error message from a third-party library.

**Future edit**: The dependency is upgraded, the runtime version changes, or the API's undocumented behavior shifts.

**Hardening**: Pin dependencies with version constraints. Use only documented API behavior. Add integration tests that verify assumptions. Wrap third-party calls in an adapter layer.

## Post-Mortem Format

When writing pre-mortem findings, use this structure for each:

```markdown
### <Short incident title>

**Severity:** Critical | High | Medium | Low
**Component:** <file(s) and function(s) involved>
**Fragility type:** <category from catalogue above>

#### What happened

<2-4 sentences describing the bug as if it already occurred. What did users or
the team observe? Be specific, name the symptom.>

#### The change that caused it

<Describe the edit a future developer made. Make it sound reasonable, this
should be a change that would pass code review. Include a plausible motivation
(new feature, refactoring, performance improvement, dependency upgrade).>

#### Why it broke

<Explain the hidden assumption or fragility the change violated. Reference
actual function names, variable names, and file paths.>

#### How it was caught

<How would this bug surface? Would tests catch it? Would it fail silently?
Would it corrupt data? Would it only manifest under specific conditions?>

#### Hardening suggestions

<1-3 concrete, actionable suggestions. Specific enough that someone could
implement them directly.>
```

## Report Structure

```markdown
# Pre-Mortem Report

**Scope:** <files/modules analyzed>
**Date:** <today's date>

## Summary

<Short paragraph: how many findings, dominant themes, systemic vs. independent>

## Post-Mortems

### 1. <title>
...

### 2. <title>
...

## Themes and Recommendations

<Cross-cutting patterns. If several findings point to the same underlying
architectural issue, call it out here. Suggest structural changes that address
multiple fragilities at once.>
```

## Quality Targets

- **3-7 findings per module**, depending on complexity
- Prioritize findings where **cause and effect are non-obvious** (change in one place, breakage elsewhere)
- Prefer fragilities that are **endemic to the design**, not surface-level issues
- Target findings that make a reader say "I would not have thought of that"
