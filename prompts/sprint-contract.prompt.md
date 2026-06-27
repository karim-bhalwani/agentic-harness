---
agent: architect
description: Negotiate a sprint contract between the builder and Guardian before coding starts. The Architect role-plays both perspectives to surface ambiguity early, when fixing it is free. Use after /design produces a spec and before the builder starts implementation.
argument-hint: "[feature name or spec reference]"
tools:
  - read
  - search
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

> **Routing note (for humans):** Use this prompt only if Gate 0 selected `Build Direct`, or work bypasses the pipeline (legacy non-story work). Do not use for features on the Plan Phase path (those use `story-planner` instead). This is design-time simulation only - do not use for re-validation after initial contract creation.

**Pre-flight check (model executes):** Before proceeding, use `read` to check whether `.copilot/stories/US-{id}-PLAN.md` exists. If it does, respond: "A PLAN.md already exists for this feature. This prompt is not needed." and stop.

If `${input:feature}` is empty or contains path-unsafe characters (e.g. `/`, `\`, `..`), stop and respond: "Please provide a valid feature name with no path separators or special characters."

Negotiate a sprint contract for: **${input:feature}**

**Before starting**, read the following files in order:

1. **Spec file**: Read `.copilot/specs/SPEC-${input:feature}.md` if it exists; otherwise read `.copilot/specs/SPEC.md`. If neither exists, stop and ask the user to provide the spec file path before proceeding.
2. **Project context**: Read `.copilot/context/PROJECT_CONTEXT.md` for project constraints and non-negotiables. If this file does not exist, proceed but explicitly note in the contract that no project-level constraints were available and the contract should be reviewed against them before use.
3. **Workflow template**: Load `~/.copilot/skills/architect/references/sprint-contract-template.md` via `read_file`. If this file cannot be read, stop immediately and respond: "Sprint contract template not found at `~/.copilot/skills/architect/references/sprint-contract-template.md`. Please ensure the file exists before running this prompt." Do not attempt to infer or reconstruct the template.

The template is the single source of truth for the three phases (Builder Proposes -> Guardian Reviews -> Finalised Contract), the review checklist, and the contract layout. Follow it. The pre-reading steps above (spec and project context) take precedence over any conflicting pre-reading instructions in the template; all other template instructions apply as written.

**Output**: A finalised contract saved to `.copilot/specs/CONTRACT-${input:feature}.md`, alongside the spec. The builder references it during implementation; Guardian uses the acceptance criteria as the scope-audit checklist during review.

This is a design-time simulation - no code is written and no review is produced here. Doer/Judge separation is preserved.
