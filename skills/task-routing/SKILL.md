---
name: task-routing
description: "Multi-agent delegation protocol with sequentiality, decomposability, and cost-benefit checks derived from DeepMind/MIT research. Load when deciding whether to delegate a task to another agent or handle it yourself. Includes coordination anti-patterns that degrade agent system performance. DO NOT USE FOR: executing delegated tasks (use subagent-execution), creating implementation plans (use concise-planning), actual code work, or single-step tasks that don't need delegation."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  source: "Extracted from copilot-instruction.instructions.md Section 9 to reduce auto-loaded context"
  dependencies: []
---

# Task Routing Protocol

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

## When to Load This Skill

Load this skill before delegating any task to another agent. If you are handling the task yourself, you do not need this.

## Quick-Fix Fast Lane

Before running the 6 checks, assess whether the task qualifies for the fast lane. Fast-lane tasks bypass all delegation checks and the full pipeline:

**All conditions must be true:**

- Single file change (or 2-3 files for a rename ripple)
- Under ~20 lines changed
- No new dependencies introduced
- No architectural or API contract changes
- Correct outcome is obvious and easily verifiable
- Not a security-critical code path

If all conditions are met, use `/quick-fix` directly. No spec, no Guardian review, no handoff chain. If any condition fails, proceed to the standard 6-check protocol below.

---

## The Six Checks

Before delegating to another agent, evaluate the task against these criteria (derived from Google/DeepMind/MIT agent scaling research).

**Decision summary - use this to navigate early exits:**

| Check                | YES outcome                                   | NO outcome          |
| -------------------- | --------------------------------------------- | ------------------- |
| 1. Sequentiality     | STOP - Single Agent                           | Proceed to Check 2  |
| 2. Decomposability   | Proceed to Check 3                            | STOP - Single Agent |
| 3. Domain Complexity | High → STOP - Single Agent; Low/Med → Proceed | -                   |
| 4. Competence        | STOP - Single Agent                           | Delegate            |
| 5. Tool Density      | STOP - Single Agent                           | Proceed to Check 6  |
| 6. Cost-Benefit      | STOP - Single Agent                           | Delegate            |

### 1. Sequentiality Check

Does step N depend on step N-1's output?

- **YES**: **STOP - Single Agent.** Multi-agent coordination degrades sequential reasoning tasks by 39-70%.
- **NO**: Proceed to Check 2.

### 2. Decomposability Check

Can the task be split into independent sub-problems that don't share mutable state?

- **YES** (e.g., analyze revenue + analyze costs + analyze market independently): Consider parallel specialist dispatch with centralized aggregation. Centralized coordination yields up to +80.9% on decomposable tasks. Proceed to Check 3.
- **NO** (e.g., each step modifies shared state the next step reads): **STOP - Single Agent.** Artificial decomposition of inherently sequential work wastes token budget on coordination instead of reasoning.

### 3. Domain Complexity Check

Estimate task complexity on a Low/Medium/High scale.

- **Low** (structured output, clear subtask boundaries, e.g., generate config, write CRUD): Multi-agent overhead is tolerable; delegate if specialist adds value.
- **Medium** (moderate decomposability, some sequential dependencies, e.g., feature implementation, pipeline design): Delegate only when the specialist's domain expertise clearly exceeds yours.
- **High** (strict sequential dependencies, dynamic state evolution, e.g., debugging production failures, stateful migration, multi-step constraint satisfaction): **STOP - Single Agent.** Coordination overhead consumes reasoning capacity at high complexity.

### 4. Competence Check

Is this task within your declared expertise?

- **YES** - if you estimate your confidence at >50%: **STOP - Single Agent.** (Research basis: accuracy gains from delegation plateau once a single agent exceeds ~45% task baseline accuracy.)
- **NO**: Delegate to the specialist agent.

### 5. Tool Density Check

Does the sub-task require 5+ distinct tool calls?

- **YES**: **STOP - Single Agent.** Coordination overhead consumes context budget needed for tool use.
- **NO**: Multi-agent may help if the task is parallelizable. Proceed to Check 6.

### 6. Cost-Benefit Check

Will delegation increase token cost >2x for less than a 10% likely improvement in output quality or task accuracy?

- **YES**: **STOP - Single Agent.**
- **NO**: Delegate if the specialist's domain expertise justifies the overhead.

### Default Posture

**Prefer self-sufficiency.** Delegation is a cost (context loss, token overhead, error amplification risk), not a free upgrade.

**Conflicting check results:** If checks produce conflicting recommendations (e.g., sequentiality check favors single agent but competence check favors delegation), the single-agent recommendation takes precedence. Sequentiality (Check 1) and Tool Density (Check 5) checks override all others when they fire.

## Coordination Anti-Patterns

These patterns are proven to degrade agent system performance. Avoid them.

