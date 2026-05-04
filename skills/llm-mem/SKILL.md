---
name: llm-mem
description: "Build and maintain a project knowledge mem using LLMs. Triggers: ingesting sources into a mem, querying mem knowledge, linting mem health, 'add to mem', 'what do I know about', 'compile to mem', or any mention of 'project mem'. Use when persisting durable knowledge (patterns, decisions, post-mortems, research) beyond the current session. DO NOT USE FOR: project setup or context files (use context-engineer), session-scoped memory (use memory tool directly), documentation generation without mem structure, or LLM app design (use llm-app-patterns)."
argument-hint: "[source to ingest, question to query, or 'lint']"
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: []
---

# LLM MEM Skill - Knowledge Compilation & Persistence

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Build and maintain a persistent, compounding knowledge mem for any project. Raw sources go in, interlinked mem articles come out. The mem grows richer with every source ingested and every question asked.

Core principles:

- **The LLM writes and maintains the mem; the human reads and asks questions.** LLMs are tireless compilers that never get bored with documentation maintenance. The human's role is curator: deciding what sources are worth ingesting and what questions are worth asking.
- **The mem is a persistent, compounding artifact.** Unlike conversation history or opaque model memory, a mem is a concrete, versionable, reviewable artifact. It lives in Git and compounds over time as more sources are ingested and more articles are cross-referenced.
- **Knowledge is compiled once and kept current, not re-derived on every query.** Compile the knowledge once into mem articles, then query the compiled mem (cheap, fast, precise) instead of re-processing raw sources (expensive, slow, inconsistent).

## Architecture

Everything lives under a single `llmmem/` directory in the **project repo**, versioned with Git:

```text
<project-root>/
└── llmmem/
    ├── raw/             ← Immutable source material (human curates, LLM reads)
    │   └── <topic>/
    │       └── YYYY-MM-DD-descriptive-slug.md
    └── mem/            ← Compiled knowledge (LLM owns entirely)
        ├── index.md     ← One-page catalog of all articles
        ├── log.md       ← Append-only operation log
        ├── overview.md  ← High-level synthesis (optional)
        └── <topic>/
            └── concept-name.md
```

**Three layers**:

| Layer       | Location      | Owner           | Rule                                                 |
| ----------- | ------------- | --------------- | ---------------------------------------------------- |
| Raw sources | `llmmem/raw/` | Human (curates) | Immutable. LLM reads, never modifies.                |
| mem         | `llmmem/mem/` | LLM (compiles)  | LLM creates, updates, cross-references. Human reads. |
| Schema      | This SKILL.md | Co-evolved      | Defines conventions, workflows, page formats.        |

### Initialization

Triggers only on the **first Ingest**. Run the scaffold script (idempotent: skips files that exist):

```bash
uv run skills/llm-mem/scripts/scaffold_mem.py
```

This creates only what is missing; it never overwrites existing files:

- `llmmem/` parent directory
- `llmmem/raw/` directory (with `.gitkeep`)
- `llmmem/mem/` directory (with `.gitkeep`)
- `llmmem/mem/index.md` - heading `# Knowledge Base Index`, empty body
- `llmmem/mem/log.md` - heading `# mem Log`, empty body

Verify structure at any time with `uv run skills/llm-mem/scripts/verify_mem.py`. The verifier also surfaces raw files that have no matching mem coverage (use `--strict` to fail on uncovered raw files in CI contexts).

If Query or Lint runs before any mem exists, tell the user: "Run an ingest first to initialize the mem." Do not auto-create.

---

## Ingest

Fetch a source into `llmmem/raw/`, then compile it into `llmmem/mem/`. Always both steps.

### Step 1: Fetch (llmmem/raw/)

1. Get the source content. Accept URLs (fetch via tools), local files (read), or pasted text.
2. Pick a topic directory. Reuse existing `llmmem/raw/` subdirectories when the topic overlaps. Create a new subdirectory only for genuinely distinct topics.
3. Save as `llmmem/raw/<topic>/YYYY-MM-DD-descriptive-slug.md`.
   - Slug from source title, kebab-case, max 60 characters.
   - Published date unknown → omit date prefix (e.g., `descriptive-slug.md`).
   - If a file with the same name exists, append a numeric suffix (e.g., `-2.md`).
   - Include metadata header: source URL, collected date, published date.
   - Preserve original text. Clean formatting noise. Do not rewrite opinions.

