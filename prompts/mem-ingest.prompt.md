---
agent: ai-engineer
description: Ingest a source document into the project's LLM-maintained knowledge mem. Fetches the source into llmmem/raw/, compiles it into mem articles, updates the index and cross-references, and logs the operation. Use whenever you have a new article, paper, post-mortem, meeting notes, or any document worth persisting in the project mem.
argument-hint: "[URL, file path, or 'paste' to provide text directly]"
tools:
  - read
  - search
  - edit
  - fetch
version: "7.0"
updated: "2026-04-12"
---

Load `skills/llm-mem/SKILL.md` via `read_file` before proceeding.

Ingest this source into the project mem: **${input:source}**

## Process

1. **Check mem exists**  -  If `llmmem/mem/index.md` does not exist, run Initialization from the skill first.
2. **Fetch**  -  Retrieve the source content (URL, file, or ask user to paste). Save to `llmmem/raw/<topic>/` following the raw-template format.
3. **Discuss**  -  Present 3-5 key takeaways to the user. Ask what to emphasize or de-emphasize before compiling.
4. **Compile**  -  Create or update mem articles following the article-template format. Merge into existing articles when the thesis overlaps; create new articles for distinct concepts.
5. **Cascade**  -  Scan related articles for ripple effects. Update every article materially affected by the new source.
6. **Index & Log**  -  Update `llmmem/mem/index.md` and append to `llmmem/mem/log.md`.
7. **Summary**  -  Report what was created, updated, and any contradictions flagged.

## Output

- List of files created and updated
- Any contradictions or conflicts flagged
- Suggestion for next steps (related sources to ingest, questions to explore)

