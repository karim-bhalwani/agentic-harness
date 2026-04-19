---
name: systematic-debugging
description: "Use when a bug, error, or unexpected behavior needs investigation. Enforces evidence-first root cause analysis before any fix attempt. Load before any debugging session - covers all failure modes from data pipelines to API errors to LLM misbehavior. DO NOT USE FOR: code review without a specific error (use guardian), implementing known fixes (use implementer), performance profiling without failures (use guardian), or architecture design (use architect)."
argument-hint: "[error message, bug description, or failing behavior]"
license: MIT
compatibility: "VS Code, Claude Code"
metadata:
  version: "7.0"
  updated: "2026-04-12"
  dependencies: ["verification-before-completion"]
---

# Systematic Debugging Skill

> Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani | Deps: verification-before-completion

## Dependencies

Load the following via `read_file` before using this skill. Skills marked ★ have `disable-model-invocation: true` and cannot self-invoke - they **must** be loaded explicitly.

- `skills/verification-before-completion/SKILL.md` ★ - completion gate; must be passed before declaring a fix verified

---

## Iron Law

> **NO FIXES WITHOUT A COMPLETED ROOT CAUSE INVESTIGATION.**
>
> Applying a fix before the root cause is confirmed wastes time, masks the real problem, and introduces new failures. Pressure is not an exception. "It's probably X" is not a root cause. A confirmed root cause is one where: (a) you can reproduce the failure, and (b) you can explain the exact chain of events from trigger to symptom.

---

## Common Rationalizations (and Why They Fail)

| Rationalization                                             | Why It Fails                                          | Required Response                                                        |
| ----------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------ |
| "It's probably X, let me just change it"                    | Unverified hypothesis becomes a random mutation       | Form a hypothesis, test it first                                         |
| "One more fix attempt" after 3 failures                     | You are debugging a symptom, not the cause            | Stop. Run Phase 1 again from scratch                                     |
| "This is a simple fix, investigation would take too long"   | Simple-looking bugs routinely have non-obvious causes | Simple bugs take ~5 min to investigate; wrong fixes cost hours of rework |
| "We made a similar change last time"                        | Bugs in complex systems are context-sensitive         | Confirm the exact same context applies before copying                    |
| "I already know what's wrong"                               | Confirmation bias leads to missed root causes         | Still run Phase 1; let evidence confirm or refute                        |
| "Let me try a slightly different approach" after 3 failures | Without root cause, all approaches are guesses        | Three failures → architectural escalation, not a fourth guess            |

---

## Red Flags

Stop and re-read the Iron Law if you notice yourself doing any of these:

- Editing a file without knowing which test will fail if the edit is wrong
- Running the same failing command twice with only minor parameter changes
- Asking "what else could I try?" instead of "what does the evidence say?"
- Fixing in multiple locations simultaneously (one fix at a time)
- Declaring "fixed" before a test or fresh evidence confirms it

---

## 4-Phase Investigation Methodology

### Phase 1: Root Cause Investigation

**Objective**: Gather enough evidence to form testable hypotheses.

1. **Read the full error message and stack trace** - do not skim. The line number and exception type are evidence.
2. **Reproduce the failure** - if you cannot reproduce it, you cannot confirm a fix. Document exactly how to reproduce.
3. **Check recent changes** - `git log --oneline -20` and `git diff HEAD~5` to identify what changed near the failure point.
4. **Map the execution path** - trace from the trigger event to the failure point through every layer:
   - Input → Validation → Business Logic → Data Access → External Service
   - LLM input → Prompt construction → Model call → Response parsing → Downstream
5. **Instrument component boundaries** - if the failure path is unclear, add temporary logging at each boundary. Remove after root cause is found.
6. **Collect baseline evidence**:
   - What is the exact failing input?
   - What is the exact wrong output or error?
   - Which component first produces the wrong value?
   - What is the expected value at that point?

**Exit condition**: You can state "The failure occurs in `[component]` when `[exact condition]`" with evidence.

### Phase 2: Pattern Analysis

**Objective**: Understand whether this is a known pattern with a known fix class.

1. **Find working examples** - search the codebase for similar operations that work correctly (`grep_search`, `semantic_search`).
2. **Compare working vs. failing** - list every structural difference between the working path and the failing path.
3. **Identify the differentiator** - which single difference explains the failure? If none does, return to Phase 1.
4. **Check for known patterns**:
   - Off-by-one error (array index, range boundary)
   - Null/None not handled (unguarded attribute access)
   - Type mismatch (string vs int, dict vs list)
   - Race condition (shared state, async ordering)
   - Config/env mismatch (wrong secret, wrong URL, wrong schema version)
   - Schema drift (upstream data changed shape)