See [raw-template.md](./references/raw-template.md) for the exact format.

### Step 2: Compile (llmmem/mem/)

Determine where new content belongs:

- **Same core thesis as existing article** → Merge into that article. Add the new source to its Sources/Raw metadata. Update affected sections.
- **New concept** → Create a new article in the most relevant topic directory. Name the file after the concept, not the raw file.
- **Spans multiple topics** → Place in the most relevant directory. Add See Also cross-references to related articles elsewhere.

These are not mutually exclusive. A single source may merge into one article while also creating a new article for a distinct concept it introduces.

**Conflict handling**: If the new source contradicts existing content, annotate the disagreement with source attribution. When merging, note the conflict inline. When the conflict lives in separate articles, note it in both and cross-link.

See [article-template.md](./references/article-template.md) for article format.

### Step 3: Cascade Updates

After the primary article, check for ripple effects:

1. Scan articles in the same topic directory for content affected by the new source.
2. Scan `llmmem/mem/index.md` entries in other topics for articles covering related concepts.
3. Update every article whose content is materially affected. Refresh each file's Updated date.

### Step 4: Post-Ingest

1. Update `llmmem/mem/index.md`: add or update entries for every touched article. See [index-template.md](./references/index-template.md).
2. Append to `llmmem/mem/log.md`:

```
## [YYYY-MM-DD] ingest | <primary article title>
- Source: llmmem/raw/<topic>/<filename>.md
- Created: <new article titles>
- Updated: <cascade-updated article titles>
```

3. Discuss key takeaways with the user before proceeding (unless batch-ingesting).

---

## Query

Search the mem and answer questions. Triggers: "What do I know about X?", "Summarize everything related to Y", "Compare A and B based on the mem".

### Steps

1. Read `llmmem/mem/index.md` to locate relevant articles.
2. Read those articles and synthesize an answer.
3. Prefer mem content over training knowledge. Cite sources with markdown links: `[Article Title](llmmem/mem/topic/article.md)`.
4. Output the answer in conversation. Do not write files unless the user asks to archive.

### Archiving

When the user explicitly asks to archive or save the answer:

1. Write the answer as a new mem page. See [archive-template.md](./references/archive-template.md).
   - Sources: markdown links to the mem articles cited in the answer.
   - No Raw field (content comes from mem, not raw sources).
   - File name reflects the query topic.
   - Place in the most relevant topic directory.
2. Always create a new page. Never merge into existing articles (archive content is a synthesized answer, not raw material).
3. Update `llmmem/mem/index.md`. Prefix the Summary with `[Archived]`.
4. Append to `llmmem/mem/log.md`:

```
## [YYYY-MM-DD] query | Archived: <page title>
```

---

## Lint

Quality checks on the mem. Two categories with different authority levels.

### Deterministic Checks (auto-fix)

Fix these automatically:

**Index consistency** - compare `llmmem/mem/index.md` against actual `llmmem/mem/` files (excluding index.md and log.md):

- File exists but missing from index → add entry with `(no summary)` placeholder.
- Index entry points to nonexistent file → mark as `[MISSING]` in the index.

**Internal links** - for every markdown link in `llmmem/mem/` article files (body and Sources metadata):

- Target does not exist → search `llmmem/mem/` for a file with the same name elsewhere.
  - Exactly one match → fix the path.
  - Zero or multiple matches → report to user.

**Raw references** - every link in a Raw field must point to an existing `llmmem/raw/` file:

- Target does not exist → search `llmmem/raw/` for a file with the same name.
  - Exactly one match → fix the path.
  - Zero or multiple matches → report to user.

**See Also** - within each topic directory:

- Add obviously missing cross-references between related articles.
- Remove links to deleted files.

### Heuristic Checks (report only)

Report findings without auto-fixing:

