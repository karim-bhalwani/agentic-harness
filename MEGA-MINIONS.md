# The Mega Minions

**Domain:** Data + AI Engineering  
**Your AI-Powered Development Crew for VS Code**  
**12 Agents • 22 Skills • 14 Prompts • 8 Hooks • Multi-Phase Pipeline**

```text
  ╔╦╗╔═╗╔═╗╔═╗  ╔╦╗╦╔╗╔╦╔═╗╔╗╔╔═╗
  ║║║║╣ ║ ╦╠═╣  ║║║║║║║║║ ║║║║╚═╗
  ╩ ╩╚═╝╚═╝╩ ╩  ╩ ╩╩╝╚╝╩╚═╝╝╚╝╚═╝
```

**Architect:** Karim Bhalwani  
**Version:** 7.0 | 12th April 2026  
**Scope:** Data Engineering, GenAI/LLM, ML Engineering

---

## Welcome to the Team

The **Mega Minions** are a collection of 12 custom AI agents, 22 specialized skills, 14 parameterized prompt files, and 8 automation hooks built for GitHub Copilot in VS Code. Together, they form a multi-agent development crew where each minion has a specific role, clear responsibilities, and knows exactly who to hand work off to next.

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

## The Architecture at a Glance

Every Mega Minion knows its place. Work flows from discovery through design, implementation, review, and release, a natural pipeline where each agent hands off to the next.

```text
                         THE MEGA MINIONS PIPELINE
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
  │                       │ specs                          │
  │         ┌─────────────┼─────────────┐                  │
  └─────────┼─────────────┼─────────────┼──────────────────┘
            ▼             ▼             ▼
  ┌─────────────────── BUILD ──────────────────────────────┐
  │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
  │  │ Senior   │  │  Data    │  │   AI     │              │
  │  │Developer │  │ Engineer │  │ Engineer │              │
  │  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
  │       │             │             │                    │
  │       │    ┌────────┴──────────┐  │                    │
  │       │    │    Data Analyst   │  │                    │
  │       │    │   (NL-to-SQL)     │  │                    │
  │       │    └───────────────────┘  │                    │
  │       └──────────────┬────────────┘                    │
  └──────────────────────┼─────────────────────────────────┘
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
**Hands off to:** Senior Developer, Data Engineer, AI Engineer, or Data Analyst (depending on the domain)

---

### The Build Crew

These four do the heavy lifting. Each one is a domain specialist who implements from the Architect's specs.

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
  ┌──────────────────────────────────────────────────────────┐
  │                    SKILLS TOOLKIT                        │
  │                                                          │
  │  Any Mega Minion can grab what they need:                │
  │                                                          │
  │  ┌────────────┐ ┌────────────┐ ┌───────────────────────┐ │
  │  │ architect  │ │brainstorm- │ │  concise-planning     │ │
  │  │            │ │  ing       │ │                       │ │
  │  │ Blueprints │ │ Ideas to   │ │ Task checklists       │ │
  │  │ & specs    │ │ designs    │ │ & atomic plans        │ │
  │  └────────────┘ └────────────┘ └───────────────────────┘ │
  │                                                          │
  │  ┌────────────┐ ┌────────────┐ ┌───────────────────────┐ │
  │  │  context-  │ │   data-    │ │  data-engineering     │ │
  │  │  engineer  │ │  analyst   │ │                       │ │
  │  │ Project    │ │ NL-to-SQL  │ │ PySpark, dbt,         │ │
  │  │ Bible ops  │ │ & T-SQL    │ │ Medallion, Delta      │ │
  │  └────────────┘ └────────────┘ └───────────────────────┘ │
  │                                                          │
  │  ┌────────────┐ ┌────────────┐ ┌───────────────────────┐ │
  │  │  genai-    │ │  guardian  │ │  implementer          │ │
  │  │  security  │ │            │ │                       │ │
  │  │ OWASP LLM  │ │ QA & sec   │ │ TDD & clean           │ │
  │  │ & Agentic  │ │ checklists │ │ code patterns         │ │
  │  └────────────┘ └────────────┘ └───────────────────────┘ │
  │                                                          │
  │  ┌────────────┐ ┌────────────┐ ┌───────────────────────┐ │
  │  │  data-     │ │  excali-   │ │  llm-app-patterns     │ │
  │  │deprecation-│ │  draw-     │ │                       │ │
  │  │  analysis  │ │  diagram   │ │ RAG, agents           │ │
  │  │ Dead data  │ │ Visual     │ │ & LLMOps              │ │
  │  │ detection  │ │ diagrams   │ │                       │ │
  │  └────────────┘ └────────────┘ └───────────────────────┘ │
  │                                                          │
  │  ┌────────────┐ ┌────────────┐ ┌───────────────────────┐ │
  │  │    ops     │ │  prompt-   │ │                       │ │
  │  │            │ │  library   │ │                       │ │
  │  │ CI/CD,     │ │ Prompt     │ │                       │ │
  │  │ Docker, IaC│ │ templates  │ │                       │ │
  │  └────────────┘ └────────────┘ └───────────────────────┘ │
  │                                                          │
  │  BACKGROUND SKILLS (auto-loaded, you never see them):    │
  │  ┌────────────┐ ┌────────────┐ ┌───────────────────────┐ │
  │  │  thinker   │ │ verificat- │ │  context-engineer     │ │
  │  │            │ │ ion-before │ │                       │ │
  │  │ Structured │ │-completion │ │ Project Bible         │ │
  │  │ reasoning  │ │ Proof gate │ │ generation            │ │
  │  └────────────┘ └────────────┘ └───────────────────────┘ │
  │  ┌────────────┐ ┌────────────┐ ┌───────────────────────┐ │
  │  │  holdout-  │ │ security-  │ │  task-routing         │ │
  │  │ validation │ │ boundaries │ │                       │ │
  │  │ Test separ-│ │ Injection  │ │ Delegation            │ │
  │  │ ation gate │ │ defense    │ │ protocol              │ │
  │  └────────────┘ └────────────┘ └───────────────────────┘ │
  └──────────────────────────────────────────────────────────┘
```

