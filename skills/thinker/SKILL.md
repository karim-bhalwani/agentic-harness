---
name: thinker
description: "Specialized in structured reasoning, mental scaffolding, and breaking down complex problems. Use at the start of every task to ensure deep, transparent, and auditable thinking before taking action. DO NOT USE FOR: generating plans or checklists (use concise-planning), brainstorming with the user (use brainstorming), implementation (use implementer), or producing any output artifact directly."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code, Claude Code"
metadata:
  version: "7.0"
  updated: "2026-04-12"
  dependencies: []
---

# Thinker Skill - Cognitive Reasoning & Scaffolding

> Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani |

## Overview

The Thinker skill provides a set of cognitive operations that prevent "leaping to conclusions" and ensure all variables are considered before execution.

## Cognitive Chain Protocol

Before executing any non-trivial task, run this chain internally. Not every step requires visible output, but every step must happen mentally before acting.

```text
UNDERSTAND ─► EXTRACT ─► HIGHLIGHT ─► APPLY ─► VALIDATE
    │             │            │           │          │
  What is the   What context  What are    Do the    Did the output
  real problem?  do I need?   the risks   work.     meet the
  What are the   Pull from    and         Execute   requirements?
  constraints?   project      priorities? step by   Check against
  Success        files,       Surface     step.     constraints
  criteria?      specs, and   patterns             and acceptance
                 prior work.  to follow.            criteria.
```

**When to apply:** Any task involving design decisions, multi-step execution, security-sensitive logic, debugging, or review. Skip for trivial/mechanical tasks (rename, typo fix, config change).

**If VALIDATE fails:** Enter BACKTRACK. Step back, re-examine assumptions, propose a new path or escalate to the user.

## Reasoning Scaffolds

### 1. UNDERSTAND

- Identify the core problem.
- Define domain requirements (explicit and implicit).
- Establish objective success criteria (acceptance criteria).

### 2. EXTRACT

- Pull context from project standards (tech stack, architecture).
- Gather relevant outputs from previous steps or agents.
- Identify specific file paths, API contracts, and data models involved.

### 3. HIGHLIGHT

- Surface critical patterns that must be followed.
- Identify integration points and potential risks (e.g., edge cases).
- Establish a clear Priority Order of operations.

### 4. APPLY

- Select the appropriate reasoning technique or design pattern.
- Plan the step-by-step execution.
- Maintain a log of tactical decisions made during execution.

### 5. VALIDATE

- Run a self-checklist against constraints.
- Verify adherence to project rules (e.g., security, type safety).
- Perform a quality check on outputs before finalizing.

### 6. BACKTRACK

- If stuck or if validation fails, step back.
- Analyze assumptions and identify where they went wrong.
- Propose new resolution paths or escalate questions.

## Workflow Integration

Whenever a complex task is received:

1. **Initialize**: Call the `thinker` skill.
2. **Scaffold**: Output a `## UNDERSTAND` block, followed by `EXTRACT` and `HIGHLIGHT`.
3. **Transition**: Hand off the "Action Plan" to the `implementer` or `architect`.

## Definition of Done

- [ ] UNDERSTAND, EXTRACT, and HIGHLIGHT blocks are complete
- [ ] Action plan is unambiguous with ordered steps
- [ ] All assumptions are documented and flagged by confidence level
- [ ] Constraints (security, performance, scope) are explicitly listed
- [ ] Plan accepted by `implementer` or `architect` before execution

## Constraints

- **NO implementation.** This is purely for reasoning and planning.
- **NO direct filesystem edits.**
- **MANDATORY for ambiguous requests.**

## Outputs & Deliverables

- **Primary Output**: Reasoning scaffolds, action plans, and validation checklists (markdown)
- **Secondary Output**: List of clarifying questions and prioritized assumptions
- **Success Criteria**: Action plan is unambiguous and passes the `verification-before-completion` pre-checks
- **Quality Gate**: `implementer` or `architect` acceptance of the plan before execution

## Additional Constraints

- **Governance Constraints:** Document assumptions and decisions in `decisions.md` when they change architecture or scope

## Common Pitfalls

- **Skipping UNDERSTAND**: Jumping straight to solutions misses the real problem. Always spend time understanding before planning.
- **Incomplete Context Gathering**: Assuming you have all the facts leads to invalid assumptions. Always explicitly pull relevant context.
- **Ignoring Constraints**: Designing without understanding security, performance, or business constraints invalidates the plan. Ask constraints early.
- **Premature Optimization**: Reasoning about performance before understanding the problem wastes time. Optimize after measurement.
- **Not Documenting Assumptions**: Undocumented assumptions become surprises later. Make assumptions explicit and validate them.
- **Skipping Validation**: "It seems right" is not validation. Run the checklist; verify constraints before handing off.

## Integration Points

| Phase         | Input From                | Output To                    | Context                                     |
| ------------- | ------------------------- | ---------------------------- | ------------------------------------------- |
| Problem Entry | User request              | Reasoning scaffolds          | UNDERSTAND, EXTRACT, HIGHLIGHT              |
| Planning      | Analyzed request          | `architect` or `implementer` | Provide validated action plan               |
| Decision Log  | Key assumptions/decisions | `context-engineer`           | Document decisions in `decisions.md`        |
| Validation    | Draft plan                | Pre-flight checklist         | Verify against constraints before execution |

## References

Load when scaffolding reasoning documents and structured briefs:

- [brief.md](./references/brief.md) - Problem brief template. Load when the task requires a formal thought document - captures problem statement, assumptions, constraints, and action plan in a single structured artifact.
