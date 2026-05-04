---
agent: ai-engineer
description: Run health checks on the project's knowledge mem. Auto-fixes broken links and index gaps, reports contradictions, orphan pages, stale content, and missing concept pages. Use periodically or after major changes to keep the mem trustworthy.
argument-hint: "[scope: 'all', 'links', 'index', or specific topic directory]"
tools:
  - read
  - search
  - edit
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Lint the project mem. Scope: **${input:scope}**

**Workflow**: Load `skills/llm-mem/SKILL.md` via `read_file`. The skill is the single source of truth for the lint workflow (deterministic auto-fix checks, heuristic report-only checks, log-append rules) and for the Mem Health Report format. Follow it; do not paraphrase here.

If `llmmem/mem/index.md` does not exist, stop and tell the user: "No mem found. Run `/mem-ingest` first."

**Output**: A Mem Health Report with the count of issues auto-fixed, a table of heuristic findings with severity, and suggested next actions.
