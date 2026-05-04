---
name: story-planner
description: "Houses scaffold_plan.py, scaffold_validation.py, verify_plan.py, and verify_validation.py used by the story-planner agent (prompts/story-planner.agent.md) to generate and validate per-story planning artifacts (US-NN-PLAN.md and US-NN-VALIDATION.md). This skill is not directly invocable; it is a script-housing skill that the story-planner agent shells out to. DO NOT USE FOR: per-story implementation planning itself (that is the story-planner agent in prompts/), backlog decomposition (use story-master agent), code review (use guardian), or implementation (use senior-developer, data-engineer, or ai-engineer)."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: []
---

# story-planner

Script-housing skill for the story-planner agent. The story-planner agent (defined in
`prompts/story-planner.agent.md`) takes a single story from `STORIES.md`, scans the live
codebase for patterns, and produces a per-story implementation plan and validation map. This
skill provides the scaffolding and verification scripts that enforce the §3.2 and §3.4 schemas.

## Scripts

| Script                                                               | Purpose                                                                                                                                                                             |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [./scripts/scaffold_plan.py](./scripts/scaffold_plan.py)             | Generates a `US-NN-PLAN.md` skeleton with all required sections as TODO markers. Accepts `--story-id US-XX`.                                                                        |
| [./scripts/scaffold_validation.py](./scripts/scaffold_validation.py) | Generates a `US-NN-VALIDATION.md` skeleton with empty Task Validation Matrix, AC Coverage Map, and Plan-Checker History table. Accepts `--story-id US-XX`.                          |
| [./scripts/verify_plan.py](./scripts/verify_plan.py)                 | Validates a `US-NN-PLAN.md` file against the §3.2 schema. Checks required sections, AC rows, task format, validate commands, and pattern references. Exits 0 on pass, 1 on failure. |
| [./scripts/verify_validation.py](./scripts/verify_validation.py)     | Validates a `US-NN-VALIDATION.md` file against the §3.4 schema. Checks header, table columns, enum values, and Plan-Checker History. Exits 0 on pass, 1 on failure.                 |
