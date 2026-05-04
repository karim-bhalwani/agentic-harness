# The LLM Mem: Your Project's Living Memory

**Domain:** Data + AI Engineering  
**Architect:** Karim Bhalwani  
**Version:** 8.0 | **Updated:** 2026-05-03  
**Scope:** Persistent project knowledge base for AI-augmented teams

> **Who this is for:** Anyone on the team who wants their project to remember what it has learned. No prior mem experience required. If you can type a slash command, you can use this.

---

## What Is This and Why Should You Care?

Every day, your team produces valuable knowledge: why you chose Azure SQL over SQL Server, how you fixed that Spark OOM error, what the architect decided about the caching layer. Today, that knowledge lives in email threads, meeting notes, and conversations that disappear when the session ends. Tomorrow's developer (human or AI) starts from scratch.

The LLM Mem fixes this. It is a **knowledge base that lives in your project's Git repo**, maintained by AI agents, and readable by everyone.

```text
  ┌──────────────────────────────────────────────────────────┐
  │                    THE LLM MEM                           │
  │                                                          │
  │   You feed it sources.     AI compiles articles.         │
  │   You ask questions.       AI answers from the mem.      │
  │   You run health checks.   AI auto-fixes what it can.    │
  │                                                          │
  │   Everything lives in Git. Everything is reviewable.     │
  │   The mem gets smarter with every source you add.        │
  │                                                          │
  └──────────────────────────────────────────────────────────┘
```

Three rules to remember:

1. **You curate. AI compiles.** You decide what goes in. The agent does the writing, cross-referencing, and maintenance.
2. **Raw sources are sacred. Mem articles are AI-owned.** Never edit mem articles directly. If something is wrong, add a correcting source and let the agent recompile.
3. **Living memory, not a dumping ground.** The mem is for knowledge that matters to the project and that you want agents to remember across sessions. If it is already captured elsewhere in the Mega Minions ecosystem (Project Bible, repo memory, code comments, skill references), it does not belong here. Every article the mem holds costs context tokens when agents read it. Fill it with noise and your agents get slower and dumber. Fill it with signal and they compound.

> **The litmus test before ingesting anything:** _"Is this something relevant to the project that is not already documented, and will an agent (or a teammate) genuinely need this knowledge in three months?"_ If the answer is no, skip it. The mem is a curated library, not a filing cabinet.

---

## The Three Commands You Need

That is it. Three slash commands. Everything else is automatic.

```text
WHAT YOU WANT                    WHAT YOU TYPE
────────────────────────────────────────────────────────────
Add knowledge to the mem         /mem-ingest <source>
Ask the mem a question           /mem-query <your question>
Check the mem is healthy         /mem-lint all
```

| Command       | What Happens                                                                                   |
| ------------- | ---------------------------------------------------------------------------------------------- |
| `/mem-ingest` | Fetches the source, saves it as raw material, compiles it into mem articles, updates the index |
| `/mem-query`  | Searches the mem, reads relevant articles, synthesizes an answer with citations                |
| `/mem-lint`   | Checks for broken links, index drift, contradictions, orphan pages. Auto-fixes what it can.    |

---

## Your First Week with the mem

### Day 1: Create the mem (One Command)

Open Copilot Chat and type:

```text
/mem-ingest https://your-architecture-doc-or-key-article.com
```

That is all. The agent will:

1. Create the `llmmem/` directory structure in your project (first time only)
2. Save the source to `llmmem/raw/`
3. Show you 3-5 key takeaways and ask what to emphasize
4. Compile mem articles in `llmmem/mem/`
5. Update the mem index and log

Commit the result. Your project now has a mem.

> **No URL?** You can also ingest local files (`/mem-ingest path/to/notes.md`) or paste text directly (`/mem-ingest paste`).

---

### Day 2: Ask It a Question

Now that the mem has content, ask something:

```text
/mem-query What does the mem say about our architecture decisions?
```

The agent reads the mem index, finds relevant articles, and gives you a synthesized answer with links to the source articles. If the answer is valuable, it offers to save it as a permanent mem page.

---

### Day 3: Add More Sources

the mem compounds. Each source you add makes every future query richer.

```text
/mem-ingest https://blog-post-about-event-sourcing.com
/mem-ingest path/to/post-mortem-notes.md
/mem-ingest paste
```

Good things to ingest:

