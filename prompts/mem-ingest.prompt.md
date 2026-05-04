---
agent: ai-engineer
description: Ingest a source document into the project's LLM-maintained knowledge mem. Fetches the source, compiles it into mem articles, updates the index, and logs the operation. Use whenever you have an article, paper, post-mortem, meeting notes, or any document worth persisting in the project mem.
argument-hint: "[URL, file path, or 'paste' to provide text directly]"
tools:
  - read
  - search
  - edit
  - fetch
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Ingest this source into the project mem: **${input:source}**

**Workflow**: Load `skills/llm-mem/SKILL.md` via `read_file`. The skill is the single source of truth for the ingest process (scaffold -> fetch -> discuss -> compile -> cascade -> index -> verify), the article and raw templates, and the contradiction-detection rules. Follow it; do not paraphrase here.

**Output**: Files created or updated under `llmmem/raw/` and `llmmem/mem/`, plus a summary in this conversation listing what changed and any contradictions flagged.
