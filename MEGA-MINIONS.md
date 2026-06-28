# The Mega Minions

**Domain:** Data + AI Engineering  
**Your AI-Powered Development Crew for VS Code**  
**16 Agents • 26 Skills • 31 Prompts (16 agent definitions + 15 invocation templates) • 14 Hooks • 6-Phase Pipeline**

```text
  ╔╦╗╔═╗╔═╗╔═╗  ╔╦╗╦╔╗╔╦╔═╗╔╗╔╔═╗
  ║║║║╣ ║ ╦╠═╣  ║║║║║║║║║ ║║║║╚═╗
  ╩ ╩╚═╝╚═╝╩ ╩  ╩ ╩╩╝╚╝╩╚═╝╝╚╝╚═╝
```

**Architect:** Karim Bhalwani  
**Version:** 9.0 | 01-July-2026  
**Scope:** Data Engineering, GenAI/LLM, ML Engineering

---

## Welcome to the Team

The **Mega Minions** are a collection of 16 custom AI agents, 26 specialized skills, 16 parameterized prompt files, and 14 automation hooks built for GitHub Copilot in VS Code. Together, they form a multi-agent development crew where each minion has a specific role, clear responsibilities, and knows exactly who to hand work off to next.

Think of them as a squad of specialists, not a single jack-of-all-trades. The Architect draws the blueprints. The Senior Developer writes the code. The Guardian reviews it. The Release Manager ships it. Each one stays in their lane and passes the baton when it is time.

> ### A Friendly Disclaimer
>
> The Mega Minions are **built to work** - and they work best when given what they need. Think of them like capable new employees: enthusiastic, well-trained in best practices, and ready to deliver. They will produce clean, tested, production-ready work if you provide them your team's context (the Project Bible), follow the established workflow (discovery → design → build → review → ship), and teach them your conventions. What they won't do: guess your unwritten rules, reinvent tribal knowledge from 2019, or ship without proof. Feed them context. Follow the process. Get results.
>
> **What this means in practice:**
>
> - **Review their work.** They will make mistakes. Catch them early.
> - **Teach them.** When they get something wrong, correct them. They learn from feedback within a session.
> - **Give them context.** The more they know about your project (via the Project Bible), the better they perform.
> - **Trust but verify.** They will tell you the code works. Run the tests anyway.
> - **They are tools, not replacements.** They amplify your expertise; they do not substitute for it.
>
> The Mega Minions get better the more we use them. Your conventions, your patterns, your standards, these are the things they learn to follow when you teach them through project context and feedback.

---

## Prompt File Types

The prompts directory contains two file types that work together:

- **`.agent.md` files (16)** — Full agent definitions with complete frontmatter (tools, model, handoffs), intent contracts, personas, and process workflows. These are the canonical agent definitions.
- **`.prompt.md` files (15)** — Lightweight invocation templates that route to a specific agent via the `agent:` frontmatter field. These provide parameterized entry points (slash commands) for common tasks like `/quick-fix`, `/code-review`, `/sql-query`, and `/design`.

Both types count toward the "31 Prompts" total. The `.agent.md` files define *who* the agent is; the `.prompt.md` files define *how* users invoke it.

---

## The Architecture at a Glance

Every Mega Minion knows its place. Work flows from discovery through design, an optional plan phase, implementation, review, and release, a natural 6-phase pipeline where each agent hands off to the next.