| Source Type           | Example                                                 | Why It Matters                                 |
| --------------------- | ------------------------------------------------------- | ---------------------------------------------- |
| **Design decisions**  | "We chose event sourcing because..."                    | Prevents future re-debates                     |
| **Post-mortems**      | "The OOM was caused by a broadcast join on an 8G table" | Prevents repeat failures                       |
| **Research findings** | "We evaluated 3 caching libraries, here are results"    | Saves future evaluation time                   |
| **Meeting notes**     | "Architecture review decided to split the monolith"     | Captures decisions that live in people's heads |
| **External articles** | Industry best practices relevant to your stack          | Brings outside knowledge into project context  |

**Do NOT ingest:**

- Random articles you found interesting but that do not relate to the project
- Information already in the Project Bible (stack, conventions, identity)
- Single-line facts that belong in repo memory ("always use F.col()")
- Verbose meeting transcripts: extract the decisions first, ingest only those
- Anything already covered by an existing mem article (check `/mem-query` first)

> **Remember:** Every article costs context tokens when agents read the mem. Quality over quantity, always.

---

### Day 4: Run a Health Check

```text
/mem-lint all
```

The Guardian reviews the mem and reports:

- **Auto-fixed**: Broken links, missing index entries, dead cross-references
- **Reported for review**: Contradictions between articles, orphan pages, stale content

Think of it like running tests, but for your knowledge base.

---

### Day 5: Let the Agents Do It Automatically

Here is the part that makes this different from a regular mem: **you do not have to remember to update it**.

Every Mega Minion agent is wired to check, after finishing a task, whether it produced knowledge worth saving. If the Debug Detective finds a root cause, it compiles a post-mortem article. If the Architect makes a trade-off decision, it compiles a rationale article.

You do not configure this. It just happens.

```text
  ┌──────────────────────────────────────────────────────────┐
  │                  THE KNOWLEDGE LOOP                      │
  │                                                          │
  │   ┌──────────┐    ┌──────────┐    ┌──────────────────┐   │
  │   │ Agent    │───►│ Does     │───►│ Compiles finding │   │
  │   │ reads    │    │ work     │    │ to mem           │   │
  │   │ mem      │    │          │    │ (if durable)     │   │
  │   └────▲─────┘    └──────────┘    └────────┬─────────┘   │
  │        │                                   │             │
  │        │         next session              │             │
  │        └───────────────────────────────────┘             │
  │                                                          │
  │   Each session makes the next one smarter.               │
  └──────────────────────────────────────────────────────────┘
```

---

## Where Everything Lives

the mem lives under one directory in your project. Nothing fancy. Just markdown files and Git.

```text
your-project/
├── src/                         ← Your code
├── tests/
├── .copilot/                    ← Project Bible, session state
└── llmmem/                     ← the mem lives here
    ├── raw/                     ← Source material (you curate)
    │   ├── architecture/
    │   │   ├── 2026-03-15-event-sourcing-trade-offs.md
    │   │   └── 2026-04-01-cqrs-vs-crud.md
    │   └── debugging/
    │       └── 2026-03-20-spark-oom-broadcast-join.md
    └── mem/                    ← Compiled articles (AI owns)
        ├── index.md             ← Start here: catalog of everything
        ├── log.md               ← What happened and when
        ├── architecture/
        │   ├── event-sourcing.md
        │   └── query-patterns.md
        └── debugging/
            └── spark-memory-issues.md
```

### The Two Sides

| Side          | Who Owns It | What Happens There                               | Your Role                 |
| ------------- | ----------- | ------------------------------------------------ | ------------------------- |
| `llmmem/raw/` | **You**     | Source material goes in, never changes           | Curate what gets ingested |
| `llmmem/mem/` | **AI**      | Articles get compiled, cross-referenced, updated | Read and query            |

> **Think of it like a compiler.** `raw/` is your source code. `mem/` is the compiled output. You do not edit the compiled output. If the output is wrong, you fix the source and recompile.

---

## How the Team Uses It

### Role Responsibilities

| Role           | What They Do with the mem                                                                                                 |
| -------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Developer**  | Ingests sources from their work. Queries before starting new tasks.                                                       |
| **Tech Lead**  | Reviews mem articles in PRs. Runs periodic lint. Curates topic structure.                                                 |
| **New Joiner** | Queries the mem on their first day instead of asking 50 questions. Ingests their onboarding notes at the end of week one. |
| **AI Agent**   | Reads the mem before work. Compiles articles after work. Auto-fixes links during lint.                                    |

