---
name: verification-before-completion
description: "Evidence-based completion gate that enforces running verification commands before any success claim is made. Use when about to claim work is complete, fixed, or passing - requires fresh command output before declaring done. DO NOT USE FOR: debugging failures (use systematic-debugging), code review (use guardian), holdout acceptance testing (use holdout-validation), or planning tasks (use concise-planning)."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: []
---

# Verification Before Completion

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

## When to Load This Skill

Load this skill when:

- About to claim that a task, fix, or implementation is complete
- Running final verification commands before declaring work done
- Reviewing whether an agent has provided fresh evidence for completion claims

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**This rule applies to all implications of completion, not just exact phrases. Reframing a claim in different words does not exempt it from verification.**

## The Iron Law

```text
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```text
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Completion Verification Sequence

Before any completion claim, execute these steps **in order**:

1. **Run the Gate Function** (steps 1–5 above). If no verification command exists for the claimed scope (e.g., no test suite, no build tool available), do NOT proceed with the completion claim. Instead, state: "No verification command is available for [claim]. Cannot confirm status. Required action: [specify what must be set up or provided before this claim can be verified]."
2. **Execute Mid-Execution Drift Checks** if at a phase transition (see section below).
3. **Verify each Intent Contract condition** against fresh evidence.
4. **Complete the Definition of Done checklist** - all seven items must be checked.
5. **Produce the Quality Gates Report** in the required format.

Only after all five steps are complete may you state the completion claim. The Gate Function, Drift Checks, Intent Contract check, Definition of Done, and Quality Gates Report are all required. No step may be skipped.

## Common Failures

| Claim                 | Requires                        | Not Sufficient                 |
| --------------------- | ------------------------------- | ------------------------------ |
| Tests pass            | Test command output: 0 failures | Previous run, "should pass"    |
| Linter clean          | Linter output: 0 errors         | Partial check, extrapolation   |
| Build succeeds        | Build command: exit 0           | Linter passing, logs look good |
| Bug fixed             | Test original symptom: passes   | Code changed, assumed fixed    |
| Regression test works | Red-green cycle verified        | Test passes once               |
| Agent completed       | VCS diff shows changes          | Agent reports "success"        |
| Requirements met      | Line-by-line checklist          | Tests passing                  |

## Failure Taxonomy

| Failure Mode                | Symptom                                             | Immediate Recovery                                                                                                                                      |
| --------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `claim_without_evidence`    | "Tests pass" stated without running tests           | Run the command. Get the output. State the claim with the output as evidence.                                                                           |
| `partial_verification`      | Only some tests run; claiming full pass             | Run the full suite. Partial runs are not verification.                                                                                                  |
| `stale_evidence`            | Citing a test run from earlier in the session       | Evidence is stale if the verification was not run in the current message turn. Re-run any command whose output was not produced in this exact response. |
| `agent_self_report_trusted` | Accepting subagent "success" without VCS diff check | Run `git diff` or check file modification timestamps. Agent reports are claims, not evidence.                                                           |
| `exit_code_ignored`         | Command ran but exit code not checked               | Exit code 0 = success. Any other = failure. Always check.                                                                                               |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- ANY wording implying success without having run verification

## Rationalization Prevention

| Excuse                                  | Reality                      |
| --------------------------------------- | ---------------------------- |
| "Should work now"                       | RUN the verification         |
| "I'm confident"                         | Confidence ≠ evidence        |
| "Just this once"                        | No exceptions                |
| "Linter passed"                         | Linter ≠ compiler            |
| "Agent said success"                    | Verify independently         |
| "I'm tired"                             | Exhaustion ≠ excuse          |
| "Partial check is enough"               | Partial proves nothing       |
| "Different words so rule doesn't apply" | No wording escapes this rule |

## Key Patterns

### Tests

```text
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

### Regression tests (TDD Red-Green)

```text
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

### Build

```text
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

### Requirements

```text
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

### Agent delegation