```text
                         THE MEGA MINIONS PIPELINE (v9.0)
  ════════════════════════════════════════════════════════════

  ┌─────────────────────── DISCOVERY ───────────────────────┐
  │                                                         │
  │   New project?              Existing codebase?          │
  │        │                          │                     │
  │        ▼                          ▼                     │
  │  ┌─────────────┐          ┌─────────────────┐           │
  │  │ Greenfield  │          │   Brownfield    │           │
  │  │ Interview   │          │   Discovery     │           │
  │  └──────┬──────┘          └────────┬────────┘           │
  │         │    Project Bible         │                    │
  │         └───────────┬──────────────┘                    │
  └─────────────────────┼───────────────────────────────────┘
                        ▼
  ┌─────────────────── DESIGN ─────────────────────────────┐
  │                 ┌───────────┐                          │
  │                 │ Architect │                          │
  │                 └─────┬─────┘                          │
  │                       │ SPEC.md                        │
  └───────────────────────┼────────────────────────────────┘
                          ▼
  ╔══════════════ GATE 0 - HUMAN ══════════════════════════╗
  ║  Review SPEC.md. Choose your path:                     ║
  ║  [ Build Direct: Senior Dev / Data Eng / AI Eng ]      ║
  ║  [ Plan Phase:   story-master ]                        ║
  ╚══════════╤════════════════════════╤════════════════════╝
             │ Plan Phase             │ Build Direct
             ▼                        ▼
  ┌───────── PLAN ──────────┐  ┌───── BUILD (direct) ───────┐
  │  story-master           │  │  Input:  SPEC.md           │
  │    - STORIES.md         │  │  Agents: chosen specialist │
  │    Gate 1: human review │  └─────────────┬──────────────┘
  │  story-planner          │                │
  │    - US-{id}-PLAN.md    │                │
  │    Gate 2: human review │                │
  └──────────┬──────────────┘                │
             ▼  (parallel within wave)       │
  ┌─────────────────── BUILD ────────────────▼─────────────┐
  │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
  │  │ Senior   │  │  Data    │  │   AI     │              │
  │  │Developer │  │ Engineer │  │ Engineer │              │
  │  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
  │       └─────────────┴─────────────┘                    │
  └─────────────────────┼──────────────────────────────────┘
                        ▼
  ┌─────────────────── REVIEW ─────────────────────────────┐
  │                 ┌───────────┐                          │
  │                 │ Guardian  │  ◄── read-only auditor   │
  │                 └─────┬─────┘                          │
  └───────────────────────┼────────────────────────────────┘
                          ▼
  ┌─────────────────── SHIP ───────────────────────────────┐
  │              ┌────────────────┐                        │
  │              │Release Manager │                        │
  │              │ Plan path:     │                        │
  │              │  → close-story │                        │
  │              └────────────────┘                        │
  └────────────────────────────────────────────────────────┘

  ┌─────────────────── ON CALL ────────────────────────────┐
  │  ┌──────────────┐  ┌────────────┐  ┌──────────────┐    │
  │  │   Debug      │  │ Prompt     │  │  Researcher  │    │
  │  │  Detective   │  │  Builder   │  │  (hidden)    │    │
  │  └──────────────┘  └────────────┘  └──────────────┘    │
  └────────────────────────────────────────────────────────┘
```

---

## Know Your Agents (KYA)

### The Discovery Duo

These two are always your **first call** on any project. They establish the Project Bible, the single source of truth that every other Mega Minion reads before doing anything.

---

#### Greenfield Interview

> _"Tell me about your vision, and I will document every decision before a single line of code is written."_

**When to call:** Starting a brand-new project from scratch.  
**What it does:** Runs a structured 6-phase interview to capture your intent, tech stack choices, constraints, and unknowns. Produces a founding Project Bible with everything declared upfront. Items you have not decided yet are marked `[NOT YET DECIDED]` instead of guessed.  
**Hands off to:** Architect

---

#### Brownfield Discovery

> _"Point me at the codebase. I will map what is actually there, not what the README claims."_

**When to call:** Joining an existing project with little or no documentation.  
**What it does:** Systematically explores the codebase through a 10-layer methodology (from package managers to tests to infrastructure). Documents only what tools confirm. Produces a Project Bible with `[CONFIRMED]` findings, not assumptions.  
**Hands off to:** Architect

---

### The Architect

> _"I design the blueprint. I do not write the code, and I do not ship without a spec."_

**When to call:** System design, API contracts, module boundaries, data modeling.  
**What it does:** Takes the Project Bible and your requirements, then produces detailed specifications: module boundaries, API contracts, data flow diagrams, and interface definitions. Every module is designed as a replaceable black box. Starts with a **Phase 0 Scope Challenge** (REDUCTION / HOLD / EXPANSION) to right-size the design effort, and includes CEO/Product Review exercises for strategic features. Specs include an **Error & Rescue Map** that traces every failure mode to its user-visible consequence. No implementation begins until the spec is reviewed.  
**Hands off to:** Senior Developer (Build Direct), Data Engineer (Build Direct), AI Engineer (Build Direct), or story-master (Plan Phase) - the human chooses the path at Gate 0 after reviewing SPEC.md

---

### The PLAN Crew

These three agents form the optional PLAN phase, activated when the human chooses **Plan Phase** at Gate 0. They sit between DESIGN and BUILD and activate only on complex specs that benefit from a structured backlog before any code is written. The Build Direct path from v7.0 is unchanged: if the human chooses Build Direct at Gate 0, these agents are never invoked.

---

#### Story Master

> _"Give me the spec. I will map every deliverable into a story, surface the dependencies, and tell your team which work is safe to start in parallel."_

