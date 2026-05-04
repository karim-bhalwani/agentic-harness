---
name: subagent-execution
description: "Use when executing an approved implementation plan by dispatching work to subagents. Enforces context isolation, two-stage review per task, and a formal status protocol. Load before orchestrating multi-task plans across subagents. DO NOT USE FOR: deciding whether to delegate (use task-routing), creating the plan itself (use concise-planning), single-task execution you can handle directly, or code review (use guardian)."
argument-hint: "[approved plan or list of tasks to execute]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: ["task-routing", "guardian", "verification-before-completion"]
---

# Subagent Execution Skill

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani | Deps: task-routing, guardian, verification-before-completion

## Dependencies

Load the following via `read_file` before using this skill.

- `skills/task-routing/SKILL.md` - verify tasks are appropriate for subagent delegation before dispatching
- `skills/guardian/SKILL.md` - spec compliance and quality review procedures
- `skills/verification-before-completion/SKILL.md` ★ - completion gate before declaring all tasks done

---

## Context Isolation Principle

> **Subagents must NEVER inherit the orchestrator's session history.**
>
> Construct exactly what each subagent needs: the spec section, the relevant files, the task description, and the acceptance criteria. Nothing else. This prevents context pollution in the subagent and preserves the orchestrator's own context budget for coordination work.

Each subagent dispatch must include:

1. The task specification (what to build, in/out scope)
2. The file paths they may read and modify
3. The acceptance criteria their output must satisfy
4. The output format (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED - see below)

---

## Subagent Status Protocol

Every subagent must return exactly one of these statuses:

| Status               | Meaning                                                            | Orchestrator Action                                          |
| -------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------ |
| `DONE`               | Task complete, tests pass, ready for review                        | Proceed to two-stage review                                  |
| `DONE_WITH_CONCERNS` | Complete but flagged issues exist                                  | Proceed to review; concerns included in review input         |
| `NEEDS_CONTEXT`      | Blocked by missing information or clarification                    | Re-dispatch with the missing context; log what was missing   |
| `BLOCKED`            | Cannot proceed due to architectural conflict or missing capability | Escalate to architect; do not re-dispatch without resolution |

**Never re-dispatch a BLOCKED task with only a prompt change.** BLOCKED means the task requires structural resolution, not more context.

---

## Workflow

### Step 1: Pre-Execution Verification

Before dispatching any subagent:

1. Load the approved plan (from `concise-planning` or `architect` spec).
2. Verify the plan passes the No Placeholders check (see `concise-planning` skill). If any step is vague, resolve it before dispatching.
3. Classify each task using the task-routing 6-check protocol. Confirm each task is appropriate for subagent execution.
4. Identify which tasks are `[SEQ]` (sequential) and which are `[PAR]` (parallel). Parallel tasks can be dispatched concurrently via `runSubagent`.

### Step 2: Dispatch

For each task (or batch of parallel tasks):

1. Construct the subagent context package (spec section + file paths + acceptance criteria). Keep it minimal - only what the subagent needs.
2. Dispatch via `runSubagent` with the appropriate agent (`senior-developer`, `data-engineer`, `ai-engineer`, etc.).
3. Record the dispatch: task ID, agent used, timestamp, context provided.

### Step 3: Two-Stage Review (Per Task)

After each subagent returns `DONE` or `DONE_WITH_CONCERNS`, run two sequential review stages before accepting the output:

**Stage 1 - Spec Compliance Review** (did the subagent do the right thing?)

- Dispatch `guardian` with the task spec and the subagent's output.
- Guardian produces a Scope Audit table: DONE / PARTIAL / NOT DONE / SCOPE CREEP for each spec item.
- **Gate**: If any spec item is NOT DONE or CHANGED in a breaking way, reject the output and re-dispatch to the implementer with a correction brief.
- If scope audit passes, proceed to Stage 2.

**Stage 2 - Code Quality Review** (did the subagent do it well?)

- Dispatch `guardian` with Phase 1 (Critical) and Phase 2 (Informational) review.
- Gate: Critical findings block acceptance. Informational findings are logged and deferred.
- If quality review passes, accept the output and mark the task complete.

> **Why two stages?** Reviewing code quality before confirming spec compliance wastes effort - you may be reviewing code that doesn't meet requirements at all. Spec first, quality second.

### Step 4: Completion

After all tasks are complete:

1. Load `verification-before-completion` and complete the evidence gate.
2. Summarize: tasks completed, reviews passed, concerns deferred.
3. If any BLOCKED tasks remain unresolved, surface them explicitly before handing off to `release-manager`.

---

## Example Dispatch Context Package

```markdown
## Task: Add rate limiting to POST /api/checkout

**Spec section**: See `.copilot/specs/checkout-spec.md` Section 3.2 Rate Limiting
**Files to modify**: `src/api/checkout.py`, `tests/test_checkout.py`
**Files to read (context only)**: `src/middleware/rate_limiter.py`, `pyproject.toml`
**Acceptance criteria**:

- POST /api/checkout returns 429 after 10 requests in 60 seconds from the same IP
- 429 response includes `Retry-After` header
- Unit test covers rate limit threshold and reset behavior
- No changes to the checkout business logic

**Output required**: Return status (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED) + PR-ready diff
```

---

## Anti-Patterns to Avoid

| Anti-Pattern                                          | Why                                                                   | Correct Approach                     |
| ----------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------ |
| Forwarding full session history to subagent           | Context pollution; subagent reasons about your history not their task | Compile a focused context package    |
| Skipping Stage 1 (spec compliance) to save tokens     | Reviewing quality before confirming requirements wastes review effort | Stage 1 always runs first            |
| Re-dispatching BLOCKED with only a prompt change      | BLOCKED signals structural conflict, not missing info                 | Escalate to architect                |
| Running Stage 1 and Stage 2 in the same Guardian call | Two stages serve different purposes; combined calls conflate them     | Separate dispatches                  |
| Dispatching sequential tasks in parallel              | Splits reasoning chain; errors compound                               | Respect [SEQ] / [PAR] classification |

---

## Outputs & Deliverables

- **Primary Output**: All plan tasks completed with two-stage review evidence
- **Secondary Output**: Review artifacts persisted to `.copilot/artifacts/`
- **Quality Gate**: `verification-before-completion` passed; no unresolved BLOCKED tasks

## Definition of Done

- [ ] All tasks in the plan have status DONE or DONE_WITH_CONCERNS
- [ ] Every DONE task passed two-stage review (spec compliance + quality)
- [ ] All DONE_WITH_CONCERNS items are documented and acknowledged
- [ ] No unresolved BLOCKED items remain
- [ ] `verification-before-completion` gate passed
