---
name: concise-planning
description: "PIPELINE POSITION: sequence (step 3 of 4: brainstorming → architect → concise-planning → implementer). Produce an atomic, ordered checklist that turns an approved design into executable steps. Use AFTER intent is aligned (brainstorming) and AFTER the spec exists (architect, when applicable), or directly when the change is small and the approach is obvious. Output is a verb-first checklist with verification steps. DO NOT USE FOR: exploring whether or what to build (use brainstorming), designing module boundaries or API contracts (use architect), writing the code (use implementer), or delegating tasks across multiple subagents (use subagent-execution)."
argument-hint: "[task to plan]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: ["thinker"]
---

# Concise Planning

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani | Deps: thinker

> **Pipeline position**: **sequence** (3 of 4) - `brainstorming` -> `architect` -> **`concise-planning`** -> `implementer`. This skill produces a verb-first checklist. It runs AFTER design is approved and BEFORE code is written.

## Dependencies

Load the following via `read_file` before using this skill. Skills marked ★ have `disable-model-invocation: true` and cannot self-invoke - they **must** be loaded explicitly.

- `skills/thinker/SKILL.md` ★ - structured reasoning scaffold; confirms scope is well-understood before planning begins

## Goal

Turn a user request into a **single, actionable plan** with atomic steps.

## Workflow

### 1. Scan Context

- Read `README.md`, docs, and relevant code files.
- Identify constraints (language, frameworks, tests).

### 2. Minimal Interaction

- Ask **at most 1–2 questions** and only if truly blocking.
- Make reasonable assumptions for non-blocking unknowns.

### 3. Generate Plan

Use the following structure:

- **Approach**: 1-3 sentences on what and why.
- **Scope**: Bullet points for "In" and "Out".
- **Action Items**: A list of 6-10 atomic, ordered tasks (Verb-first).
- **Validation**: At least one item for testing.

## Plan Template

```markdown
# Plan

<High-level approach>

## Scope

- In:
- Out:

## Action Items

[ ] <Step 1: Discovery>
[ ] <Step 2: Implementation>
[ ] <Step 3: Implementation>
[ ] <Step 4: Validation/Testing>
[ ] <Step 5: Rollout/Commit>

## Open Questions

- <Question 1 (max 3)>
```

## Checklist Guidelines

- **Atomic**: Each step should be a single logical unit of work.
- **Verb-first**: "Add...", "Refactor...", "Verify...".
- **Concrete**: Name specific files or modules when possible.

## No Placeholders - Iron Law

> **Every action item must be immediately executable by the implementer without further clarification.**

The following patterns are **forbidden** anywhere in a plan:

| Forbidden Pattern                | Why                                | Replace With                                             |
| -------------------------------- | ---------------------------------- | -------------------------------------------------------- |
| `TBD` / `TODO`                   | Deferred decision, not a plan step | Resolve now or add to Open Questions                     |
| `implement the function`         | No file path, no signature         | `Add \`calculate_total()\` to \`src/billing/totals.py\`` |
| `similar to Task N`              | Relies on copy-paste reasoning     | Repeat the exact spec inline                             |
| `add appropriate error handling` | Vague, untestable                  | `Raise \`ValidationError\` if input is None or empty`    |
| `handle edge cases`              | Which cases?                       | List each edge case explicitly as its own step           |
| `update tests`                   | What tests? Which behavior?        | `Add test for empty cart in \`tests/test_checkout.py\``  |
| `refactor as needed`             | Not a step                         | Either commit to specific refactor or remove             |

**Enforcement:** Before finalizing the plan, scan every action item for these patterns. If any are found, the plan is not ready to hand off.

## Scope Check (Run Before Writing the Plan)

Before generating action items, answer these two questions:

1. **Does this plan span multiple independent subsystems?** If yes, flag it: "This work spans N subsystems. Recommend decomposing into N sub-plans for clarity." Proceed only if the user confirms a single combined plan.
2. **Is the scope well-understood?** If key unknowns exist (missing spec, no schema, ambiguous acceptance criteria), surface them as Open Questions before writing steps. Do not write speculative steps.

## Plan Self-Review (Run After Writing the Plan)

Before handing off or presenting the plan, verify:

1. **Spec coverage** - Does every requirement in the spec/request map to at least one action item?
2. **Placeholder scan** - Re-read every action item against the No Placeholders table above.
3. **Type consistency** - Do the deliverables of step N match the inputs expected by step N+1?
4. **Validation present** - Is there at least one testing/verification step?

If any check fails, fix the plan before presenting it.

## Parallel Decomposition

When generating action items, classify each step's dependency type:

- **[SEQ]**: Must wait for the previous step to complete (strict dependency).
- **[PAR]**: Can execute independently alongside other [PAR] items.

### When to Parallelize

- If 3+ items are [PAR], recommend parallel execution via subagents with a centralized aggregation step.
- Parallelizable tasks (independent research, separate module implementations, multi-file test writing) benefit from decomposition.
- Sequential tasks (multi-step reasoning chains, state-dependent pipelines) MUST NOT be parallelized. Splitting sequential context across agents degrades performance by 39-70%.

### Decomposition Rules