**Exit condition**: You can classify the failure type and cite a working example that deviates from the failing case in exactly one way.

### Phase 3: Hypothesis and Testing

**Objective**: Confirm the root cause via minimal-change experiments.

1. **Form one hypothesis at a time** - "The failure is caused by `[specific condition]`."
2. **Define what would confirm and reject it** - "If this is correct, adding `[x]` should produce `[y]`. If wrong, the output will still be `[z]`."
3. **Test with the minimal possible change** - isolate the variable; don't combine changes.
4. **Document the result** - confirmed, rejected, or inconclusive. Rejected hypotheses are as valuable as confirmed ones.
5. **3-strike rule** - if three independent hypotheses are rejected, do NOT form a fourth. The evidence base is insufficient. Return to Phase 1 with broader instrumentation.

**Exit condition**: One hypothesis is confirmed by a reproducible test.

### Phase 4: Implementation

**Objective**: Apply the minimal fix that resolves the root cause without side effects.

1. **Write a failing test first** - create a test that reproduces the bug. It must fail before the fix and pass after.
2. **Apply the fix** - one change. If the fix requires multiple changes in unrelated locations, that is a signal the root cause analysis is incomplete.
3. **Run the failing test** - confirm it now passes.
4. **Run the full test suite** - confirm no regressions.
5. **3-strike architectural escalation** - if fixes keep breaking sibling tests, stop. The root cause is architectural, not local. Escalate to `architect`.
6. **Load `verification-before-completion`** - complete the evidence gate before declaring done.

---

## Component Boundary Instrumentation

Use this pattern when the failure path spans multiple components and the exact boundary is unclear.

Add temporary instrumentation at each layer boundary:

```python
# Data pipeline example - add at each stage boundary
import logging
logger = logging.getLogger(__name__)

# Before calling the next stage
logger.debug("BOUNDARY: entering [stage_name] | input shape=%s | sample=%s",
             df.shape, df.head(2).to_dict())

# After receiving output from a stage
logger.debug("BOUNDARY: exiting [stage_name] | output shape=%s | null_count=%s",
             df.shape, df.isnull().sum().to_dict())
```

**Rules:**

- Always remove boundary logging after the root cause is confirmed.
- Log at `DEBUG` level, never `INFO` or higher (boundary logging is noisy in production).
- For LLM calls, log the prompt token count and the raw response before any parsing.

---

## 3-Strike → Architectural Escalation Protocol

If any investigation phase exhausts 3 attempts without progress:

1. **Document what you know**: What was observed? What was ruled out? What is still unknown?
2. **Form the architectural question**: Is the problem in the design of this component, not just its implementation?
3. **Escalate to `architect`** with the documented findings - do not attempt a fourth fix.
4. **Signal**: "`[component]` has failed 3 investigation cycles. Root cause is likely architectural. Escalating."

---

## Outputs & Deliverables

- **Primary Output**: Root Cause Report (see template below)
- **Secondary Output**: Failing test that confirms the root cause
- **Quality Gate**: `verification-before-completion` passed before declaring fix verified

### Root Cause Report Template

```markdown
## Root Cause Report

**Date**: YYYY-MM-DD
**Reporter**: [agent or person]
**Severity**: Critical / High / Medium / Low

### Symptom

[Exact observed behavior, including error message and stack trace]

### Root Cause

[One-sentence statement of the confirmed root cause]
[Which component, which condition, which exact code path]

### Evidence Chain

1. [Observation 1] → [leads to]
2. [Observation 2] → [leads to]
3. [Confirmed root cause]

### Hypotheses Considered

| Hypothesis | Result    | Evidence                 |
| ---------- | --------- | ------------------------ |
| [H1]       | Rejected  | [why]                    |
| [H2]       | Confirmed | [what test confirmed it] |

### Fix Applied

[Description of the minimal change made]
[File(s) modified]

### Verification

- [ ] Failing test written and now passes
- [ ] Full test suite passes
- [ ] verification-before-completion gate passed
```

---

## Definition of Done

- [ ] Root cause stated in one sentence with evidence citation
- [ ] Failing test exists that reproduces the bug
- [ ] Fix applied passes the failing test
- [ ] No regressions (full test suite passes)
- [ ] `verification-before-completion` gate completed
- [ ] Root Cause Report written

## Constraints

- **One hypothesis at a time.** Never test multiple simultaneous changes.
- **One fix at a time.** Never apply two fixes in the same commit.
- **Evidence required.** "It seems like" and "probably" are not evidence.
- **3-strike limit.** Three failed hypotheses → architectural escalation, not a fourth attempt.