**When to call:** Human selects `[ Plan Phase ]` at Gate 0 after reviewing SPEC.md. Not invoked automatically by the Architect.  
**What it does:** Reads the approved `SPEC.md`, decomposes it into a structured user story backlog (`STORIES.md`) with dependency graph, parallel-execution waves, security flags, holdout flags, and risk tagging. Runs mandatory pre-write checks (DAG validity, SDLC coverage, independent-merge verification). Stops at Gate 1 for human review - does not auto-proceed to story-planner.  
**Inputs:** `SPEC.md`, `PROJECT_CONTEXT.md`  
**Outputs:** `.copilot/stories/STORIES.md`, `.copilot/stories/.active-story`  
**Hands off to:** Human (Gate 1 - no auto-handoff). Human then invokes story-planner with a chosen story ID.  
**DO NOT USE FOR:** Writing per-story implementation plans (use story-planner), ad-hoc one-off tasks without a spec (use feature-plan), system design (use architect), code review (use guardian), or implementation (use senior-developer, data-engineer, data-scientist, or ai-engineer).

---

#### Story Planner

> _"Give me a story and I will break it into atomic tasks, write GIVEN/WHEN/THEN acceptance criteria, list the patterns in this codebase to follow, and validate the plan before BUILD."_

**When to call:** Human invokes story-planner at Gate 1. Defaults to the story ID in `.active-story`; explicit story ID argument or `STORY_ID` env var overrides the file.  
**What it does:** Reads the story from `STORIES.md`, scans the live codebase for analogous patterns (via Explore subagent), extracts SPEC directives, writes GIVEN/WHEN/THEN acceptance criteria, decomposes into atomic tasks each with a single `Validate:` command, audits test infrastructure, and runs a plan-checker loop (separate judge, up to 3 iterations) before Gate 2. Does not proceed if blocking story dependencies are unfinished.  
**Inputs:** `STORIES.md` (story row), referenced `SPEC.md` section, `PROJECT_CONTEXT.md`  
**Outputs:** `.copilot/stories/US-{id}-PLAN.md`, `.copilot/stories/US-{id}-VALIDATION.md`  
**Hands off to:** Senior Developer, Data Engineer, or AI Engineer (human clicks Gate 2 handoff button). Also hands off to Architect if a Risk: Spike story or spec conflict is discovered.  
**DO NOT USE FOR:** Ad-hoc tasks with no spec (use feature-plan), backlog decomposition (use story-master), implementation (use senior-developer, data-engineer, data-scientist, or ai-engineer), or code review (use guardian).

---

#### Close Story

> _"The story is done when every task is checked, the report is filed, and STORIES.md is stamped. I am the gate that confirms it."_

**When to call:** Triggered by Release Manager's "Close Story" handoff button at the end of the SHIP phase on the Plan Phase path.  
**What it does:** Reads `US-{id}-PLAN.md` and the BUILD agent's `US-{id}-report.md`. Verifies every task checkbox is checked and all validation results passed. If anything is incomplete, stops and presents a Resume Build handoff back to the appropriate BUILD agent. If everything is complete, stamps the `STORIES.md` row to `done`, updates `US-{id}-VALIDATION.md`, advances `.active-story` to the next story in the wave.  
**Inputs:** `US-{id}-PLAN.md`, `US-{id}-report.md`, `US-{id}-VALIDATION.md`, `STORIES.md`  
**Outputs:** Updated `STORIES.md` (status: done), updated `US-{id}-VALIDATION.md`  
**Hands off to:** Senior Developer, Data Engineer, or AI Engineer (if incomplete tasks found); otherwise signals wave advancement.  
**DO NOT USE FOR:** Writing implementation reports (BUILD agent owns that), code review (use guardian), release-note generation (use release-manager), or plan writing (use story-planner).

---

### The Build Crew

These five do the heavy lifting. Each one is a domain specialist who implements from the Architect's specs.

---

#### Senior Developer

> _"Give me a spec or a bug report and I will deliver clean, tested, production-ready code."_

**When to call:** Feature implementation, bug fixes, refactoring, general-purpose coding.  
**What it does:** Follows existing codebase conventions, writes complete code (no `# TODO` placeholders), includes tests, and validates with lint/typecheck before declaring done. Loads the `implementer` skill for TDD and clean code patterns.  
**Hands off to:** Guardian

---

#### Data Engineer

> _"Pipelines, transformations, and data quality. I build the plumbing that makes data flow."_