- Factual contradictions across articles
- Outdated claims superseded by newer sources
- Missing conflict annotations where sources disagree
- Orphan pages with no inbound links from other mem articles
- Missing cross-topic references
- Concepts frequently mentioned but lacking a dedicated page
- Archive pages whose cited source articles have been substantially updated since archival

### Post-Lint

Append to `llmmem/mem/log.md`:

```
## [YYYY-MM-DD] lint | <N> issues found, <M> auto-fixed
```

---

## Agent Integration

This skill is designed for **dual-mode usage**:

### Mode 1: Human-Triggered (via prompts)

The user explicitly requests mem operations:

- `/mem-ingest <source>` → Ingest a source
- Direct questions → Query the mem
- "Lint the mem" → Run health checks

### Mode 2: Agent-Triggered (automatic)

Any agent loads this skill when it produces durable knowledge worth persisting. The agent's workflow gains one conditional exit step:

```
Normal workflow:  Context → Work → Verify → Done
With mem:        Context → Work → Verify → Compile to mem (if durable) → Done
```

**Decision rule**: After completing primary work, the agent asks: "Did I produce knowledge that is (a) reusable across sessions, (b) not already captured in the mem, and (c) worth more than a single-line repo memory?" If yes, load this skill and ingest the findings.

| Agent            | What It Files                                           | Example                                       |
| ---------------- | ------------------------------------------------------- | --------------------------------------------- |
| architect        | Architectural decisions, trade-off rationale            | "Why we chose event sourcing over CQRS"       |
| guardian         | Recurring anti-patterns, security findings              | "SQL injection pattern in legacy endpoints"   |
| debug-detective  | Root cause analyses, failure signatures                 | "Spark OOM from broadcast join on 8G table"   |
| senior-developer | Implementation gotchas, dependency decisions            | "Why we pinned boto3 < 1.35"                  |
| data-engineer    | Schema decisions, pipeline topology, data quality rules | "Delta merge strategy for late-arriving data" |
| retrospective    | Lessons learned, velocity patterns                      | "Sprint 12: 40% rework from ambiguous specs"  |

### Reading the mem Before Work

When starting a task, agents SHOULD check if `llmmem/mem/index.md` exists and read it for relevant prior knowledge before beginning. This replaces ad-hoc searching with a single-read navigation step.

---

## Conventions

- Standard markdown with relative links throughout.
- `llmmem/mem/` supports one level of topic subdirectories only. No deeper nesting.
- Today's date for log entries and Collected dates. Updated dates reflect when content last changed. Published dates come from the source (use `Unknown` when unavailable).
- Inside `llmmem/mem/` files, all markdown links use paths relative to the current file.
- In conversation output, use project-root-relative paths (e.g., `llmmem/mem/topic/article.md`).
- Ingest updates both `llmmem/mem/index.md` and `llmmem/mem/log.md`.
- Archive (from Query) updates both.
- Lint updates `llmmem/mem/log.md` (and `llmmem/mem/index.md` only when auto-fixing index entries).
- Plain queries do not write any files.
- The mem lives in the **project repo**, not the skills repo. It is committed to Git and shared with the team.

## When to Load This Skill

- When ingesting source material into a project mem
- When querying accumulated project knowledge
- When health-checking mem consistency
- When an agent produces durable, reusable knowledge after completing a task
- When setting up a new project's knowledge base

## Scripts

- [scaffold_mem.py](./scripts/scaffold_mem.py) - Idempotent initializer for `llmmem/` structure (creates `raw/`, `mem/`, `index.md`, `log.md`). Run before the first ingest.
- [verify_mem.py](./scripts/verify_mem.py) - Verifies `llmmem/` structure is intact and surfaces raw files with no matching mem coverage. Use `--strict` to fail on uncovered files in CI.

## References

Load these when you need the exact format for a component:

- [raw-template.md](./references/raw-template.md) - Format for raw source files
- [article-template.md](./references/article-template.md) - Format for mem articles
- [archive-template.md](./references/archive-template.md) - Format for archived query answers
- [index-template.md](./references/index-template.md) - Format for mem/index.md
