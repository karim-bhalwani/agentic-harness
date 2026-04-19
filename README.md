# Copilot Skills, Hooks & Agents Collection

![Version](https://img.shields.io/badge/version-7.0-blue)
![Status](https://img.shields.io/badge/status-Production%20Ready-brightgreen)
![Domain](https://img.shields.io/badge/domain-Data%20%2B%20AI%20Engineering-9933ff)
![Python](https://img.shields.io/badge/python-3.11%2B-blue)
![VS Code](https://img.shields.io/badge/VS%20Code-Copilot%20Compatible-0078d4)
![Audit](https://img.shields.io/badge/audit-passing-brightgreen)
![Agents](https://img.shields.io/badge/agents-12-blue)
![Skills](https://img.shields.io/badge/skills-22-blue)
![Hooks](https://img.shields.io/badge/hooks-8-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**Architect:** Karim Bhalwani  
**Version:** 7.0 | **Updated:** 2026-04-12  
**Scope:** Data + AI Engineering

> **New here?** Start with [USER-GUIDE.md](USER-GUIDE.md)
> **Python setup** → [UV-GUIDE.md](UV-GUIDE.md) (install UV, create projects, manage deps)
> **Agent catalog** → [MEGA-MINIONS.md](MEGA-MINIONS.md)
> **Copy-paste examples** → [PROMPT-CHEATSHEET.md](PROMPT-CHEATSHEET.md)
> **Architecture deep dive** → [ARCHITECTURE.md](ARCHITECTURE.md)
> **project mem guide** → [LLM-MEM-GUIDE.md](LLM-MEM-GUIDE.md)

### Reading Order by Audience

| Audience                | Start Here                               | Then Read                                                     | Reference                                                         |
| ----------------------- | ---------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------- |
| **New user**            | [USER-GUIDE.md](USER-GUIDE.md)           | [MEGA-MINIONS.md](MEGA-MINIONS.md)                            | [PROMPT-CHEATSHEET.md](PROMPT-CHEATSHEET.md)                      |
| **Skill/agent builder** | [ARCHITECTURE.md](ARCHITECTURE.md)       | Review skills in `skills/` folder                             | See [ARCHITECTURE.md](ARCHITECTURE.md) for design patterns        |
| **Architect/lead**      | [CORE_PRINCIPLES.md](CORE_PRINCIPLES.md) | [ARCHITECTURE.md](ARCHITECTURE.md)                            | Review [ARCHITECTURE.md](ARCHITECTURE.md) for engineering details |
| **Routing decisions**   | See task-routing skill                   | Consult [MEGA-MINIONS.md](MEGA-MINIONS.md) for handoff chains | -                                                                 |
| **Mem feature**         | [LLM-MEM-GUIDE.md](LLM-MEM-GUIDE.md)     | -                                                             | -                                                                 |

A curated collection of VS Code Copilot **custom agents** (`.agent.md`), **custom instructions** (`.instructions.md`), **skills** (`SKILL.md`), and **prompt files** (`.prompt.md`) designed to create an autonomous, multi-agent development workflow. Agents delegate to each other via handoffs and subagents, load domain-specific skills on demand, and follow a shared global instruction rulebook.

---

## Table of Contents

- [Overview](#overview)
- [How It Works in VS Code](#how-it-works-in-vs-code)
- [Repository Structure](#repository-structure)
- [Agents](#agents)
  - [Agent Registry](#agent-registry)
  - [Agent Interactions](#agent-interactions)
- [Skills](#skills)
  - [Skill Registry](#skill-registry)
- [Prompt Files](#prompt-files)
  - [Prompt File Registry](#prompt-file-registry)
- [Global Instructions](#global-instructions)
- [Design Principles](#design-principles)
- [Conventions & Standards](#conventions--standards)
- [Installation & Setup](#installation--setup)
- [VS Code Documentation References](#vs-code-documentation-references)

---

## Overview

This repository provides a **multi-agent orchestration system** for GitHub Copilot in VS Code. Instead of a single general-purpose AI, the system defines specialized agents (architect, senior-developer, guardian, etc.) that collaborate through a coordinator-worker pattern:

1. **Agents** (`.agent.md`) define personas, tools, instructions, and handoff chains for specific roles.
2. **Skills** (`SKILL.md`) provide domain-specific knowledge and workflow patterns that agents load on demand.
3. **Prompt Files** (`.prompt.md`) provide parameterized slash-command templates that invoke specific agents with structured context.
4. **Instructions** (`.instructions.md`) define global rules applied to every Copilot interaction.

The system follows a **Spec-Before-Code** philosophy: the Architect designs, the Senior Developer implements, the Guardian reviews, and the Release Manager ships.

---

## How It Works in VS Code

VS Code Copilot supports five customization mechanisms used by this project:

| Mechanism               | File Extension       | Location                  | Applied                                                            |
| ----------------------- | -------------------- | ------------------------- | ------------------------------------------------------------------ |
| **Custom Agents**       | `.agent.md`          | `prompts/` (user profile) | When selected from agents dropdown                                 |
| **Prompt Files**        | `.prompt.md`         | `prompts/` (user profile) | Via `/prompt-name` slash command                                   |
| **Custom Instructions** | `.instructions.md`   | `prompts/` (user profile) | Automatically via `applyTo` glob                                   |
| **Skills**              | `SKILL.md`           | `~/.copilot/skills/`      | On-demand, loaded by agents when task matches                      |
| **Hooks**               | `.ps1`, `hooks.json` | `~/.copilot/hooks/`       | Automatically at agent lifecycle events (SessionStart, Stop, etc.) |

### Key Concepts

- **Custom Agents** configure Copilot with specific personas, tool access, and instructions. They appear in the Chat view agents dropdown. Each agent declares which tools it can use and which other agents it can hand off to.
- **Subagents** run in isolated context windows. The main agent delegates subtasks, receives only the summary, keeping its own context clean. Multiple subagents can run in parallel.
- **Handoffs** create guided sequential workflows between agents with suggested next-step buttons after each response.
- **Skills** are loaded via `read_file` when an agent determines the task matches a skill's domain. Multiple skills can be combined.
- **Hooks** run automatically at VS Code agent lifecycle events (SessionStart, PreToolUse, Stop, etc.). They enforce quality contracts at the platform level, outside the model, providing deterministic enforcement that instruction-based guidance cannot guarantee.

---

## Repository Structure

```text
copilot-skills-agents/
├── README.md                              # This file
├── USER-GUIDE.md                          # Onboarding guide for new team members
├── CORE_PRINCIPLES.md                     # Design philosophy & core principles
├── MEGA-MINIONS.md                        # Friendly team guide ("The Mega Minions")
├── PROMPT-CHEATSHEET.md                   # Copy-paste prompt examples for every agent
├── pyproject.toml                         # Python project metadata
├── prompts/                               # Agent, instruction & prompt file definitions
│   ├── copilot-instruction.instructions.md  # Global rulebook (applyTo: **)
│   ├── architect.agent.md                 # System design & specs
│   ├── senior-developer.agent.md              # Implementation & features
│   ├── ai-engineer.agent.md               # RAG, LLM agents, embeddings
│   ├── data-engineer.agent.md             # PySpark, Delta Lake, dbt
│   ├── guardian.agent.md                  # Code review, security audit
│   ├── data-analyst.agent.md              # NL-to-SQL, Azure SQL, Data Vault queries
│   ├── debug-detective.agent.md           # Root cause analysis
│   ├── brownfield-discovery.agent.md           # Brownfield project mapping
│   ├── greenfield-interview.agent.md           # Greenfield project interviews
│   ├── release-manager.agent.md           # CI/CD, deployment, quality gates
│   ├── prompt-builder.agent.md            # Prompt engineering & validation
│   ├── researcher.agent.md               # Fact-checking utility (hidden)
│   ├── code-review.prompt.md              # /code-review → Guardian structured audit
│   ├── feature-plan.prompt.md             # /feature-plan → atomic implementation checklist
│   ├── sql-query.prompt.md                # /sql-query → data-analyst NL-to-SQL
│   ├── debug-detective.prompt.md          # /debug-detective → root cause analysis
│   ├── brownfield-discovery.prompt.md     # /brownfield-discovery → Project Bible
│   ├── greenfield-interview.prompt.md     # /greenfield-interview → founding interview
│   ├── doc-garden.prompt.md               # /doc-garden → documentation freshness audit
│   ├── design.prompt.md                   # /design → full design spec via Architect
│   ├── quick-fix.prompt.md                # /quick-fix → fast lane for small changes
│   ├── mem-ingest.prompt.md              # /mem-ingest → ingest source into project mem
│   ├── mem-query.prompt.md               # /mem-query → query project mem knowledge
│   ├── mem-lint.prompt.md                # /mem-lint → health check the project mem
│   ├── sprint-contract.prompt.md          # /sprint-contract → pre-work negotiation
│   └── retrospective.prompt.md            # /retrospective → pipeline retrospective
├── hooks/                                 # Hook harness (copy to ~/.copilot/hooks/)
│   ├── hooks.json                         # Hook registration config for VS Code
│   ├── quality-gate.ps1                   # Stop: blocks agent finish with ruff/ty errors
│   ├── block-destructive.ps1              # PreToolUse: blocks rm -rf, DROP TABLE, git push --force
│   ├── lint-on-write.ps1                  # PreToolUse: denies .py writes until ruff passes
│   ├── auto-format.ps1                    # PostToolUse: formats every file the agent writes
│   ├── session-context.ps1                # SessionStart: injects branch, venv, Project Bible status
│   ├── scan-secrets.ps1                   # Stop: scans modified files for leaked credentials
│   ├── pre-compact-save.ps1               # PreCompact: saves session state before compaction
│   ├── subagent-context.ps1               # SubagentStart: injects context into subagent sessions
│   └── INSTALL.md                         # Team install guide
└── skills/                                # Domain-specific skill references
    ├── architect/
    │   ├── SKILL.md                       # Black-box design, Scope Challenge, Error & Rescue Maps
    │   ├── scripts/scaffold_spec.py       # Spec scaffolder with required sections
    │   └── references/                    # SPEC.md template with Error & Rescue Map
    ├── brainstorming/
    │   ├── SKILL.md                       # Ideas-to-design dialogue
    │   ├── scripts/generate_idea_board.py # Diverge-converge idea board
    │   └── references/
    ├── concise-planning/
    │   ├── SKILL.md                       # Atomic task checklists
    │   ├── scripts/format_checklist.py    # Task list → validated checklist
    │   └── references/                    # Plan template, feature_progress.json
    ├── context-engineer/
    │   ├── SKILL.md                       # Project Bible generation, session state, orientation
    │   └── references/                    # Context snippet, orientation template, session state schema, entropy_audit.md
    ├── data-analyst/
    │   ├── SKILL.md                       # NL-to-SQL, T-SQL, Data Vault querying
    │   └── references/
    ├── data-deprecation-analysis/
    │   ├── SKILL.md                       # Dead data detection, legacy pattern analysis
    │   └── references/
    ├── data-engineering/
    │   ├── SKILL.md                       # Medallion, PySpark, dbt, SQL
    │   └── scripts/validate_schema.py     # PySpark schema contract validator
    ├── excalidraw-diagram/
    │   ├── SKILL.md                       # Visual diagram generation (.excalidraw JSON)
    │   └── references/                    # Color palette, element templates, JSON schema, visual patterns
    ├── genai-security/
    │   ├── SKILL.md                       # GenAI/LLM security, OWASP Top 10
    │   └── references/
    ├── guardian/
    │   ├── SKILL.md                       # QA, three-phase review, OWASP, testing pyramid
    │   ├── scripts/generate_review_report.py # PASS/FAIL/NEEDS WORK report
    │   └── references/                    # review-checklist.md, quality_grades.md, calibration_examples/
    ├── holdout-validation/
    │   └── SKILL.md                       # Holdout scenario authorship & test separation
    ├── implementer/
    │   ├── SKILL.md                       # TDD, clean code, type safety
    │   └── references/
    ├── llm-mem/
    │   ├── SKILL.md                       # Knowledge compilation: ingest, query, lint for project mems
    │   └── references/                    # raw-template, article-template, archive-template, index-template
    ├── llm-app-patterns/
    │   ├── SKILL.md                       # RAG, agents, LLMOps patterns
    │   └── references/
    ├── ops/
    │   ├── SKILL.md                       # GitHub Actions, Docker, IaC
    │   ├── scripts/check_pipeline_health.py # CI/CD config health scanner
    │   ├── scripts/lint_agent_legible_errors.py # Agent-legible error message linter
    │   └── references/                    # mechanical-enforcement.md
    ├── prompt-library/
    │   ├── SKILL.md                       # Prompt templates & patterns
    │   └── references/
    ├── security-boundaries/
    │   └── SKILL.md                       # Prompt injection defense rules
    ├── subagent-execution/
    │   └── SKILL.md                       # Subagent orchestration, context isolation, two-stage review
    ├── systematic-debugging/
    │   └── SKILL.md                       # Evidence-first debugging, 4-phase methodology, rationalization resistance
    ├── task-routing/
    │   └── SKILL.md                       # Multi-agent delegation protocol
    ├── thinker/
    │   ├── SKILL.md                       # Structured reasoning scaffolds
    │   └── references/
    └── verification-before-completion/
        ├── SKILL.md                       # Evidence-before-claims gate
        └── references/
```

---

## Agents

### Agent Registry

| Agent                    | Role                                                   | Hands Off To                                               |
| ------------------------ | ------------------------------------------------------ | ---------------------------------------------------------- |
| **architect**            | System design, API contracts, module boundaries, specs | data-engineer, ai-engineer, senior-developer, data-analyst |
| **senior-developer**     | Implementation, features, bug fixes, refactoring       | guardian                                                   |
| **ai-engineer**          | RAG pipelines, LLM agents, embeddings, LLMOps          | guardian                                                   |
| **data-engineer**        | PySpark pipelines, Delta Lake, dbt, Airflow            | guardian                                                   |
| **data-analyst**         | NL-to-SQL, Azure SQL, Data Vault querying, T-SQL       | guardian, data-engineer, architect                         |
| **guardian**             | Code review, security audit, performance profiling     | release-manager (PASS); senior-developer, data-engineer, ai-engineer (NEEDS WORK) |
| **debug-detective**      | Root cause analysis, hypothesis-driven investigation   | architect, senior-developer, data-engineer, ai-engineer    |
| **brownfield-discovery** | Map undocumented brownfield codebases                  | architect                                                  |
| **greenfield-interview** | Interview users for greenfield Project Bible           | architect                                                  |
| **release-manager**      | CI/CD pipelines, deployment, changelogs, quality gates | senior-developer (for gate failures)                       |
| **prompt-builder**       | Refine rough prompts into polished versions            | (standalone, no handoffs)                                  |
| **researcher**           | Fact-checking, docs retrieval, syntax validation       | (hidden, never user-invoked)                               |

> **Note:** Most agents omit `tools` in frontmatter for full default access. Exceptions: `researcher` uses `tools: [web, search]` (restricted to read-only web and search), and `guardian` has an explicit tools list enforcing its read-only audit role. Other behavioral constraints (e.g., no code editing for Guardian) are enforced via agent instructions.

### Agent Interactions

```text
                    ┌──────────────┐
    Greenfield ────►│greenfield-int│──┐
                    └──────────────┘  │
                    ┌──────────────┐  │  ┌───────────┐
    Brownfield ────►│brownfield-dis│──┴─►│ architect │
                    └──────────────┘     └─────┬─────┘
                                               │ specs
                         ┌─────────────────────┼─────────────────────┐
                         ▼            ▼        ▼                     ▼
               ┌──────────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐
               │ senior-dev   │ │data-eng  │ │ ai-engineer  │ │ data-analyst │
               └──────┬───────┘ └────┬─────┘ └──────┬───────┘ └──────┬───────┘
                      │              │              │                │
                      └──────────────┴──────────────┴────────────────┘
                                             │
                                   ┌──────────────┐
                                   │   guardian   │─── NEEDS WORK ──►(back to implementers)
                                   └──────┬───────┘
                                     PASS ▼
                                ┌──────────────────┐
                                │ release-manager  │
                                └──────────────────┘

  On-call agents:
    ┌──────────────┐     ┌───────────────┐     ┌──────────────┐
    │  researcher  │     │debug-detective│────►│architect /   │
    │  (subagent)  │     │               │     │senior-dev    │
    └──────────────┘     └───────────────┘     └──────────────┘
```

**Typical workflow:**

1. **greenfield-interview** or **brownfield-discovery** establishes context (Project Bible)
2. **architect** designs the system (produces `SPEC.md`), then hands off to implementation agents
3. **senior-developer** / **data-engineer** / **ai-engineer** implements from spec; **data-analyst** handles database queries
4. **guardian** reviews for quality, security, and performance (NEEDS WORK loops back to the implementer; PASS proceeds to **release-manager**)
5. **release-manager** handles CI/CD and deployment

**On-call agents:** **debug-detective** is called when errors arise and hands off to **architect** (design issues), **senior-developer** (implementation fixes), **data-engineer** (pipeline root cause), or **ai-engineer** (LLM/AI system root cause). **researcher** is a hidden utility agent called as a subagent for fact-checking. **prompt-builder** operates standalone with no handoffs.

---

## Skills

### Skill Registry

| Skill                              | Domain                                                                   | Used By                                                | Background? |
| ---------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------ | ----------- |
| **architect**                      | Black-box design, Scope Challenge, Error & Rescue Maps, module boundaries | architect agent                                        |             |
| **brainstorming**                  | Ideas-to-design dialogue, approach exploration                           | architect, greenfield-interview                        |             |
| **concise-planning**               | Atomic task checklists, implementation plans                             | senior-developer, any agent                            |             |
| **context-engineer**               | Project Bible generation, tiered context loading                         | brownfield-discovery, greenfield-interview             | Yes         |
| **data-analyst**                   | NL-to-SQL, Azure SQL/SSMS, Data Vault querying, T-SQL optimization       | data-analyst agent, guardian                           |             |
| **data-deprecation-analysis**      | Dead data detection, legacy pattern recognition, deprecation planning    | data-engineer, data-analyst, guardian                  |             |
| **data-engineering**               | Medallion architecture, PySpark, dbt, SQL, data quality                  | data-engineer agent                                    |             |
| **excalidraw-diagram**             | Visual diagram generation (.excalidraw JSON), architecture illustrations | architect, data-engineer, ai-engineer, senior-developer |             |
| **genai-security**                 | GenAI/LLM security auditing, OWASP Top 10 for LLMs & Agents, red teaming | guardian agent, ai-engineer                            |             |
| **guardian**                       | Three-phase review (SCOPE AUDIT/CRITICAL/INFORMATIONAL), OWASP Top 10, testing pyramid | guardian agent                                         |             |
| **holdout-validation**             | Holdout scenario authorship and evaluation, test separation discipline   | architect (authorship), guardian (eval)                | Yes         |
| **implementer**                    | TDD, clean code, type safety, Python standards                           | senior-developer agent                                 |             |
| **llm-app-patterns**               | RAG pipelines, agent architectures, prompt engineering, LLMOps           | ai-engineer agent                                      |             |
| **llm-mem**                       | Knowledge compilation: ingest sources, query mem, lint health, persist durable knowledge | all agents (post-task), senior-developer, guardian      |             |
| **ops**                            | GitHub Actions, Docker, deployment patterns, IaC                         | release-manager agent                                  |             |
| **prompt-library**                 | Prompt templates, role-based patterns, analysis frameworks               | prompt-builder agent                                   |             |
| **subagent-execution**             | Orchestrating multi-task plans via subagents, context isolation, two-stage review, status protocol | senior-developer, data-engineer, ai-engineer, architect |             |
| **systematic-debugging**           | Evidence-first root cause analysis, 4-phase debugging methodology, rationalization resistance | debug-detective, senior-developer                      |             |
| **thinker**                        | Structured reasoning (UNDERSTAND, EXTRACT, HIGHLIGHT, APPLY, VALIDATE)   | all agents (complex tasks)                             | Yes         |
| **task-routing**                   | Multi-agent delegation protocol, 6-check routing, anti-patterns          | all agents (before delegating)                         | Yes         |
| **security-boundaries**            | Prompt injection defense, trust boundaries, agent-specific security      | all agents (untrusted content), guardian                | Yes         |
| **verification-before-completion** | Evidence-before-claims gate, fresh verification required                 | all agents (before completion)                         | Yes         |

> **Background skills** have `user-invocable: false`. They are loaded automatically by agents when relevant and cannot be invoked manually via slash commands.

---

## Prompt Files

### Prompt File Registry

Prompt files are **parameterized slash-command templates** that invoke a specific agent with structured context. Invoke them with `/prompt-name` in the Chat view.

| Prompt File                        | Slash Command              | Agent Invoked          | Purpose                                        |
| ---------------------------------- | -------------------------- | ---------------------- | ---------------------------------------------- |
| `code-review.prompt.md`            | `/code-review`             | `guardian`             | Structured PASS/FAIL/NEEDS WORK code review    |
| `feature-plan.prompt.md`           | `/feature-plan`            | `architect`            | Atomic implementation checklist (no code)      |
| `sql-query.prompt.md`              | `/sql-query`               | `data-analyst`         | Natural language → optimized T-SQL             |
| `debug-detective.prompt.md`        | `/debug-detective`         | `debug-detective`      | Hypothesis-driven root cause analysis          |
| `brownfield-discovery.prompt.md`   | `/brownfield-discovery`    | `brownfield-discovery` | Codebase mapping → Project Bible               |
| `greenfield-interview.prompt.md`   | `/greenfield-interview`    | `greenfield-interview` | Founding interview → Project Bible             |
| `doc-garden.prompt.md`             | `/doc-garden`              | `guardian`             | Documentation freshness & consistency audit    |
| `design.prompt.md`                 | `/design`                  | `architect`            | Full design spec for a feature or system       |
| `quick-fix.prompt.md`              | `/quick-fix`               | `senior-developer`     | Fast lane for small, low-risk changes          |
| `retrospective.prompt.md`          | `/retrospective`           | `architect`            | Pipeline retrospective and improvement cycle   |
| `sprint-contract.prompt.md`        | `/sprint-contract`         | `architect`            | Pre-work negotiation between builder & Guardian |
| `mem-ingest.prompt.md`            | `/mem-ingest`             | `ai-engineer`          | Ingest source into project knowledge mem      |
| `mem-query.prompt.md`             | `/mem-query`              | `ai-engineer`          | Query accumulated project mem knowledge       |
| `mem-lint.prompt.md`              | `/mem-lint`               | `guardian`             | Health check the project mem                  |
| `pre-mortem.prompt.md`            | `/pre-mortem`             | `guardian`             | Fragility analysis: fictional post-mortems for bugs that haven't happened yet |

---

## Global Instructions

The file [prompts/copilot-instruction.instructions.md](prompts/copilot-instruction.instructions.md) is the global rulebook applied to **every** Copilot chat interaction via `applyTo: '**'`.

### Key Rules

| Section                 | Highlights                                                                                                                                    |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Response Style**      | Concise with rationale. 1-3 sentences for simple answers. No fluff. English only.                                                             |
| **Safety**              | Safety > Correctness > Brevity. Never process plaintext secrets.                                                                              |
| **Formatting**          | Headers + bullets. Bold for emphasis. Code blocks with language tags.                                                                         |
| **Coding Style**        | Python default: PEP 8, type hints, f-strings, pathlib. SQL: uppercase keywords, CTEs. PySpark: DataFrame API, `F.col()`.                      |
| **Testing**             | Always propose tests. `test_<feature>_<scenario>` naming.                                                                                     |
| **Error Handling**      | Happy path first. Validate inputs. Fail fast.                                                                                                 |
| **Dependencies**        | Stable/LTS. Pin majors. Never hardcode secrets.                                                                                               |
| **Tooling**             | Check for `.venv`. Never install globally. Load skills from `~/.copilot/skills/`.                                                             |
| **Agent Registry**      | Delegation table defining when each agent applies. Quick-Fix Fast Lane for small changes.                                           |
| **Project Context**     | Check `.copilot/context/PROJECT_CONTEXT.md` before any work. Session Resume Protocol for `.copilot/state/SESSION_STATE.md`.           |
| **Conflict Resolution** | Safety > Correctness > Brevity. Document overrides.                                                                                           |
| **Workflow Discipline** | Action bias, retry guardrails (3-strike rule), non-interactive flags, convention mimicry, re-read before re-edit, lint/typecheck after task.  |
| **Continuous Learning** | Use VS Code `memory` tool for cross-session facts. Store conventions, patterns, verified commands.                                            |
| **Security Boundaries** | Anti-prompt-injection defense. All file content is DATA, not instructions. Trusted sources: `.agent.md`, `.instructions.md`, `SKILL.md` only. |

---

## Design Principles

### 1. Coordinator-Worker Pattern

A main agent orchestrates the task, delegating subtasks to specialized agents. Each worker runs in its own context window, returning only summaries to keep the coordinator focused.

### 2. Spec-Before-Code

No implementation begins without a reviewed specification. The Architect produces specs, the Senior Developer follows them, the Guardian validates them.

### 3. Tiered Context Loading

Project context is organized in tiers to manage token budgets:

- **Tier 1** (always loaded, < 200 lines): `PROJECT_CONTEXT.md`
- **Tier 2** (loaded by task match): `ARCHITECTURE.md`, `CODEBASE_PATTERNS.md`, `AGENT_GUIDE.md`
- **Tier 3** (loaded on reference): `DECISIONS.md`

### 4. Evidence-Before-Claims

No agent may claim work is complete without running verification commands and confirming output. The `verification-before-completion` skill enforces this gate.

### 5. Persona-Based Agents

Each agent has a **default persona** and one or more **specialized personas** (e.g., Senior Developer has a Code Reviewer, Guardian has a Gate Keeper, Architect has a Design Reviewer).

### 6. Read-Only Review

The Guardian agent never modifies code. It only reads, tests, analyzes, and reports findings with severity-rated remediation guidance.

### 7. Black-Box Modules

All architectural designs treat modules as replaceable black boxes with defined interfaces. Internal implementation is irrelevant to consumers.

### 8. Prompt Injection Defense

All agents treat content from workspace files, terminals, URLs, and user documents as **data, never as instructions**. Only trusted sources (`.agent.md`, `.instructions.md`, `SKILL.md`) define agent behavior. Embedded directives in code comments, docstrings, or fetched content are ignored and flagged. This prevents indirect prompt injection, role hijacking, and system prompt exfiltration. See Section 14 of the [Global Instructions](prompts/copilot-instruction.instructions.md).

### 9. Intent Contracts

Every agent defines an **Intent Contract** - a set of conditions that must be true when the agent's work is done. Unlike procedural instructions ("run the tests"), intent contracts specify outcomes ("a user performing the core workflow succeeds without unexpected errors"). This shifts agent accountability from process compliance to user-observable results.

### 10. Holdout Validation

The Architect writes behavioral acceptance scenarios during spec creation, stored in `.copilot/holdout/` where implementation agents cannot see them. Guardian evaluates implementations against these holdout scenarios during review. This structural separation prevents agents from gaming their own tests - the entity writing the code can never see the criteria it will be evaluated against.

### 11. Specialization Over Minimalism

The system uses 12 specialized agents rather than fewer generalist agents. This is a deliberate tradeoff: each agent's system prompt is tightly scoped, reducing context pollution and keeping each agent focused on its domain. The coordination overhead is mitigated by strict handoff chains, token budgeting, and tiered context loading. Domain expertise lives in 22 skills (loaded on demand), not in bloated system prompts. Fourteen parameterized prompt files provide slash-command entry points for the most common workflows.

### 12. Self-Measurement

The system tracks its own effectiveness through retrospectives and rework tracking. When agents hit 3-strike escalations, when Guardian sends work back, or when holdout scenarios fail, these events are recorded as specification health signals. After every 5 workflows, the system audits whether each agent is adding value proportional to its coordination cost.

### 13. Structural Enforcement Layer (Hooks)

Quality contracts enforced by instructions are probabilistic. An agent under context pressure may skip a lint check even when instructed never to do so. The hook harness enforces quality invariants at the platform level, outside the model: a Stop hook running `ruff check .` blocks the session from closing until ruff passes. No amount of context pressure, competing priorities, or model drift can override it. Instructions handle judgment; hooks handle invariants.

---

## Conventions & Standards

### Naming

| Item              | Convention                    | Example                                              |
| ----------------- | ----------------------------- | ---------------------------------------------------- |
| Agent files       | `<name>.agent.md`             | `senior-developer.agent.md`                          |
| Prompt files      | `<purpose>.prompt.md`         | `code-review.prompt.md`                              |
| Skill files       | `SKILL.md` in named directory | `skills/implementer/SKILL.md`                        |
| Instruction files | `<name>.instructions.md`      | `copilot-instruction.instructions.md`                |
| Agent names       | lowercase, hyphenated         | `data-engineer`, `debug-detective`                   |
| Skill names       | lowercase, hyphenated         | `llm-app-patterns`, `verification-before-completion` |

> **Note:** Agent-skill mirror naming (e.g., `architect` agent + `architect` skill) is intentional. They are different primitives registered via different mechanisms and do not collide.

### Agent Response Format

Every agent response starts with its persona header:

```text
## **[Persona]**: [Action Description]
```

Examples: `## **Senior Developer**: Implementing auth service`, `## **Guardian**: Security Audit - payments module`

### Severity Levels (Guardian)

| Severity     | Blocks Release? |
| ------------ | --------------- |
| **Critical** | Yes, always     |
| **High**     | Yes, by default |
| **Medium**   | No              |
| **Low**      | No              |

### Imperative Prompting Terms (Prompt Builder)

- **You MUST**: Critical requirement
- **You WILL**: Required action
- **You ALWAYS**: Consistent behavior
- **You NEVER**: Prohibited action
- **MANDATORY**: Must not be skipped
- **CRITICAL**: Affects correctness or safety

### Technology Stack Defaults

- **Language:** Python (PEP 8, type hints, 3.11+)
- **Data Platform:** Databricks, Delta Lake, Unity Catalog
- **LLM Provider:** Azure OpenAI
- **LLM Models (agents):** Claude Opus 4.6, Claude Sonnet 4.5, Claude Haiku 4.5, GPT-5.3-Codex, Gemini 3 Flash
- **Embeddings:** text-embedding-3-small
- **Search:** Azure AI Search (vector/hybrid with semantic ranking)
- **CI/CD:** GitHub Actions
- **Data Patterns:** Medallion Architecture, Data Vault 2.0
- **Testing:** pytest, 80%+ coverage target

---

## Installation & Setup

### Prerequisites

- VS Code 1.106+ (custom agents support)
- GitHub Copilot extension
- [UV](UV-GUIDE.md) (Python package manager, no admin required)

### New Project Setup

Before calling Greenfield Interview or Brownfield Discovery agents, set up your Python project with UV:

```powershell
# Install UV (one-time, no admin needed)
irm https://astral.sh/uv/install.ps1 | iex

# Create a new project
uv init my-project
cd my-project

# Add dev tools
uv add --dev ruff ty pytest
```

See [UV-GUIDE.md](UV-GUIDE.md) for the full command reference, migration from pip, and CI/CD integration.

### Install Agents & Instructions

Copy the `prompts/` directory contents to your VS Code user profile prompts folder:

```powershell
# Windows
$profilePath = "$env:APPDATA\Code\User\prompts"
Copy-Item -Path ".\prompts\*" -Destination $profilePath -Recurse -Force
```

Alternatively, place them in a workspace's `.github/agents/` folder for project-scoped agents.

### Install Skills

Copy the `skills/` directory to `~/.copilot/skills/`:

```powershell
# Windows
$skillsPath = "$env:USERPROFILE\.copilot\skills"
New-Item -ItemType Directory -Path $skillsPath -Force
Copy-Item -Path ".\skills\*" -Destination $skillsPath -Recurse -Force
```

### Install Hooks

Copy the `hooks/` directory to `~/.copilot/hooks/`:

```powershell
# Windows
$hooksPath = "$env:USERPROFILE\.copilot\hooks"
New-Item -ItemType Directory -Path $hooksPath -Force
Copy-Item -Path ".\hooks\*" -Destination $hooksPath -Force
```

---

## License

This is a personal productivity toolkit. See individual files for any specific licensing.
