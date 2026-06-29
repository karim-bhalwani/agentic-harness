---
name: thinker
description: "Specialized in structured reasoning, mental scaffolding, and breaking down complex problems. Use at the start of every task to ensure deep, transparent, and auditable thinking before taking action. DO NOT USE FOR: brainstorming with the user (use brainstorming), implementation (use implementer), or producing final deliverable artifacts (complete documents, code, designs). Thinker produces intermediate outputs like reasoning scaffolds and action plans for handoff to implementer or architect."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: []
---

# Thinker Skill - Cognitive Reasoning & Scaffolding

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

## Overview

The Thinker skill provides a set of cognitive operations that prevent "leaping to conclusions" and ensure all variables are considered before execution.

## Cognitive Chain Protocol

Before executing any non-trivial task, run this chain internally. UNDERSTAND, EXTRACT, and HIGHLIGHT must be surfaced as visible markdown blocks when Workflow Integration is triggered. APPLY and VALIDATE may remain internal unless the task requires explicit auditability.

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

**When to apply:** Any task involving design decisions, multi-step execution, security-sensitive logic, debugging, or review. Skip only when the task has no design decisions, no cross-file impact, and no security or correctness risk - for example: a single-file typo fix, a local variable rename with no semantic change, or a comment update. When in doubt, apply the full chain.

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
- [ ] If the plan is not accepted, return to BACKTRACK, revise based on the rejection reason, and re-present. If acceptance cannot be determined (e.g., no other agent responds), flag the plan as unverified and surface it to the user before proceeding.

## Constraints

- **NO implementation.** This is purely for reasoning and planning.
- **NO direct filesystem edits.**
- **MANDATORY when the user request does not specify at least one of: success criteria, technical constraints, or target component. If any of these are missing, do not skip the chain.**

## Outputs & Deliverables

- **Primary Output**: Reasoning scaffolds, action plans, and validation checklists (markdown)
- **Secondary Output**: List of clarifying questions and prioritized assumptions
- **Success Criteria**: Action plan is unambiguous and passes the `verification-before-completion` pre-checks
- **Quality Gate**: `implementer` or `architect` acceptance of the plan before execution

## Additional Constraints

- **Governance Constraints:** Document assumptions and decisions in `decisions.md` when they change architecture or scope. If `decisions.md` does not exist, note in the action plan that it must be created before handoff, and include the decision log entry as a block in the thinker output so it is not lost.

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