**When to call:** PySpark pipelines, Delta Lake writes, dbt transformations, Airflow DAGs, data quality checks.  
**What it does:** Builds production data systems following Medallion architecture. Uses DataFrame API (never RDD), `F.col()` imports, and proper partitioning. Loads the `data-engineering` skill for domain patterns.  
**Hands off to:** Guardian

---

#### AI Engineer

> _"RAG pipelines, LLM agents, embeddings, and everything in between. I make AI systems production-ready."_

**When to call:** RAG pipelines, LLM agent architectures, embedding strategies, Azure OpenAI integration, LLMOps.  
**What it does:** Builds production AI/ML systems with proper chunking strategies, retrieval pipelines, prompt templates, and observability. Loads the `llm-app-patterns` skill and conditionally loads `genai-security` for threat modeling.  
**Hands off to:** Guardian

---

#### Data Analyst

> _"Ask me a question in plain English. I will write the SQL."_

**When to call:** Natural language to SQL, Azure SQL/SSMS queries, Data Vault querying, T-SQL optimization.  
**What it does:** Translates business questions into optimized T-SQL with proper CTEs, aliased joins, and copy-ready scripts. Understands Data Vault patterns (Hubs, Links, Satellites) and SSMS workflows. Always explains the query logic.  
**Hands off to:** Guardian, Data Engineer (if pipeline work needed), or Architect (if schema redesign needed)

---

#### Data Scientist

> _"Give me a business question and a dataset. I will profile, model, validate, and tell you what the numbers actually mean."_

**When to call:** Exploratory data analysis (EDA), statistical hypothesis testing, predictive modeling (classification / regression with scikit-learn / XGBoost), time series forecasting (Prophet, SARIMA, gradient-boosted lag features), A/B experiment design and analysis.  
**What it does:** Profiles datasets before modeling, audits for target leakage, splits data BEFORE feature engineering (no leakage), cross-validates on training data, evaluates on held-out test exactly once, and compares every model against a dummy/naive baseline. Produces SHAP feature importance, calibration diagnostics, and structured evaluation reports. Runs power analysis and SRM detection for experiments. Loads the `data-science` skill for domain patterns. Personas: EDA Analyst (default), Modeling Engineer, Forecaster, Experimenter.  
**Hands off to:** Guardian, Data Engineer (if a production pipeline is needed to feed the model), AI Engineer (if the model needs to be served behind an API or LLM agent), or Architect (if the modeling spec is flawed)

---

### The Quality Gate

#### Guardian

> _"I read. I test. I report. I never touch the code."_

**When to call:** Code review, security audit, performance profiling, quality gate enforcement.  
**What it does:** A strictly read-only auditor. Runs a **three-phase review**: Phase 0 (SCOPE AUDIT) compares changes against the spec to flag scope drift; Phase 1 (CRITICAL) checks for merge-blocking issues (SQL injection, race conditions, auth bypass, LLM trust boundary violations); Phase 2 (INFORMATIONAL) covers advisory findings (naming, complexity, duplication, logging). Reviews code against OWASP Top 10, runs the testing pyramid (unit, integration, E2E), profiles performance bottlenecks, and produces severity-rated findings (Critical/High/Medium/Low). Validates the architect's **Error & Rescue Map** against implementation. Critical and High block release. Loads the `guardian` skill and conditionally loads `genai-security` for AI-specific audits.  
**Hands off to:** Release Manager

---

### The Closer

#### Release Manager

> _"CI/CD, changelogs, quality gates, and deployment plans. I get the code out the door."_

**When to call:** Setting up CI/CD pipelines, deployment plans, changelogs, and quality gates.  
**What it does:** Builds GitHub Actions workflows, Docker configurations, and deployment automation. Validates that all quality gates pass before release. Produces release checklists and rollback procedures.  
**Hands off to:** Senior Developer (if fixes needed from gate failures)

---

### The On-Call Specialists

These agents work outside the main pipeline. Call them when you need them.

---

#### Debug Detective

> _"Give me an error, a log, or a failing test. I will find the root cause."_

**When to call:** Production failures, mysterious bugs, flaky tests, performance regressions.  
**What it does:** Runs hypothesis-driven investigation. Traces bugs through pipelines, services, and code. Produces a root cause analysis with evidence and recommended fix.  
**Hands off to:** Architect (if design issue), Senior Developer (if general implementation fix), Data Engineer (if pipeline root cause), or AI Engineer (if LLM/AI system root cause)

---

#### Prompt Builder

> _"I create, improve, and validate prompts and agent instructions. Every prompt gets tested."_