### Quick Skill Reference

| Skill                              | What It Gives Any Agent                                                             |
| ---------------------------------- | ----------------------------------------------------------------------------------- |
| **architect**                      | Black-box design, spec formats, Scope Challenge modes, Error & Rescue Maps          |
| **brainstorming**                  | Structured idea exploration, approach comparison, requirement validation            |
| **concise-planning**               | Atomic task checklists with clear done-criteria for any multi-step work             |
| **context-engineer**               | Project Bible generation, tiered context loading, decision tracking                 |
| **data-analyst**                   | NL-to-SQL patterns, Data Vault querying cheatsheets, schema exploration             |
| **data-engineering**               | Medallion architecture, PySpark optimization, dbt patterns, data quality            |
| **data-deprecation-analysis**      | Dead data detection, legacy pattern recognition, data deprecation planning          |
| **excalidraw-diagram**             | Visual diagram generation (.excalidraw JSON), architecture and flow illustrations   |
| **genai-security**                 | OWASP Top 10 for LLMs and Agentic apps, prompt injection defense, red teaming       |
| **guardian**                       | Three-phase review checklist, security audit patterns, testing pyramid, perf profiling |
| **implementer**                    | TDD workflows, clean code principles, Python type safety, refactoring patterns      |
| **llm-app-patterns**               | RAG pipeline designs, agent architectures, prompt engineering, LLMOps observability |
| **llm-mem**                       | Knowledge compilation: ingest sources into mem, query accumulated knowledge, lint health |
| **ops**                            | GitHub Actions templates, Docker patterns, deployment automation, IaC               |
| **prompt-library**                 | Curated prompt templates, role-based patterns, analysis frameworks                  |
| **subagent-execution**             | Subagent orchestration, context isolation, two-stage review, status protocol        |
| **systematic-debugging**           | Evidence-first debugging, 4-phase methodology, rationalization resistance           |
| **thinker**                        | Cognitive scaffolding (UNDERSTAND, EXTRACT, HIGHLIGHT, APPLY, VALIDATE)             |
| **holdout-validation**             | Holdout scenario authorship, test separation discipline, intent-level validation    |
| **security-boundaries**            | Prompt injection defense, trust boundary rules, agent-specific security             |
| **task-routing**                   | Multi-agent delegation protocol, 6-check routing, coordination anti-patterns        |
| **verification-before-completion** | Pre-completion evidence gate: run it, prove it, then claim it                       |

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
  Type /debug-detective → Debug Detective hunts the root cause
  Type /brownfield-disc → Brownfield Discovery maps your codebase
  Type /greenfield-int  → Greenfield Interview captures your vision
  Type /doc-garden      → Guardian audits documentation freshness
  Type /quick-fix       → Fast lane for small, obvious fixes (no pipeline)
  Type /retrospective   → Architect runs pipeline retrospective and improvement cycle
  Type /sprint-contract → Pre-work negotiation between builder and Guardian
  Type /mem-ingest     → Ingest a source into the project knowledge mem
  Type /mem-query      → Query accumulated project mem knowledge
  Type /mem-lint       → Health check the project mem
  Type /pre-mortem     → Guardian analyzes code for fragility against future edits
