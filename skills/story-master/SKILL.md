---
name: story-master
description: "Houses the scaffold_stories.py and verify_stories.py scripts used by the story-master agent (prompts/story-master.agent.md) to generate and validate STORIES.md backlog files. This skill is not directly invocable; it is a script-housing skill that the story-master agent shells out to. This skill provides only scaffolding and verification functionality; backlog decomposition is handled by the story-master agent, code review by guardian, and implementation planning by story-planner agent."
user-invocable: false
disable-model-invocation: true
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: []
---

# story-master

Script-housing skill for the story-master agent. The story-master agent (defined in
`prompts/story-master.agent.md`) reads an approved `SPEC.md`, decomposes it into a structured
user-story backlog, and writes `.copilot/stories/STORIES.md`. This skill provides the scaffolding
and verification scripts that enforce the §3.1 STORIES.md schema and prevent silent schema drift
from breaking the downstream `close-story` verification step.

## Scripts

| Script                                                         | Purpose                                                                                                                                                                                                                                                                       |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [./scripts/scaffold_stories.py](./scripts/scaffold_stories.py) | Generates a `.copilot/stories/STORIES.md` skeleton with the summary table header, execution wave placeholder sections, and coupled-pairs table. story-master fills in the rows.                                                                                               |
| [./scripts/verify_stories.py](./scripts/verify_stories.py)     | Validates a `STORIES.md` file against the §3.1 schema through modular checks: (1) column set validation, (2) enum values validation, (3) dependency references validation, (4) H3 detail sections validation, (5) wave consistency validation. Exits 0 on pass, 1 on failure. |
| [./scripts/stories_lock.py](./scripts/stories_lock.py)         | Provides atomic read-modify-write access to `STORIES.md` via exclusive file locking. Commands: `acquire` (obtains lock), `release --force` (releases lock). Used by close-story to prevent concurrent stamps.                                                                 |
| [./scripts/failure_catalog.py](./scripts/failure_catalog.py)   | Catalogs known failure modes for story lifecycle operations (missing plan, missing report, lock contention, invalid story ID). Maps each failure to a remediation instruction for the calling agent.                                                                          |

## Related Skills

- [story-planner](../story-planner/SKILL.md) - After STORIES.md is approved at Gate 1, story-planner picks up each story to produce per-story implementation plans