**When to call:** Creating new prompts/agents, improving existing ones, validating prompt quality.  
**What it does:** Research-driven prompt engineering with mandatory testing cycles. Produces prompts using imperative language (MUST, WILL, ALWAYS) with clear structure and measurable quality criteria.  
**Hands off to:** Terminal agent (no handoffs). Returns the refined prompt directly to the user.

---

#### Researcher

> _"I am a hidden librarian. You do not call me directly. Other agents send me to look things up."_

**When to call:** You don't. Other agents delegate to this one internally.  
**What it does:** Fact-checking, documentation retrieval, syntax validation, API research. Runs in an isolated context so the calling agent's window stays clean.  
**Hands off to:** Returns findings to the calling agent

---

## The Skills Toolkit

Skills are the **silent workers behind the scenes**. They are not agents you talk to. They are knowledge packs that any Mega Minion can pick up and use when the task calls for it. Think of them as reference manuals, checklists, and best-practice guides that agents read before starting work.

```text
  ┌──────────────────────────────────────────────────────────────────────┐
  │                    SKILLS TOOLKIT (26 SKILLS)                        │
  │                                                                      │
  │  Any Mega Minion can grab what they need:                            │
  │                                                                      │
  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────────┐ │
  │  │ architect  │ │brainstorm- │ │ concise-   │ │ context-engineer   │ │
  │  │            │ │  ing       │ │ planning   │ │                    │ │
  │  │ Blueprints │ │ Ideas to   │ │ Task       │ │ Project Bible      │ │
  │  │ & specs    │ │ designs    │ │ checklists │ │ operations & state │ │
  │  └────────────┘ └────────────┘ └────────────┘ └────────────────────┘ │
  │                                                                      │
  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────────┐ │
  │  │  data-     │ │   data-    │ │  data-     │ │  excalidraw-       │ │
  │  │  analyst   │ │deprecation-│ │ engineering│ │  diagram           │ │
  │  │ NL-to-SQL  │ │ analysis   │ │            │ │                    │ │
  │  │ & T-SQL    │ │ Dead data  │ │ PySpark,   │ │ Visual diagrams    │ │
  │  │            │ │ detection  │ │ dbt, Delta │ │ & architecture     │ │
  │  └────────────┘ └────────────┘ └────────────┘ └────────────────────┘ │
  │                                                                      │
  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────────┐ │
  │  │  genai-    │ │  guardian  │ │implementer │ │  llm-app-patterns  │ │
  │  │  security  │ │            │ │            │ │                    │ │
  │  │ OWASP LLM  │ │ QA & sec   │ │ TDD &      │ │ RAG, agents        │ │
  │  │ & Agentic  │ │ checklists │ │ clean code │ │ & LLMOps           │ │
  │  └────────────┘ └────────────┘ └────────────┘ └────────────────────┘ │
  │                                                                      │
  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────────┐ │
  │  │  llm-mem   │ │   ops      │ │ prompt-    │ │ security-          │ │
  │  │            │ │            │ │  library   │ │ boundaries         │ │
  │  │ Knowledge  │ │ CI/CD,     │ │ Prompt     │ │ Injection defense  │ │
  │  │ compilation│ │ Docker,IaC │ │ templates  │ │ & trust boundaries │ │
  │  └────────────┘ └────────────┘ └────────────┘ └────────────────────┘ │
  │                                                                      │
  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────────┐ │
  │  │subagent-   │ │systematic- │ │ task-      │ │ thinker            │ │
  │  │execution   │ │ debugging  │ │ routing    │ │                    │ │
  │  │            │ │            │ │            │ │ Structured         │ │
  │  │ Multi-task │ │ Root cause │ │ Delegation │ │ reasoning & proof  │ │
  │  │ orchestrat.│ │ analysis   │ │ protocol   │ │ scaffolds          │ │
  │  └────────────┘ └────────────┘ └────────────┘ └────────────────────┘ │
  │                                                                      │
  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────────────┐ │
  │  │verification│ │holdout-    │ │ story-     │ │ story-planner      │ │
  │  │-before-    │ │ validation │ │ master     │ │                    │ │
  │  │completion  │ │            │ │            │ │ Per-story atomic   │ │
  │  │ Evidence   │ │ Test separ-│ │ PLAN phase │ │ planning & gate 2  │ │
  │  │ proof gate │ │ ation gate │ │ backlog    │ │                    │ │
  │  └────────────┘ └────────────┘ └────────────┘ └────────────────────┘ │
  │                                                                      │
  │  ┌────────────┐ ┌────────────────────────────────────────────────┐   │
  │  │  data-     │ │  data-science                                  │   │
  │  │  narrative │ │                                                │   │
  │  │            │ │  EDA, statistical testing, predictive          │   │
  │  │ Dataset →  │ │  modeling, time series forecasting,            │   │
  │  │ evidence-  │ │  and A/B experiment design                     │   │
  │  │ traceable  │ └────────────────────────────────────────────────┘   │
  │  │ report.md  │                                                      │
  │  └────────────┘                                                      │
  │                                                                      │
  │  All 26 skills auto-load on demand. You never invoke them manually.  │
  └──────────────────────────────────────────────────────────────────────┘
```