| Anti-Pattern                                              | Why It Fails                                   | Better Alternative                                     |
| --------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------ |
| **Independent swarm** (parallel agents, no communication) | Errors amplify 17.2x unchecked                 | Centralized topology with manager reviewing outputs    |
| **Multi-agent for sequential tasks**                      | Splits reasoning chain, fragments context      | Single agent with full context                         |
| **Delegation for in-expertise tasks**                     | Adds 2-6x token cost for no accuracy gain      | Handle internally, note if close to boundary           |
| **Peer-to-peer debate for precision tasks**               | Error cascades without central filter          | Manager-worker topology with Guardian gate             |
| **Tool-heavy sub-tasks delegated to teams**               | Coordination chat consumes tool budget         | Single agent with focused tool set                     |
| **Auto-retry without state transition**                   | Compounds errors in a loop                     | FSM with explicit recovery state and 3-strike limit    |
| **Unbounded context forwarding**                          | Dumps irrelevant history into downstream agent | Compiled context: only pass decisions, schemas, errors |

## Context Isolation

See `~/.copilot/skills/subagent-execution/SKILL.md` section "Context Mode: Fresh vs Inherited" for the canonical rules. Summary: default to fresh context (task spec, file paths, acceptance criteria only); use inherited context only when explicitly justified (continuation, prior-attempt awareness).

For structured multi-task execution with two-stage review, load `~/.copilot/skills/subagent-execution/SKILL.md`.

## PLAN-phase Agent Routing (v8.0)

The Plan Phase introduces three new agents and one new prompt that overlap superficially with existing pipeline entries. Use this section to disambiguate.

### story-planner vs feature-plan.prompt.md

- `story-planner.agent.md` - A `SPEC.md` and `STORIES.md` exist; a story ID is supplied (or read from `.active-story` / `STORY_ID`). Output: `US-{id}-PLAN.md` + `US-{id}-VALIDATION.md` with plan-checker history. **DO NOT USE FOR:** ad-hoc one-off tasks with no SPEC.
- `feature-plan.prompt.md` - No SPEC, no STORIES.md, no story ID. Ad-hoc fast-lane planning for one-off tasks outside the pipeline. **DO NOT USE FOR:** stories that are part of an approved backlog (use story-planner).

### story-master vs architect

- `architect.agent.md` - Produces `SPEC.md`. Designs module boundaries, API contracts, data models. Decides `Scope: HOLD/EXPANSION/REDUCTION`. **DO NOT USE FOR:** breaking an approved SPEC into stories.
- `story-master.agent.md` - Consumes an approved `SPEC.md` and produces `STORIES.md` with dependency graph, waves, and risk tags. Does not invent requirements; every story traces to a SPEC section. **DO NOT USE FOR:** redesigning the SPEC (that is back-pressure to architect via the `Hand off to Architect (Story Scope Problem)` handoff in story-planner).

### close-story vs release-manager

- `release-manager.agent.md` - Owns the path from approved code to production: CI/CD, deployment, changelogs, rollback runbooks. **DO NOT USE FOR:** stamping a single story's backlog row to done.
- `close-story.agent.md` - Verify-and-stamp closer for one shipped story. Checks plan tasks ticked, VALIDATION.md present, report present with PASS, then updates STORIES.md row under file lock and advances `.active-story`. Does NOT author the report and does NOT generate release notes. **DO NOT USE FOR:** writing the implementation report (BUILD agent owns that) or releasing software (release-manager owns that).

### Gate 0 routing decision

The Architect now presents four handoff buttons after writing `SPEC.md`. Three are `Build Direct` (Senior Dev / Data Eng / AI Eng) which read SPEC.md directly with no story decomposition; one is `Approve: Plan Phase` which routes to story-master. The Architect's recommendation guidance table (small `Scope: HOLD` -> Build Direct, multi-deliverable or `Scope: EXPANSION/REDUCTION` -> Plan Phase) is advisory; the human's click is the final decision. The Architect records the decision in `SESSION_STATE.md`.

### Data Analyst routing in v8.0

The Architect handoff to `data-analyst` was removed (RD-1). Data Analyst remains a utility agent reachable via four retained paths: `@data-analyst` mention, `/sql-query` slash command, Guardian rework handoff for SQL-heavy code, and peer delegation from Senior Developer / Data Engineer per the 6-check protocol above. **DO NOT** invent an Architect-to-Data-Analyst handoff in v8.0 designs.

### Analyst story close path (Owner: data-analyst in STORIES.md)

When story-master tags a story `Type: Technical, Owner: data-analyst`, the story bypasses the full BUILD-phase machinery (no story-planner, no PLAN.md, no VALIDATION.md). It is NOT an unverified path -- it has a defined four-step close sequence:

1. Human invokes `@data-analyst` with the story context.
2. `@data-analyst` writes the SQL deliverable.
3. `@guardian` reviews the SQL (injection risks, performance, output correctness) and writes approval to `.copilot/artifacts/review-report.md`. Use the Guardian SQL rework handoff for this step.
4. Human invokes `close-story`. It detects `Owner: data-analyst`, skips PLAN.md and VALIDATION.md checks, verifies the Guardian review report is present and PASS-only, then stamps `STORIES.md` under file lock.

Summary: Guardian review is mandatory for analyst stories. The Guardian review report (`review-report.md`) is the quality gate that replaces the implementation report + VALIDATION.md on this path. `close-story` enforces this gate before stamping.
