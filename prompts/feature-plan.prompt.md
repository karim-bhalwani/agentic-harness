---
agent: architect
description: Generate an atomic, reviewable implementation plan for a feature or task. Uses the concise-planning skill layered on thinker reasoning. Produces a checklist the user can approve before any code is written. Use when starting a non-trivial task and you want a plan first.
argument-hint: "[feature, task, or user story to plan]"
tools:
  - read
  - search
version: "7.0"
updated: "2026-04-12"
---

Use the `concise-planning` skill to produce an implementation plan for: **${input:task}**

**Context to scan before planning**:

- Existing codebase patterns, file structure, and naming conventions
- Tech stack and available libraries (do NOT assume a library is available)
- Any constraints or acceptance criteria the user mentioned

**Output format** (strict):

1. **Goal** - One sentence stating what done looks like from the user's perspective
2. **Assumptions** - Numbered list of inferred decisions (flag if any are risky)
3. **Plan** - Atomic, sequenced checklist. Each item:
   - Starts with a verb (Create, Update, Add, Remove, Refactor, Test)
   - Is small enough to verify independently
   - References specific files or modules where known
4. **Risks** - Up to 3 items that could derail execution
5. **Estimated steps** - rough count (e.g., "12 steps, ~2h")

Do NOT write any code. Wait for explicit approval before proceeding to implementation.

