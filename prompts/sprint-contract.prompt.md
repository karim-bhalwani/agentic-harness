---
agent: architect
description: Negotiate a sprint contract between the builder and Guardian before coding starts. The Architect role-plays both perspectives to surface ambiguity early, when fixing it is free. Use after /design produces a spec and before the builder starts implementation.
argument-hint: "[feature name or spec reference]"
tools:
  - read
  - search
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

> **Retired on the Plan Phase path.** If a `.copilot/stories/US-{id}-PLAN.md` exists for this feature, that file already contains the GIVEN/WHEN/THEN acceptance criteria, out-of-scope list, and verification methods. Running this prompt afterwards re-validates the Architect's own output and burns tokens. Use this prompt only on the Build Direct path (Gate 0 selected `Build Direct`) or for legacy non-story work that bypasses the pipeline. The Plan Phase path replaces sprint-contract with `story-planner`.

Negotiate a sprint contract for: **${input:feature}**

**Before starting**, read:

- `.copilot/specs/SPEC.md` (or `.copilot/specs/SPEC-${input:feature}.md` if parallel workstreams)
- `.copilot/context/PROJECT_CONTEXT.md` (for project constraints and non-negotiables)

**Workflow**: Load `skills/architect/references/sprint-contract-template.md` via `read_file`. The template is the single source of truth for the three phases (Builder Proposes -> Guardian Reviews -> Finalised Contract), the review checklist, and the contract layout. Follow it; do not paraphrase it here.

**Output**: A finalised contract saved to `.copilot/specs/CONTRACT-${input:feature}.md`, alongside the spec. The builder references it during implementation; Guardian uses the acceptance criteria as the scope-audit checklist during review.

This is a design-time simulation - no code is written and no review is produced here. Doer/Judge separation is preserved.