### How Skills Work (Behind the Scenes)

1. Agent receives your task
2. Agent checks which skills match the domain
3. Agent reads the relevant `SKILL.md` file(s) before starting
4. Agent follows the skill's workflow, constraints, and quality standards
5. You never see this happening, it just makes the output better

Three skills (`thinker`, `verification-before-completion`, `context-engineer`) are **background skills**. They load automatically when relevant. You cannot (and do not need to) invoke them manually. Three additional background skills load automatically in specific contexts: `holdout-validation` during spec design and review, `security-boundaries` when handling untrusted content, and `task-routing` before agent delegation.

---

## The Prompt Files

Prompt files are **slash-command shortcuts** that wire a structured template directly to the right Minion. Instead of typing a long instruction, you type `/command` and fill in the blanks.

```text
  Type /code-review     → Guardian reviews your code
  Type /design          → Architect produces a full spec for architectural changes
  Type /feature-plan    → Architect (using concise-planning skill) produces an atomic checklist
  Type /sql-query       → Data Analyst writes optimized T-SQL
  Type /data-science    → Data Scientist runs EDA, modeling, forecasting, or A/B experiment
  Type /data-narrative  → Data Scientist turns a dataset into an evidence-grounded report.md
  Type /doc-garden      → Guardian audits documentation freshness
  Type /quick-fix       → Fast lane for small, obvious fixes (no pipeline)
  Type /retrospective   → Architect runs pipeline retrospective and improvement cycle
  Type /sprint-contract → Pre-work negotiation between builder and Guardian
  Type /mem-ingest      → Ingest a source into the project knowledge mem
  Type /mem-query       → Query accumulated project mem knowledge
  Type /mem-lint        → Health check the project mem
  Type /pre-mortem      → Guardian analyzes code for fragility against future edits
  Type /start-here      → Pipeline status check / next-action router

  Direct Agent Invocation (no slash command):
  Type @brownfield-discovery  → Map your existing codebase
  Type @greenfield-interview  → Capture vision for a new project
  Type @debug-detective       → Hunt root causes of failures
```

### When to Use a Prompt File vs. Invoking an Agent Directly

| Approach                             | When to Use                                                                                        |
| ------------------------------------ | -------------------------------------------------------------------------------------------------- |
| **Prompt file** (`/cmd`)             | You know exactly which workflow you want and want a consistent structure with parameterized inputs |
| **Agent directly** (agents dropdown) | You need a conversation, have a complex multi-step task, or want to guide the agent interactively  |

Both routes use the same underlying Minions. Prompt files are just pre-wired, opinionated entry points.

### Prompt → Agent Cross-Reference

Use this matrix to find the prompt file that maps to a given agent (or vice versa). Prompts not listed are workflow-only (no single owning agent).

| Prompt File          | Primary Agent       | Use Case                                                    |
| -------------------- | ------------------- | ----------------------------------------------------------- |
| `/start-here`        | (orientation)       | First-time setup; routes to the right agent                 |
| `/design`            | `architect`         | Produce a SPEC for new functionality                        |
| `/feature-plan`      | `story-planner`     | Decompose an approved spec into a task checklist            |
| `/quick-fix`         | `senior-developer`  | Small, low-risk change; skips full pipeline                 |
| `/code-review`       | `guardian`          | Read-only review of a PR / branch / file set                |
| `/lean-review`       | `guardian`          | Lightweight review for trivial diffs                        |
| `/pre-mortem`        | `architect`         | Surface failure modes before implementation                 |
| `/retrospective`     | `release-manager`   | Post-ship retro and lessons-learned capture                 |
| `/sprint-contract`   | `story-master`      | Negotiate the scope and DoD for an upcoming wave            |
| `/sql-query`         | `data-analyst`      | Natural language → optimized T-SQL                          |
| `/data-science`      | `data-scientist`    | EDA, modeling, forecasting, experiment design               |
| `/data-narrative`    | `data-scientist`    | Turn an analysis into a stakeholder-ready narrative         |
| `/doc-garden`        | (any)               | Documentation cleanup and link hygiene pass                 |
| `/mem-ingest`        | (any)               | Add durable knowledge to the project mem                    |
| `/mem-query`         | (any)               | Query the project mem before acting                         |
| `/mem-lint`          | (any)               | Audit mem health and surface stale entries                  |

