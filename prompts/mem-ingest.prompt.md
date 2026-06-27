---
agent: ai-engineer
description: Ingest a source document into the project's LLM-maintained knowledge mem. Fetches the source, compiles it into mem articles, updates the index, and logs the operation. Use for documents directly related to project deliverables, team decisions, research findings, or operational insights - such as articles, papers, post-mortems, meeting notes, and design reviews.
argument-hint: "[URL, file path, or 'paste' to provide text directly]"
tools:
  - read
  - search
  - edit
  - web/fetch
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Ingest this source into the project LLM-maintained knowledge memory (mem): **${input:source}**

If ${input:source} is empty or not provided, respond with: "Error: No source provided. Please supply a URL, file path, or use 'paste' to provide text directly." and halt.

**Workflow**: Load `~/.copilot/skills/llm-mem/SKILL.md` via `read_file`. The skill is the single source of truth for the ingest process (scaffold -> fetch -> discuss -> compile -> cascade -> index -> verify), the article and raw templates, and the contradiction-detection rules. Follow it; do not paraphrase here. If the SKILL.md file is missing or unreadable, respond with an error message and halt the process. If the source document cannot be fetched, is empty, or returns an error response, respond with a descriptive error message identifying the failure reason and halt the process.

**Output**: Files created or updated under `llmmem/raw/` and `llmmem/mem/`, plus a summary in this conversation listing what changed and any contradictions flagged.