```text
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:

- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**

- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

## Checkpoint Templates

For standardized evidence presentation, use the role-specific paste templates in `references/checkpoint-templates.md`. Fill the sections that apply to your role; skip what doesn't. These ensure verification evidence is consistent and auditable across agents and sessions. If `references/checkpoint-templates.md` is not available in context, use the Quality Gates Report Format defined in this document as the fallback template.

**Rule applies to:**

- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## Mid-Execution Drift Checks

At every phase transition (moving between todo items, switching investigation phases, starting a new section of work), pause and run these three self-checks:

### 1. Scope Drift

> "Am I still solving the original problem?"

Re-read the task description or spec. If your current action doesn't trace back to a stated requirement, you are drifting. Stop, note the drift, and return to the plan.

### 2. Retry Loop Detection

> "Have I attempted this same fix or approach before?"

If the same file, test, or command has failed 3 times with substantially similar attempts, do NOT retry. Escalate to the user with: what was tried, what failed, and what alternative approaches exist.

### 3. Plan Adherence

> "Does my todo list reflect what I'm actually doing?"

If you're working on something not in your todo list, either (a) add it and justify why, or (b) stop and return to the planned work. Untracked work is invisible work.

**When to skip:** Single-step tasks with no plan (quick-fix, config change, typo). If there's no plan to drift from, these checks don't apply.

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.

## Outputs & Deliverables

- **Primary Output**: Verification evidence (command outputs, test logs, CI run links)
- **Secondary Output**: Checklist of verification commands and required acceptance criteria
- **Success Criteria**: Evidence confirms the claimed status (exit codes, zero failures)
- **Quality Gate**: Attach verification artifacts to PRs or closure reports when claiming completion

## Common Pitfalls

- **Premature Satisfaction**: Saying "done" before running verification. Always execute the full verification command.
- **Partial Evidence**: "Most tests pass" is not passing. 100% success rate or state the actual failure count.
- **Ignoring Exit Codes**: Assuming "looks good" means success. Check exit codes; `0` = success, non-zero = failure.
- **Stale Verification**: Running verification once per project is not enough. Re-verify when claiming completion each time.
- **Mixing Concerns**: Testing one thing but claiming another passes. Verify exactly what you're claiming.
- **Trusting Reports**: Agent says "success" but you didn't verify. Always run the check yourself independently.

## Integration Points

| Phase              | Input From               | Output To               | Context                                                 |
| ------------------ | ------------------------ | ----------------------- | ------------------------------------------------------- |
| Completion Claim   | Any agent finishing work | Verification gate       | Require fresh evidence before accepting completion      |
| Testing            | Implementation complete  | Evidence collection     | Run full test suite, capture output, check exit codes   |
| PR/Merge           | Code ready for review    | Artifact attachment     | Include verification evidence in PR comments or closure |
| Requirements Check | Feature specification    | Line-by-line validation | Verify each requirement is met with evidence            |

## Quality Gates Report Format

Before wrapping up any task, run a structured quality gates triage and report in this format:

```markdown
## Quality Gates

| Gate           | Status | Evidence             |
| -------------- | ------ | -------------------- |
| Build          | PASS   | exit 0, 0 errors     |
| Lint/Typecheck | PASS   | 0 warnings, 0 errors |
| Unit Tests     | PASS   | 34/34 pass           |
| Smoke Test     | PASS   | endpoint returns 200 |

## Requirements Coverage

| Requirement        | Status   | Notes                     |
| ------------------ | -------- | ------------------------- |
| Add login endpoint | Done     | POST /api/login           |
| Rate limiting      | Deferred | Needs Redis, out of scope |
```

- Report **deltas only** (PASS/FAIL). No verbose logs unless a gate fails.
- Include a **requirements coverage** line mapping each requirement to Done/Deferred + reason.
- If a gate fails, apply one fix, re-run the full verification command, and report the new output. Repeat this cycle up to 3 times. If the gate still fails after 3 attempts, stop and message the user with: what was tried, what failed each time, and what you believe the root cause is.

## Intent Contracts

Every agent defines an **Intent Contract**: conditions that must be true when the agent's work is done. These are NOT procedural checklists ("run the tests"). They are outcome statements ("the user can complete their workflow without errors").

### Purpose

Intent contracts shift agent accountability from **process compliance** ("did you follow the steps?") to **outcome delivery** ("does the software work for the user?"). A passing test suite that misses the user's actual need is a failure, not a success.

### How to Write Intent Contracts

- Start with "When your work is done, these conditions must be true:"
- Each condition should be verifiable by a third party who has never seen the code
- Focus on what is true in the world, not what is true in the code
- Include at least one condition about what should NOT happen (failure modes)

### Relationship to Definition of Done

The Intent Contract supplements, not replaces, the Definition of Done. The DoD contains procedural checks (tests pass, types clean). The Intent Contract contains outcome checks (user workflow succeeds, edge cases handled). Both must be satisfied.

### Relationship to Verification

Intent contracts define WHAT to verify. The verification gate (above) defines HOW to verify it. When running verification before completion:

1. Check each Intent Contract condition against evidence
2. Run the DoD procedural checks
3. Only claim completion when both are satisfied

## Definition of Done

- [ ] Verification command executed fresh (not cached or stale)
- [ ] Exit code is 0 and output confirms zero failures
- [ ] Evidence attached (command output, test log, or screenshot)
- [ ] Each claim matches a specific verification artifact
- [ ] No "should", "probably", or "seems" language in completion statement
- [ ] Quality Gates report produced with PASS/FAIL for each gate
- [ ] Requirements coverage checklist maps every requirement to Done/Deferred

## Constraints

- **Technical Constraints:** Verification requires running the canonical commands in the project environment; do not rely on stale outputs
- **Governance Constraints:** Claims without attached verification are invalid for closure

## References

- [checklist.md](references/checklist.md) - Verification checklist template for pre-completion gates
- [checkpoint-templates.md](references/checkpoint-templates.md) - Role-specific paste templates for standardized evidence presentation
