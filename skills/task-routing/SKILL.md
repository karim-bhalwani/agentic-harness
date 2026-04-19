---
name: task-routing
description: "Multi-agent delegation protocol with sequentiality, decomposability, and cost-benefit checks derived from DeepMind/MIT research. Load when deciding whether to delegate a task to another agent or handle it yourself. Includes coordination anti-patterns that degrade agent system performance. DO NOT USE FOR: executing delegated tasks (use subagent-execution), creating implementation plans (use concise-planning), actual code work, or single-step tasks that don't need delegation."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code, Claude Code"
metadata:
  version: "7.0"
  updated: "2026-04-12"
  source: "Extracted from copilot-instruction.instructions.md §9 to reduce auto-loaded context"
  dependencies: []
---

# Task Routing Protocol

> Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani | Source: [arXiv:2512.08296v2](https://arxiv.org/abs/2512.08296)

## When to Load This Skill

Load this skill before delegating any task to another agent. If you are handling the task yourself, you do not need this.

## The Six Checks

Before delegating to another agent, evaluate the task against these criteria (derived from Google/DeepMind/MIT agent scaling research):

### 1. Sequentiality Check

Does step N depend on step N-1's output?

- **YES**: Single agent. Multi-agent coordination degrades sequential reasoning tasks by 39-70%.
- **NO**: Proceed to decomposability check.

### 2. Decomposability Check

Can the task be split into independent sub-problems that don't share mutable state?

- **YES** (e.g., analyze revenue + analyze costs + analyze market independently): Consider parallel specialist dispatch with centralized aggregation. Centralized coordination yields up to +80.9% on decomposable tasks.
- **NO** (e.g., each step modifies shared state the next step reads): Single agent. Artificial decomposition of inherently sequential work wastes token budget on coordination instead of reasoning.

### 3. Domain Complexity Check

Estimate task complexity on a Low/Medium/High scale.

- **Low** (structured output, clear subtask boundaries, e.g., generate config, write CRUD): Multi-agent overhead is tolerable; delegate if specialist adds value.
- **Medium** (moderate decomposability, some sequential dependencies, e.g., feature implementation, pipeline design): Delegate only when the specialist's domain expertise clearly exceeds yours.
- **High** (strict sequential dependencies, dynamic state evolution, e.g., debugging production failures, stateful migration, multi-step constraint satisfaction): Single agent strongly preferred. Coordination overhead consumes reasoning capacity at high complexity.

### 4. Competence Check

Is this task within your declared expertise?

- **YES** at >50% confidence: Handle it yourself. Capability saturation means delegation adds overhead without accuracy gain once a single agent exceeds ~45% baseline.
- **NO**: Delegate to the specialist agent.

### 5. Tool Density Check

Does the sub-task require 5+ distinct tool calls?

- **YES**: Single agent. Coordination overhead consumes context budget needed for tool use.
- **NO**: Multi-agent may help if the task is parallelizable.

### 6. Cost-Benefit Check

Will delegation increase token cost >2x for <10% likely improvement?

- **YES**: Single agent.
- **NO**: Delegate if the specialist's domain expertise justifies the overhead.

### Default Posture

**Prefer self-sufficiency.** Delegation is a cost (context loss, token overhead, error amplification risk), not a free upgrade.

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

## Context Isolation Principle

When delegating to any subagent, construct what they need - do not forward session history:

- **Pass**: the task spec, relevant file paths, acceptance criteria, and any decisions already made
- **Never pass**: the full conversation history, your reasoning steps, or context unrelated to the task
- **Why**: context pollution causes the subagent to reason about your session instead of their task; it also wastes your own context budget on forwarding instead of coordination

For structured multi-task execution with two-stage review, load `skills/subagent-execution/SKILL.md`.