1. **Identify the dependency graph**: which steps produce outputs consumed by later steps?
2. **Group independent steps**: steps with no shared dependencies can run in parallel.
3. **Always include an aggregation step**: after parallel work, a single agent reviews and integrates all outputs.
4. **Never parallelize tool-heavy work**: if a sub-task needs 5+ tool calls, keep it in a single agent to preserve context budget.

### Example

```markdown
## Action Items

[SEQ] 1. Define API schema and data models
[PAR] 2a. Implement user endpoint (depends on: 1)
[PAR] 2b. Implement product endpoint (depends on: 1)
[PAR] 2c. Write shared test fixtures (depends on: 1)
[SEQ] 3. Integration test all endpoints (depends on: 2a, 2b, 2c)
[SEQ] 4. Run linter and type checker
```

## Feature Progress Tracker (Opt-In)

When a `.copilot/state/` directory exists in the target project, create a machine-readable progress tracker alongside the plan. This enables agents to update task status as they work, and retrospectives to measure velocity.

**When to create**: After the plan is finalized and approved. Generate one tracker per feature/plan.

**Procedure**:

1. Load the [feature_progress.json](./references/feature_progress.json) template.
2. Populate `feature` from the plan title, `branch` from current Git branch (or leave empty).
3. Map each Action Item to a `tasks[]` entry: `title` from the step text, `id` from step number, `depends_on` from `[SEQ]`/`[PAR]` annotations.
4. Set `status` to `"planning"` and compute `summary` counts.
5. Write to `.copilot/state/FEATURE_PROGRESS.json`.

**Field rules** (for any agent updating the tracker):

- Only modify `status`, `started`, `completed`, and `notes` on individual tasks.
- Recompute `summary` counts and `updated` date after every change.
- Valid task statuses: `not-started`, `in-progress`, `completed`, `blocked`.
- Valid top-level statuses: `planning`, `in-progress`, `review`, `completed`.
- Never rewrite `title`, `id`, or `depends_on` (owned by the planner).

**Skip signal**: If `.copilot/state/` does not exist and the task is a quick fix or one-off, skip tracker creation. Mention: "Feature tracker skipped (no `.copilot/state/` directory)."

## Outputs & Deliverables

- **Primary Output**: A single `plan.md` following the Plan Template
- **Secondary Output**: Open questions and assumptions list; `FEATURE_PROGRESS.json` (if opt-in)
- **Success Criteria**: Plan has atomic action items and at most 3 blocking questions
- **Quality Gate**: Plan reviewed and approved by requester or `implementer`

## Definition of Done

- [ ] Plan follows the template: Approach, Scope (In/Out), Action Items, Open Questions
- [ ] Action items are atomic, verb-first, and reference specific files/modules
- [ ] At least one validation/testing step is included
- [ ] Open questions limited to 3 or fewer blocking items
- [ ] Plan reviewed and approved by requester

## Constraints

- **Technical Constraints:** Do not implement code in this step; produce a plan only.
- **Scope Constraints:** Plans should be limited to the requested scope; avoid speculative features.
- **Governance Constraints:** Align plan with `project-context.md` and `SPEC.md` if present.

## Common Pitfalls

- **Over-Planning**: Creating 30+ atomic steps when 6-10 suffice. Keep it concise; details emerge during execution.
- **Vague Action Items**: "Implement feature" isn't actionable. "Add payment processing to checkout flow" is specific.
- **Missing Validation Steps**: A plan without testing/verification sets up for rework. Always include a validation checkpoint.
- **Ignoring Dependencies**: Listing steps in random order instead of respecting precedence. Steps must be executable in sequence.
- **Scope Creep**: Including "nice-to-haves" in the main plan. Use "Out of Scope" section to acknowledge but exclude them.
- **Assuming All Context**: Not reading existing code/docs leads to redundant or conflicting plans. Always scan context first.

## Integration Points

| Phase        | Input From                 | Output To            | Context                             |
| ------------ | -------------------------- | -------------------- | ----------------------------------- |
| Input        | User request + context     | Plan generation      | Scan code, README, and constraints  |
| Design Specs | `architect` specifications | Implementation steps | Use `SPEC.md` to guide atomic tasks |
| Execution    | Approved plan              | `implementer`        | Hand off actionable checklist       |
| Monitoring   | Progress updates           | Status tracking      | Adjust if blockers emerge           |

## References

Load these to calibrate plan structure and output format:

### Reference Documents

- [plan_template.md](./references/plan_template.md) - Reusable planning checklist template. Load at the start of every planning task to ensure the output follows the correct atomic-step format.
- [feature-plan.md](./references/feature-plan.md) - Worked feature plan example. Load when unsure of appropriate granularity or when the user needs a concrete example to validate the plan structure.
- [feature_progress.json](./references/feature_progress.json) - Feature progress tracker template. Load when creating a progress tracker for a plan (opt-in, when `.copilot/state/` exists).

### Scripts

- [format_checklist.py](./scripts/format_checklist.py) - Checklist formatter and validator. Converts a plain list of tasks into a structured, verb-led planning checklist with effort estimate, hygiene warnings (non-verb items, overly broad tasks), and Markdown output ready for user review.
