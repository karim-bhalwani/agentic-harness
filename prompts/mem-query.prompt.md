---
agent: ai-engineer
description: Query the project mem for accumulated knowledge. Searches mem articles, synthesizes an answer with citations, and optionally archives the answer as a new mem page. Use when you want to ask questions against everything the project has learned.
argument-hint: "[your question about the project's accumulated knowledge]"
tools:
  - read
  - search
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Load `skills/llm-mem/SKILL.md` via `read_file` before proceeding.

Answer this question from the project mem: **${input:question}**

## Process

1. **Validate input** - Check if the question is clear and well-formed. If the input question is malformed or unclear, ask the user to rephrase it before proceeding.
2. **Read index** - Read `llmmem/mem/index.md` to locate relevant articles.
3. **Read articles** - Read the identified articles and synthesize an answer.
   - **No articles found** - If no relevant articles are found, inform the user and suggest refining the query (e.g., try different keywords, broader terms, or check if the topic exists in mem).
4. **Cite sources** - Use markdown links to mem articles as citations.
5. **Present** - Output the answer in conversation. Prefer mem content over training knowledge.
6. **Offer archival** - Ask the user: "Would you like to archive this answer as a mem page?"

If the user says yes, follow the Archive workflow from the skill.
