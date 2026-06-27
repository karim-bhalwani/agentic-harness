---
name: subagent-execution
description: "Use when executing an approved implementation plan by dispatching work to subagents. Enforces context isolation, two-stage review per task, and a formal status protocol. Load before orchestrating multi-task plans across subagents. DO NOT USE FOR: deciding whether to delegate (use task-routing), creating the plan itself (use concise-planning), single-task execution you can handle directly, or code review (use guardian)."
argument-hint: "[approved plan or list of tasks to execute]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: ["task-routing", "guardian", "verification-before-completion"]
---

# Subagent Execution Skill

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani | Deps: task-routing, guardian, verification-before-completion

## Dependencies

Load the following via `read_file` before using this skill.

- `~/.copilot/skills/task-routing/SKILL.md` - verify tasks are appropriate for subagent delegation before dispatching
- `~/.copilot/skills/guardian/SKILL.md` - spec compliance and quality review procedures
- `~/.copilot/skills/verification-before-completion/SKILL.md` ★ - completion gate before declaring all tasks done

---

## Context Mode: Fresh vs Inherited

Every subagent delegation must explicitly choose one of two context modes.
Never leave this implicit; the choice has a direct, large impact on token cost and correctness.

### Fresh Context (default - use this unless inherited is explicitly justified)

The subagent starts with a clean context window. It receives ONLY:

1. The task description (what to do, what files to touch, scope in/out)
2. Relevant file paths (what it may read and modify)
3. Explicit acceptance criteria (what DONE looks like)
4. Required output format (`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`)

**Use fresh context for**:

- Independent tasks that can be fully specified without session history
- Parallel branches (two subagents working different files simultaneously)
- Specialist tasks (Debug Detective investigating a single error)
- Any task where the subagent does not need to know what was tried before

**Token impact**: Fresh context costs only the task packet (~500-2K tokens input).
Inheriting a 40K-token parent session costs 40K tokens input per child. At 3 children,
that is 120K tokens vs 6K tokens for the same work.

### Inherited Context (use sparingly, with explicit justification)

The subagent receives the full accumulated parent session history.

**Use inherited context only when**:

- The subagent is a direct continuation (e.g., Guardian reviewing code written 2 steps ago)
- The subagent needs to understand WHAT WAS ALREADY TRIED to avoid repeating it
- The task cannot be meaningfully specified without the session history

**Inherited context is NOT justified by**:

- Convenience ("easier to just pass everything")
- Uncertainty ("not sure what it needs, give it everything")
- Default ("this is how we've always done it")

### Dispatch Template

When constructing any subagent dispatch, include the context mode explicitly:

```text
CONTEXT MODE: fresh | inherited
TASK: [one sentence]
FILES TO READ: [list of relative paths]
FILES TO MODIFY: [list of relative paths]
SCOPE IN: [what to do]
SCOPE OUT: [what NOT to do]
ACCEPTANCE CRITERIA:
  - [criterion 1]
  - [criterion 2]
OUTPUT FORMAT: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
OUTPUT PATH: [where to write the result, if any]
```

---

## Subagent Status Protocol

Every subagent must return exactly one of these statuses:

| Status               | Meaning                                                            | Orchestrator Action                                          |
| -------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------ |
| `DONE`               | Task complete, tests pass, ready for review                        | Proceed to two-stage review                                  |
| `DONE_WITH_CONCERNS` | Complete but flagged issues exist                                  | Proceed to review; concerns included in review input         |
| `NEEDS_CONTEXT`      | Blocked by missing information or clarification                    | See NEEDS_CONTEXT rule in Workflow Step 3                    |
| `BLOCKED`            | Cannot proceed due to architectural conflict or missing capability | Escalate to architect; do not re-dispatch without resolution |

**Never re-dispatch a BLOCKED task with only a prompt change.** BLOCKED means the task requires structural resolution, not more context.

**DONE_WITH_CONCERNS + critical overlap rule**: If a `DONE_WITH_CONCERNS` subagent report flags a concern that overlaps with a Critical finding in Stage 2 review, the combined signal is a blocking rejection. Re-dispatch with a correction brief addressing both the concern and the critical finding. Do not accept output when the same issue is flagged by both the subagent and Guardian.

---

## Failure Taxonomy

| Failure Mode                  | Symptom                                                               | Immediate Recovery                                                                         |
| ----------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `context_pollution`           | Subagent asks about topics from parent session it should not know     | Re-dispatch with fresh context only. Parent context was leaked.                            |
| `blocked_redispatch`          | Same task re-dispatched with only a prompt change after `BLOCKED`     | STOP. `BLOCKED` requires structural resolution, not more context. Escalate to architect.   |
| `missing_acceptance_criteria` | Subagent returns `DONE` but output cannot be verified                 | The dispatch was malformed. Redispatch with explicit acceptance criteria.                  |
| `artifact_path_unknown`       | Subagent produced output but orchestrator cannot find it              | Require designated output paths in every dispatch. Never accept implicit output locations. |
| `needs_context_loop`          | Same subagent returns `NEEDS_CONTEXT` more than once for the same gap | The gap is structural, not informational. Escalate to architect.                           |

---

## Workflow

### Step 1: Pre-Execution Verification

Before dispatching any subagent:

1. Load the approved plan (from `concise-planning` or `architect` spec).
2. Verify the plan passes the No Placeholders check (see `concise-planning` skill). If any step is vague, resolve it before dispatching.
3. Classify each task using the task-routing 6-check protocol. Confirm each task is appropriate for subagent execution.
4. Identify which tasks are `[SEQ]` (sequential) and which are `[PAR]` (parallel). Parallel tasks can be dispatched concurrently via `runSubagent`.

**Parallel failure rule**: If any branch in a parallel batch returns `BLOCKED`, do not cancel already-running branches, but do not dispatch any further parallel batches until the BLOCKED task is escalated and resolved. If a parallel branch returns `NEEDS_CONTEXT`, re-dispatch that branch independently; other branches continue unaffected.

**NEEDS_CONTEXT rule**: If a subagent returns `NEEDS_CONTEXT`: (1) identify the missing information, (2) re-dispatch once with that information added to the context package. If the same subagent returns `NEEDS_CONTEXT` a second time for the same gap, stop - escalate to architect; the gap is structural.

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
- **Gate**: If any spec item is NOT DONE, or if any spec item was modified in a way that changes its external interface, return value, or specified behavior, reject the output and re-dispatch to the implementer with a correction brief.
- If scope audit passes, proceed to Stage 2.

**Stage 2 - Code Quality Review** (did the subagent do it well?)

- Dispatch `guardian` with Phase 1 (Critical) and Phase 2 (Informational) review.
- Gate: Critical findings (e.g., security vulnerabilities, data-loss bugs, broken tests, or violations of project coding standards) block acceptance. Informational findings (e.g., style suggestions, minor inefficiencies, non-blocking improvements) are logged and deferred.
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