```

### When to Use a Prompt File vs. Invoking an Agent Directly

| Approach                             | When to Use                                                                                        |
| ------------------------------------ | -------------------------------------------------------------------------------------------------- |
| **Prompt file** (`/cmd`)             | You know exactly which workflow you want and want a consistent structure with parameterized inputs |
| **Agent directly** (agents dropdown) | You need a conversation, have a complex multi-step task, or want to guide the agent interactively  |

Both routes use the same underlying Minions. Prompt files are just pre-wired, opinionated entry points.

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

### The Prompt Engineering Behind It

Each Mega Minion's instructions are crafted using deliberate prompt engineering patterns:

| Pattern                   | How It Is Used                                                                           |
| ------------------------- | ---------------------------------------------------------------------------------------- |
| **Persona assignment**    | Each agent has a clear identity ("You are an expert...") that anchors its behavior       |
| **Constraint definition** | Agents know what they do NOT do (Guardian never writes code, Architect never implements) |
| **Workflow scaffolding**  | Step-by-step procedures prevent agents from skipping phases                              |
| **Output formatting**     | Every agent starts responses with `## **Persona**: Action` for scannable output          |
| **Delegation tables**     | Agents know exactly when to hand off and to whom, with token cost estimates              |
| **Evidence gates**        | No agent can claim "done" without proving it with tool output                            |
| **Convention mimicry**    | Agents study surrounding code before editing, matching your team's style                 |
| **Safety-first priority** | Safety > Correctness > Brevity, baked into every agent's decision making                 |

### The Context Engineering Behind It

Context engineering is the discipline of **putting the right information in front of the AI at the right time**. The Mega Minions implement this through:

| Technique                   | Implementation                                                                                                         |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Project Bible**           | A single, structured document that captures project truth. Every agent reads it first.                                 |
| **Tiered loading**          | Three tiers of context, loaded progressively based on task needs.                                                      |
| **Subagent isolation**      | Delegated work runs in separate context windows. Main agent stays focused.                                             |
| **Skill loading protocol**  | Domain knowledge loaded on demand, not upfront. Saves tokens for reasoning.                                            |
| **Handoff context passing** | Each handoff includes a prompt that transfers only the relevant decisions and findings.                                |
| **Token cost awareness**    | Delegation tables include estimated token costs to help agents make efficient decisions.                               |
| **Background knowledge**    | Silent skills (`thinker`, `verification-before-completion`) inject quality standards without consuming user attention. |
| **Holdout validation**      | Architect writes acceptance scenarios; implementation agents can't see them; Guardian evaluates against them.          |
| **Intent contracts**        | Every agent defines outcome conditions, not just procedural steps. Accountability shifts from process to results.      |
| **Self-measurement**        | Retrospectives and rework tracking surface specification quality trends and agent value over time.                     |

---

## Quick Reference Card