Agents without a dedicated prompt file (`brownfield-discovery`, `greenfield-interview`, `close-story`, `debug-detective`, `ai-engineer`, `data-engineer`, `prompt-builder`, `researcher`) are invoked directly from the agent dropdown or via `@agent-name` mentions.

---

## How It All Fits Together

### The Context-Aware Architecture

The real power of the Mega Minions is not any single agent. It is how they **share context, preserve token budgets, and stay focused**.

```text
  ┌──────────────────── THE CONTEXT ENGINE ────────────────────┐
  │                                                            │
  │  TIER 1: Always Loaded (< 200 lines)                       │
  │  ┌───────────────────────────────────────────────────┐     │
  │  │ PROJECT_CONTEXT.md  (the Project Bible)           │     │
  │  │ ORIENTATION.md      (5-min quick-start summary)   │     │
  │  │ Global instructions  (shared rulebook)            │     │
  │  └───────────────────────────────────────────────────┘     │
  │                                                            │
  │  SESSION STATE: Checked on Startup                         │
  │  ┌───────────────────────────────────────────────────┐     │
  │  │ .copilot/state/SESSION_STATE.md  (resume point)   │     │
  │  └───────────────────────────────────────────────────┘     │
  │                                                            │
  │  TIER 2: Loaded by Task Match                              │
  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
  │  │ ARCHITECTURE │ │   CODEBASE   │ │  AGENT_GUIDE │        │
  │  │     .md      │ │ PATTERNS.md  │ │     .md      │        │
  │  └──────────────┘ └──────────────┘ └──────────────┘        │
  │                                                            │
  │  TIER 3: Loaded on Reference                               │
  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
  │  │ DECISIONS.md │ │ Skill refs   │ │  Templates   │        │
  │  └──────────────┘ └──────────────┘ └──────────────┘        │
  │                                                            │
  │  Each agent loads ONLY what it needs. Nothing more.        │
  └────────────────────────────────────────────────────────────┘
```

**Why this matters:**

Every AI model has a **context window**, a limited amount of text it can hold in its head at once. Stuff it full of irrelevant information and the quality of answers drops. The Mega Minions are engineered to be **context-efficient**:

- **Tiered context loading**: agents load only what the current task requires, not everything in the project.
- **5-minute orientation**: new team members and agents get up to speed from `ORIENTATION.md` without reading the full Bible.
- **Session state resume**: interrupted work persists to `.copilot/state/SESSION_STATE.md`, so agents can resume where they left off instead of starting over.
- **Subagent isolation**: when an agent delegates to a researcher or specialist, that work happens in a separate context window. Only the summary comes back, keeping the main agent's context clean.
- **Skill-on-demand**: skills are not loaded upfront. They are read only when the task domain matches, saving token budget for actual reasoning.
- **Handoff chains**: instead of one agent juggling design + implementation + review + deployment, each phase gets a fresh, focused context. The baton passes forward; the baggage does not.
- **Background skills**: the `thinker` skill forces structured reasoning before action. `verification-before-completion` forces evidence gathering before claiming done. Neither consumes your attention, but both improve output quality.

---

## Next Steps

- **Ready to start using agents?** Follow the setup and first-week walkthrough in [USER-GUIDE.md](USER-GUIDE.md)
- **Want copy-paste examples for every agent?** Open [PROMPT-CHEATSHEET.md](PROMPT-CHEATSHEET.md)
- **Not sure when to delegate vs. do it yourself?** See agent handoff chains in [MEGA-MINIONS.md](MEGA-MINIONS.md) and the task-routing skill
- **Want to give your project a living memory?** See [LLM-MEM-GUIDE.md](LLM-MEM-GUIDE.md)

## Know Your Hooks

The hook harness (`hooks/`, 14 PS1 scripts) is the **enforcement layer** of the Mega Minions. Where agent instructions ask, hooks enforce - structurally, at the platform level, below the model.

Copy the `hooks/` directory to `~/.copilot/hooks/` to activate them. They fire automatically on VS Code agent lifecycle events.

