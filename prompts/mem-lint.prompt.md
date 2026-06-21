---
agent: ai-engineer
description: Run health checks on the project's knowledge mem. Auto-fixes broken links and index gaps, reports contradictions, orphan pages, stale content, and missing concept pages. Use periodically or after major changes to keep the mem trustworthy.
argument-hint: "[scope: 'all', 'links', 'index', or specific topic directory]"
tools:
  - read
  - search
  - edit
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Lint the project mem. Scope: **${input:scope}** (valid values: `all`, `links`, `index`, or a specific topic directory, e.g., `topics/AI/` or `topics/ML/`)

**Validation**: If the scope value is invalid or unsupported, respond with: "Invalid scope provided. Please use one of the valid values: `all`, `links`, `index`, or a specific topic directory."

**Workflow**: Load `skills/llm-mem/SKILL.md` via `read_file`. If `skills/llm-mem/SKILL.md` cannot be loaded, respond with: "Skill file not found. Ensure the file exists and is accessible." The skill is the single source of truth for the lint workflow (deterministic auto-fix checks, heuristic report-only checks, log-append rules) and for the Mem Health Report format. Follow it; do not paraphrase here.

If `llmmem/mem/index.md` does not exist, stop and tell the user: "No mem found. Run `/mem-ingest` first."

**Output**: A Mem Health Report with the count of issues auto-fixed, a table of heuristic findings with severity, and suggested next actions.