```text
  ╔═══════════════════════════════════════════════════════════╗
  ║              MEGA MINIONS QUICK REFERENCE                 ║
  ╠═══════════════════════════════════════════════════════════╣
  ║                                                           ║
  ║  DISCOVERY                                                ║
  ║    greenfield-interview ... New project? Start here.      ║
  ║    brownfield-discovery ... Existing code? Map it first.  ║
  ║                                                           ║
  ║  DESIGN                                                   ║
  ║    architect .............. Specs before code. Always.    ║
  ║                                                           ║
  ║  BUILD                                                    ║
  ║    senior-developer ....... Features, bugs, refactoring   ║
  ║    data-engineer .......... Pipelines, dbt, PySpark       ║
  ║    ai-engineer ............ RAG, LLM agents, embeddings   ║
  ║    data-analyst ........... English to SQL, Data Vault    ║
  ║                                                           ║
  ║  REVIEW                                                   ║
  ║    guardian ............... Read-only audit & security    ║
  ║                                                           ║
  ║  SHIP                                                     ║
  ║    release-manager ........ CI/CD, deploy, quality gates  ║
  ║                                                           ║
  ║  ON CALL                                                  ║
  ║    debug-detective ........ Root cause analysis           ║
  ║    prompt-builder ......... Create & improve prompts      ║
  ║    researcher ............. Hidden fact-checker           ║
  ║                                                           ║
  ║  SKILLS (22 total, loaded on demand by any agent)         ║
  ║    architect, brainstorming, concise-planning,            ║
  ║    context-engineer, data-analyst,                        ║
  ║    data-deprecation-analysis, data-engineering,           ║
  ║    excalidraw-diagram, genai-security, guardian,          ║
  ║    holdout-validation, implementer, llm-app-patterns,     ║
  ║    llm-mem, ops, prompt-library, security-boundaries*,    ║
  ║    subagent-execution, systematic-debugging,              ║
  ║    task-routing*, thinker*, verification*                 ║
  ║                                                           ║
  ║    * = background skill (auto-loaded, invisible to you)   ║
  ║                                                           ║
  ║  HOOKS (8 total, copy hooks/ to ~/.copilot/hooks/)        ║
  ║    quality-gate, scan-secrets ........... (Stop)          ║
  ║    block-destructive, lint-on-write .. (PreToolUse)       ║
  ║    auto-format ..................... (PostToolUse)        ║
  ║    session-context ............... (SessionStart)         ║
  ║    subagent-context ........... (SubagentStart)           ║
  ║    pre-compact-save ............... (PreCompact)          ║
  ║                                                           ║
  ║  PROMPT FILES (14 slash commands)                         ║
  ║    /code-review     /feature-plan    /sql-query           ║
  ║    /debug-detective /brownfield-disc /greenfield-int      ║
  ║    /doc-garden      /quick-fix       /design              ║
  ║    /retrospective   /sprint-contract                      ║
  ║    /mem-ingest     /mem-query      /mem-lint              ║
  ║                                                           ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  GOLDEN RULE: Context in, quality out.                    ║
  ║  Set up your Project Bible first. Everything else follows.║
  ╚═══════════════════════════════════════════════════════════╝
```

---

## Final Word

The Mega Minions are not magic. They are **well-structured prompts that guide AI models to behave like a coordinated team**. The architecture is deliberately designed around three constraints of working with LLMs:

1. **Limited context windows** - solved by tiered loading, subagent isolation, and handoff chains that keep each agent focused on one phase at a time.

2. **Tendency to drift off-task** - solved by persona assignment, constraint definitions, and workflow scaffolding that keep each agent in its lane.

3. **Hallucination risk** - solved by evidence gates (verification-before-completion), read-only review (Guardian), and the researcher agent for fact-checking.

4. **Quality contract reliability** - solved by the hook harness (8 PS1 scripts in `hooks/`), which enforces lint gates, formatting, secrets scanning, and destructive command blocking at the platform level. Instructions ask; hooks enforce.

The beauty is in the composition. No single Mega Minion is extraordinary on its own. But when they work together (discovery feeds design, design feeds implementation, implementation feeds review, review feeds release) the whole becomes significantly greater than the sum of the parts.

This approach has a name: **harness engineering**. Just as prompt engineering refined how we talk to models, and context engineering refined what models know, harness engineering refines the environments, feedback loops, and control systems that keep agents reliable. The Mega Minions are a harness. The Project Bible is its context layer. The spec-first pipeline and Guardian review are its constraint layer. The doc-garden prompt and retrospective process are its maintenance layer. The hook harness (`hooks/`, 8 PS1 scripts) is its enforcement layer: quality gates, destructive command blocking, and secrets scanning that run structurally at the platform level below the model. Instructions ask; hooks enforce.

### Why 12 Agents and Not Fewer?

Research shows that more agents can make systems worse when coordination overhead exceeds the value of parallelism (DeepMind, December 2025). So why does this system use 12 agents instead of 5 or 6?

**The answer is specialization-through-scoping, not specialization-through-duplication:**

- Each agent's system prompt is tightly focused on one domain. A `data-engineer` prompt contains PySpark patterns, Delta Lake writes, and dbt models; it doesn't contain RAG pipelines or SQL optimization. This tight scoping reduces context pollution and keeps the agent working within its area of expertise.
- Domain expertise lives in **skills** (loaded on demand), not in agent count. The skills are the real knowledge layer; the agents are routing and workflow scaffolding.
- The agents follow identical workflow _patterns_ (state machine, retry, escalation) but with different domain _content_. This is template consistency, not unnecessary duplication.
- Coordination overhead is mitigated by strict handoff chains (linear pipeline, not peer-to-peer mesh), token budgeting (delegation tables with cost estimates), and tiered context loading (each agent loads only what it needs).

**Give them context. Let them specialize. Verify their output. Ship with confidence.**

---

_The Mega Minions, 12 agents, 22 skills, 14 prompts, 8 hooks, one team._
