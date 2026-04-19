---
agent: ai-engineer
description: Query the project mem for accumulated knowledge. Searches mem articles, synthesizes an answer with citations, and optionally archives the answer as a new mem page. Use when you want to ask questions against everything the project has learned.
argument-hint: "[your question about the project's accumulated knowledge]"
tools:
  - read
  - search
version: "7.0"
updated: "2026-04-12"
---

Load `skills/llm-mem/SKILL.md` via `read_file` before proceeding.

Answer this question from the project mem: **${input:question}**

## Process

1. **Read index**  -  Read `llmmem/mem/index.md` to locate relevant articles.
2. **Read articles**  -  Read the identified articles and synthesize an answer.
3. **Cite sources**  -  Use markdown links to mem articles as citations.
4. **Present**  -  Output the answer in conversation. Prefer mem content over training knowledge.
5. **Offer archival**  -  Ask the user: "Would you like to archive this answer as a mem page?"

If the user says yes, follow the Archive workflow from the skill.

