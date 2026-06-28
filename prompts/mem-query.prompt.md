---
agent: ai-engineer
description: Query the project mem for accumulated knowledge. Searches mem articles, synthesizes an answer with citations, and optionally archives the answer as a new mem page. Use when you want to ask questions against everything the project has learned.
argument-hint: "[your question about the project's accumulated knowledge]"
tools:
  - read
  - search
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

## Intent Contract

When this prompt completes, these conditions must be true:

- The response cites the specific mem entries that support each claim
- If no relevant knowledge exists, the gap is explicitly identified
- The answer is actionable without requiring the user to re-query

Load `~/.copilot/skills/llm-mem/SKILL.md` via `read_file` before proceeding. If `~/.copilot/skills/llm-mem/SKILL.md` cannot be read, stop and inform the user: "Unable to load the required skill file at ~/.copilot/skills/llm-mem/SKILL.md. Please verify the file exists before retrying." Do not proceed with the workflow.

Answer this question from the project mem: **${input:question}**

## Process

1. **Validate input** - Check if the question is clear and well-formed. If the input question is malformed or unclear, ask the user to rephrase it before proceeding.
2. **Read index** - Read `llmmem/mem/index.md` to locate relevant articles. If `llmmem/mem/index.md` cannot be read or is empty, inform the user: "The mem index could not be loaded. Please verify that llmmem/mem/index.md exists and is accessible." and stop.
3. **Read articles** - Read the identified articles and synthesize an answer.
   - **No articles found** - If no relevant articles are found, inform the user and suggest refining the query (e.g., try different keywords, broader terms, or check if the topic exists in mem).
4. **Cite sources** - Use markdown links to mem articles as citations.
5. **Present** - Output the answer in conversation. Base your answer primarily on mem content. If mem content is incomplete, you may supplement with training knowledge, but clearly label any such additions as not sourced from mem (e.g., "Note: the following is from general knowledge, not from mem:").
6. **Offer archival** - Ask the user: "Would you like to archive this answer as a mem page?"

If the user says yes, follow the Archive workflow from the skill. If the Archive workflow cannot be found in the skill file, inform the user: "The archive workflow is unavailable. Please check that SKILL.md contains an Archive section." and do not attempt to archive.