### Onboarding a New Team Member

```text
Step 1:  /mem-query Give me an overview of the architecture and key decisions
         → Agent synthesizes a personalized overview from existing articles

Step 2:  /mem-query What are the known gotchas and failure modes?
         → Agent compiles a "things that will bite you" summary

Step 3:  After week one, the new joiner ingests their onboarding notes
         /mem-ingest path/to/my-onboarding-notes.md
         → The next joiner benefits from their experience
```

the mem captures the reasoning behind decisions, not just the decisions themselves.

---

## Growing the mem Over Time

### Week 1: Bootstrap

Seed the mem with foundational knowledge:

1. Ingest your architecture document
2. Ingest existing design docs or ADRs
3. Ingest 3-5 key external articles that shaped your technical direction
4. Run `/mem-lint all`

After this you should have 5-15 articles. That is enough for agents to start reading before tasks.

### Weeks 2-8: Organic Growth

the mem grows mostly by itself:

- Agents compile findings after tasks (automatic)
- Developers ingest sources when they encounter something valuable (ad hoc)
- Tech lead reviews mem changes in PRs (quality gate)

Most articles come from agent post-task compilation, not manual ingestion.

### Ongoing: Maintenance

- Run `/mem-lint all` weekly or in CI
- Address contradictions and orphan pages when reported
- Split topic directories that grow past 20 articles
- Archive superseded articles rather than deleting them

---

## Common Questions

### "Can I just edit mem articles directly?"

You can, but a future ingest may overwrite your changes during a cascade update. Instead, add a correcting source to `llmmem/raw/` and let the agent recompile.

### "Does this work without the Mega Minions?"

Yes. the mem is plain markdown files. Any LLM that can read and write files can maintain it. The Mega Minions give you structured slash commands and automatic post-task compilation, but the pattern works anywhere.

### "What if the agent writes something wrong?"

Add a correcting source and re-ingest. The new source takes precedence during compilation. If two sources disagree, the mem annotates the conflict rather than silently picking a winner.

### "How big can the mem get?"

No hard limit. The index is the practical bottleneck. Once it exceeds ~200 lines, add topic-level overview articles as a secondary navigation layer.

### "Can I use this for compliance?"

Yes. Git gives you full version history, author attribution (including which agent wrote what), and PR-based approval trails. The operation log (`llmmem/mem/log.md`) records every ingest, archive, and lint. That said, this is a knowledge tool, not a formal compliance system.

### "What should I NOT put in the mem?"

- Secrets, credentials, or API keys (never)
- Single-line conventions (use repo memory instead)
- Transient task context ("I am working on ticket #1234")
- Content with legal restrictions on storage or redistribution

---

## Troubleshooting

| Problem                              | Fix                                                                                                                                        |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| "No mem found" message               | Run `/mem-ingest` with any source. The first ingest creates the directory structure.                                                       |
| Agents are not compiling after tasks | Normal for routine work. Compilation only triggers for durable, reusable knowledge.                                                        |
| Broken links after a merge           | Run `/mem-lint links`. The agent searches for moved files and fixes paths automatically.                                                   |
| Index out of sync                    | Run `/mem-lint index`. Missing entries are added, orphan entries are flagged.                                                              |
| Articles contradict each other       | Run `/mem-lint all`. Contradictions are reported as heuristic findings. Resolve by adding a clarifying source or annotating both articles. |
| Mem too noisy in PRs                 | Use a dedicated mem branch (for teams of 10+) or configure your PR template to collapse `llmmem/` diffs.                                   |

---

## Quick Reference Card

```text
COMMANDS
────────────────────────────────────────────────────────────
/mem-ingest <source>        Add knowledge (URL, file, paste)
/mem-query <question>       Ask the mem something
/mem-lint <scope>           Health check (all, links, index)

KEY FILES
────────────────────────────────────────────────────────────
llmmem/mem/index.md         Start here: catalog of all articles
llmmem/mem/log.md           Operation history
llmmem/raw/                 Source material (you curate)
llmmem/mem/                 Compiled articles (AI owns)

DECISION RULES
────────────────────────────────────────────────────────────
Should I ingest this?        Will someone need this in 3 months?
Should I edit articles?      No. Add a source and re-ingest.
Should I run lint?           After merges, before releases, monthly.
Should I gitignore the mem? No. the mem is shared and reviewable.

GOLDEN RULE: Feed it knowledge today. Get smarter agents tomorrow.
```
