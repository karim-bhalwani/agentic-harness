---
agent: architect
description: Negotiate a sprint contract between the builder and Guardian before coding starts. The Architect role-plays both perspectives to surface ambiguity early, when fixing it is free. Use after /design produces a spec and before the builder starts implementation.
argument-hint: "[feature name or spec reference]"
tools:
  - read
  - search
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

> **When to use this prompt:**
>
> 1. Check if `.copilot/stories/US-{id}-PLAN.md` exists for this feature. If yes, that file already contains acceptance criteria and verification methods - skip this prompt.
> 2. Use this prompt only if:
>    - Gate 0 selected `Build Direct` (Build Direct path), OR
>    - Work bypasses the pipeline (legacy non-story work)
> 3. Do not use for features on the Plan Phase path (those use `story-planner` instead).
>
> **Note:** This is design-time simulation only. Do not use for re-validation after initial contract creation, as it burns tokens without adding value.

Negotiate a sprint contract for: **${input:feature}**

**Before starting**, read:

- `.copilot/specs/SPEC.md` (or `.copilot/specs/SPEC-${input:feature}.md` if parallel workstreams)
- `.copilot/context/PROJECT_CONTEXT.md` (for project constraints and non-negotiables)

**Workflow**: Load `skills/architect/references/sprint-contract-template.md` via `read_file`. The template is the single source of truth for the three phases (Builder Proposes -> Guardian Reviews -> Finalised Contract), the review checklist, and the contract layout. Follow it; do not paraphrase it here.

**Output**: A finalised contract saved to `.copilot/specs/CONTRACT-${input:feature}.md`, alongside the spec. The builder references it during implementation; Guardian uses the acceptance criteria as the scope-audit checklist during review.

This is a design-time simulation - no code is written and no review is produced here. Doer/Judge separation is preserved.