| Hook | Event | What It Does |
| ---- | ----- | ------------ |
| `quality-gate.ps1` | `Stop` | Runs lint + typecheck before the agent declares done. Blocks completion if the project's quality commands fail. |
| `scan-secrets.ps1` | `Stop` | Scans all staged files for credentials, API keys, and secret patterns. Blocks (or warns) before anything leaves the session. |
| `block-destructive.ps1` | `PreToolUse` | Intercepts `run_in_terminal` calls and blocks dangerous commands: `rm -rf`, `Remove-Item -Recurse`, `DROP TABLE`, `git push --force`, `reg delete`, `diskpart`, `cipher /w`, and more. Allows temp-path bypasses and an allowlist escape hatch. |
| `scan-user-prompt.ps1` | `UserPromptSubmit` | Scans incoming user prompts for prompt-injection markers and embedded credentials before the agent processes them. |
| `lint-on-write.ps1` | `PreToolUse` | Runs the project linter on any file the agent is about to write. Catches style and syntax errors before they land. |
| `auto-format.ps1` | `PostToolUse` | Runs the project formatter on files the agent just wrote. Keeps diffs clean without agent involvement. |
| `artifact-manifest.ps1` | `PostToolUse` | Appends a JSONL entry to `.copilot/state/artifact-manifest.jsonl` for every agent file write (timestamp, agent, tool, path, role). Gives future sessions a cheap grep-able index of produced artifacts. |
| `session-context.ps1` | `SessionStart` | Injects Project Bible path, active story, branch, last commit, Python version, and pipeline phase into the agent's startup context. |
| `subagent-context.ps1` | `SubagentStart` | Passes project root, active story, and pipeline phase to each subagent at launch, so delegated agents start with the right context. |
| `subagent-verify.ps1` | `SubagentStop` | After a subagent finishes, runs the relevant `verify_*.py` script to confirm expected artifacts (spec, story backlog, plan, review report, session state) actually landed and are not stubs. Blocks if verification fails. |
| `pre-compact-save.ps1` | `PreCompact` | Writes `.copilot/state/SESSION_STATE.md` before VS Code compacts the conversation. Preserves enough context to resume the session. |
| `block-holdout.ps1` | `PreToolUse` | Prevents implementation agents from reading `.copilot/holdout/` acceptance scenarios - the blind-evaluation layer stays blind until Guardian runs. |

**Circuit breakers**: every hook respects an escape hatch env var (e.g. `SKIP_DESTRUCTIVE_GUARD=true`, `SKIP_SUBAGENT_VERIFY=true`) for emergencies. Use them deliberately; do not leave them set.

**Installation**: see `hooks/INSTALL.md` for a one-command setup and `hooks/README.md` for configuration options per hook.

---

## Final Word

The Mega Minions are not magic. They are **well-structured prompts that guide AI models to behave like a coordinated team**. The architecture is deliberately designed around three constraints of working with LLMs:

1. **Limited context windows** - solved by tiered loading, subagent isolation, and handoff chains that keep each agent focused on one phase at a time.

2. **Tendency to drift off-task** - solved by persona assignment, constraint definitions, and workflow scaffolding that keep each agent in its lane.

3. **Hallucination risk** - solved by evidence gates (verification-before-completion), read-only review (Guardian), and the researcher agent for fact-checking.

4. **Quality contract reliability** - solved by the hook harness (14 PS1 scripts in `hooks/`), which enforces lint gates, formatting, secrets scanning, destructive command blocking, prompt-injection detection, post-subagent artifact verification, and artifact manifest logging at the platform level. Instructions ask; hooks enforce.

The beauty is in the composition. No single Mega Minion is extraordinary on its own. But when they work together (discovery feeds design, design feeds implementation, implementation feeds review, review feeds release) the whole becomes significantly greater than the sum of the parts.

This approach has a name: **harness engineering**. Just as prompt engineering refined how we talk to models, and context engineering refined what models know, harness engineering refines the environments, feedback loops, and control systems that keep agents reliable. The Mega Minions are a harness. The Project Bible is its context layer. The spec-first pipeline and Guardian review are its constraint layer. The doc-garden prompt and retrospective process are its maintenance layer. The hook harness (`hooks/`, 14 PS1 scripts) is its enforcement layer: quality gates, destructive command blocking, secrets scanning, prompt-injection detection, and post-subagent artifact verification that run structurally at the platform level below the model. Instructions ask; hooks enforce.

**Give them context. Let them specialize. Verify their output. Ship with confidence.**

---

_The Mega Minions, 16 agents, 26 skills, 16 prompts, 14 hooks, one team._
