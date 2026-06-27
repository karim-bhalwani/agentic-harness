---
agent: architect
description: Generate an atomic, reviewable implementation plan for a feature or task. Uses the concise-planning skill layered on thinker reasoning. Produces a checklist the user can approve before any code is written. Use when starting a non-trivial task and you want a plan first.
argument-hint: "[feature, task, or user story to plan]"
tools:
  - read
  - search
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Produce an implementation plan for: **${input:task}**

**Pre-planning validation**:

If the task description is incomplete, ambiguous, or lacks sufficient detail, ask clarifying questions before proceeding. Examples of clarifications needed:

- Unclear scope or acceptance criteria
- Missing technical constraints or dependencies
- Unspecified user personas or use cases
- No defined success metrics or validation criteria

Once the user answers all clarifying questions, summarize the confirmed scope and constraints in a single paragraph, then proceed to the Context scan and planning steps below.

**Context to scan before planning**:

- Existing codebase patterns, file structure, and naming conventions
- Tech stack and available libraries (do NOT assume a library is available)
- Any constraints or acceptance criteria the user mentioned

**Handling complex tasks**:

If the task involves multiple subtasks or cross-functional dependencies:

- Break down the task into logical subtasks
- Identify and explicitly specify dependencies between subtasks
- Group related work items and note any sequential or parallel execution paths
- Call out any blocking dependencies or integration points

**Workflow**: Load `~/.copilot/skills/concise-planning/SKILL.md` via `read_file` and follow its Workflow + Plan Template. The skill is the single source of truth for the output format (Approach / Scope / Action Items / Validation), atomic-step granularity, and assumption-handling rules. If `~/.copilot/skills/concise-planning/SKILL.md` cannot be loaded, stop and notify the user: "Unable to load the planning skill file at ~/.copilot/skills/concise-planning/SKILL.md. Please verify the path and retry, or provide the skill contents directly." Do not proceed with planning until the file is available or the user confirms an alternative format. If the user confirms an alternative format, use the following inline fallback template (the external skill file takes precedence when available):

```
## Approach
[One paragraph describing the chosen strategy and rationale]

## Scope
- In: [what is included]
- Out: [what is explicitly excluded]
- Assumptions: [list each assumption]

## Action Items
- [ ] Step 1 - [verb-first atomic action, single responsibility]
- [ ] Step 2 - ...
(Each step must be independently executable and verifiable)

## Validation
- [ ] [How to confirm each step succeeded]
```

Do NOT write any code. Wait for explicit approval before proceeding to implementation.
