---
agent: architect
description: Generate an atomic, reviewable implementation plan for a feature or task. Uses the concise-planning skill layered on thinker reasoning. Produces a checklist the user can approve before any code is written. Use when starting a non-trivial task and you want a plan first.
argument-hint: "[feature, task, or user story to plan]"
tools:
  - read
  - search
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Produce an implementation plan for: **${input:task}**

**Context to scan before planning**:

- Existing codebase patterns, file structure, and naming conventions
- Tech stack and available libraries (do NOT assume a library is available)
- Any constraints or acceptance criteria the user mentioned

**Workflow**: Load `skills/concise-planning/SKILL.md` via `read_file` and follow its Workflow + Plan Template. The skill is the single source of truth for the output format (Approach / Scope / Action Items / Validation), atomic-step granularity, and assumption-handling rules.

Do NOT write any code. Wait for explicit approval before proceeding to implementation.
