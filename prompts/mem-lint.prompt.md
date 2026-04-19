---
agent: senior-developer
description: Run health checks on the project's knowledge mem. Auto-fixes broken links and index gaps. Reports contradictions, orphan pages, stale content, and missing concept pages. Use periodically or after major changes to keep the mem trustworthy.
argument-hint: "[scope: 'all', 'links', 'index', or specific topic directory]"
tools:
  - read
  - search
  - edit
version: "7.0"
updated: "2026-04-12"
---

Load `skills/llm-mem/SKILL.md` via `read_file` before proceeding.

Lint the project mem. Scope: **${input:scope}**

## Process

1. **Verify mem exists** - If `llmmem/mem/index.md` does not exist, report "No mem found. Run `/mem-ingest` first."
2. **Deterministic checks** (auto-fix):
   - Index consistency: files vs. index entries
   - Internal links: broken paths in mem articles
   - Raw references: broken links to llmmem/raw/ files
   - See Also: missing or dead cross-references
3. **Heuristic checks** (report only):
   - Factual contradictions across articles
   - Outdated claims superseded by newer sources
   - Orphan pages with no inbound links
   - Concepts mentioned frequently but lacking dedicated pages
   - Archive pages with stale source citations
4. **Log** - Append summary to `llmmem/mem/log.md`.

## Output

Mem Health Report with:

- Count of issues found and auto-fixed
- Table of heuristic findings with severity and recommendation
- Suggested next actions (sources to ingest, pages to create)
