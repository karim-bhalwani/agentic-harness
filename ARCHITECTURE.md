# Architecture: The Engineering Behind the Mega Minions

**Domain:** Data + AI Engineering  
**Architect:** Karim Bhalwani  
**Version:** 8.0 | **Updated:** 2026-05-03  
**Scope:** Multi-layer system design for data & LLM systems

**Is this document for you?**

- ✅ You want to understand WHY the system is designed a certain way
- ✅ You are building or modifying custom agents or skills
- ✅ You are reviewing the system architecture or making design decisions

**Not for you?**

- ❌ You are new and just want to start using agents → Read [USER-GUIDE.md](USER-GUIDE.md)
- ❌ You want copy-paste examples → Read [PROMPT-CHEATSHEET.md](PROMPT-CHEATSHEET.md)
- ❌ You want to understand the philosophy → Read [CORE_PRINCIPLES.md](CORE_PRINCIPLES.md)

---

## Why This Document Exists

CORE_PRINCIPLES.md explains the *philosophy*. MEGA-MINIONS.md introduces the *team*. This document explains the *engineering*: how the five layers of the system (Hooks, Prompts, Skills, Agents, Instructions) are designed, why they compose the way they do, and what deliberate trade-offs were made along the way.

---

## 1. System Overview

### The Five-Layer Model

The Mega Minions are built on a five-layer architecture where each layer has a distinct purpose, a distinct lifecycle, and a distinct audience.

```text
┌──────────────────────────────────────────────────────────────────┐
│                      LAYER 4: INSTRUCTIONS                       │
│  Workspace-scoped global rules applied to every agent session    │
│  automatically. Platform behavior, security posture, tool use,   │
│  and code style conventions that apply unconditionally.          │
│  Files: instructions/*.instructions.md                           │
│                                                                  │
│  Instructions SET the baseline contract. They load automatically │
│  via applyTo patterns and require no agent action to activate.   │
│  They cannot be overridden by skills, prompts, or agents.        │
├──────────────────────────────────────────────────────────────────┤
│                         LAYER 3: AGENTS                          │
│  Autonomous agents, each with a persona, intent contract,        │
│  workflow state machine, and delegation table.                   │
│  Files: prompts/*.agent.md                                       │
│                                                                  │
│  Agents CONSUME skills and prompts. They are the orchestration   │
│  layer: they decide what to do, when to delegate, and when       │
│  to stop.                                                        │
├──────────────────────────────────────────────────────────────────┤
│                         LAYER 2: SKILLS                          │
│  Domain knowledge packs, each with a SKILL.md, optional          │
│  reference docs, and optional scripts.                           │
│  Files: skills/*/SKILL.md                                        │
│                                                                  │
│  Skills ENCODE accumulated domain expertise. They are loaded     │
│  on demand by agents, injecting specialized knowledge into       │
│  the context window without permanent residency.                 │
├──────────────────────────────────────────────────────────────────┤
│                         LAYER 1: PROMPTS                         │
│  Parameterized prompt files that serve as structured entry       │
│  points into the system. Slash-command shortcuts.                │
│  Files: prompts/*.prompt.md                                      │
│                                                                  │
│  Prompts PARAMETERIZE common workflows. They are the user        │
│  interface: predictable, opinionated, and pre-wired to the       │
│  right agent.                                                    │
├──────────────────────────────────────────────────────────────────┤
│                         LAYER 0: HOOKS                           │
│  Platform-level lifecycle scripts that fire automatically at     │
│  agent events. Operate outside the language model entirely.      │
│  Files: hooks/*.ps1, hooks/hooks.json                            │
│                                                                  │
│  Hooks ENFORCE quality contracts deterministically. They cannot  │
│  be argued with, forgotten under context pressure, or overridden │
│  by an eager agent. They are the only layer the model cannot     │
│  influence.                                                      │
└──────────────────────────────────────────────────────────────────┘
```

**Why five layers?** Because the five concerns (baseline contract, user interaction, domain knowledge, workflow orchestration, and quality enforcement) have fundamentally different change rates and fundamentally different enforcement mechanisms.

- **Instructions** change when workspace-wide standards change. A new language convention, a new security posture rule, or a new tool-use policy is an instructions-layer concern.
- **Prompts** change when user workflows change. A new slash command for a new task type is a prompt-layer concern.
- **Skills** change when domain knowledge changes. A new PySpark optimization pattern or a new OWASP vulnerability category is a skill-layer concern.
- **Agents** change when workflow topology changes. A new pipeline phase or a new delegation path is an agent-layer concern.
- **Hooks** change when enforcement contracts change. A new quality gate, a new blocked command pattern, or a new credential scan rule is a hook-layer concern.

Collapsing these into fewer layers creates files that change for multiple reasons, are hard to test in isolation, and mix probabilistic instruction-following with deterministic enforcement.

### Why Not Alternatives?

**Flat prompt files** (one big `.md` per agent with everything inlined): This was the v1 approach. It worked for three agents. By agent six, the prompts exceeded 3,000 lines each. Domain knowledge was duplicated across agents. Updating a PySpark pattern meant editing four files. The three-layer model solved this by extracting shared knowledge into skills.

**Monolithic single agent** (one super-agent that does everything): DeepMind's December 2025 research showed this degrades on parallelizable tasks. A single agent also means a single context window carrying all domain knowledge simultaneously. The tighter the agent's scope, the better its reasoning quality on that scope.

**Peer-to-peer agent mesh** (agents talk freely to each other): Independent swarms with no coordination amplify errors up to 17x (DeepMind, 2025). The Mega Minions use a linear pipeline with centralized coordination, not a mesh.

### The Pipeline

Work flows through a strict linear pipeline. Each phase has exactly one sender and one receiver.

```text
                         THE MEGA MINIONS PIPELINE (v8.0)
  ════════════════════════════════════════════════════════════

  ┌─────────────────────── DISCOVERY ───────────────────────┐
  │   New project? → Greenfield Interview                   │
  │   Existing codebase? → Brownfield Discovery             │
  │   Output: PROJECT_CONTEXT.md (Project Bible)            │
  └─────────────────────────┬───────────────────────────────┘
                             ▼
  ┌──────────────────────── DESIGN ─────────────────────────┐
  │   Agent: Architect                                      │
  │   Output: SPEC.md (modules, contracts, holdout flags,   │
  │           Error & Rescue Map, Scope tag)                │
  └─────────────────────────┬───────────────────────────────┘
                             ▼
  ╔═══════════════════ GATE 0 - HUMAN ══════════════════════╗
  ║  Review SPEC.md. Choose path:                           ║
  ║  [ Build Direct → Senior Dev / Data Eng / AI Eng ]      ║
  ║  [ Plan Phase ]                                         ║
  ╚═════════════════╤═══════════════════╤═══════════════════╝
                    │ Plan Phase        │ Build Direct
                    ▼                   ▼
  ┌──────────────── PLAN ──────────────┐ ┌────── BUILD (direct) ───────┐
  │  Step 1: story-master              │ │  Input:  SPEC.md            │
  │    Output: STORIES.md              │ │  Agent:  chosen specialist  │
  │    Gate 1: Human approves waves    │ └─────────────┬───────────────┘
  │                                    │               │
  │  Step 2: story-planner (per story) │               │
  │    Output: US-{id}-PLAN.md         │               │
  │            US-{id}-VALIDATION.md   │               │
  │    Gate 2: Human approves plan     │               │
  └────────────────┬───────────────────┘               │
                   ▼  (parallel within wave)           │
  ┌──────────────────────── BUILD ─────────────────────▼───┐
  │   Agents: Senior Developer / Data Engineer / AI Eng    │
  │   Input:  US-{id}-PLAN.md  OR  SPEC.md (direct path)   │
  │   Output: code + tests + US-{id}-report.md             │
  └─────────────────────────┬──────────────────────────────┘
                             ▼
  ┌─────────────────────── REVIEW ──────────────────────────┐
  │   Agent: Guardian                                       │
  │   (genai-security skill auto-loaded if Security-flagged)│
  └─────────────────────────┬───────────────────────────────┘
                             ▼
  ┌───────────────────────── SHIP ──────────────────────────┐
  │   Agent: Release Manager                                │
  │   Plan path: close-story → stamps STORIES.md row        │
  │   Direct path: standard release flow                    │
  └─────────────────────────────────────────────────────────┘
```

On-call specialists (Debug Detective, Prompt Builder, Researcher) operate outside this pipeline and are invoked when needed. The Researcher is hidden (only other agents can invoke it as a subagent). Gate 0 is a routing decision between Design and Plan, not a phase of its own.

This linear topology means 15 agents produce handoff points bounded by the pipeline structure, not by the agent count. The coordination surface is linear rather than quadratic (n(n-1)/2).

---

## 2. Prompt Engineering Layer

### What Makes a Prompt "First Class"

In this system, prompt files (`.prompt.md`) are not informal instructions. They are structured, parameterized entry points that guarantee:

1. **Consistent routing**: Each prompt targets a specific agent via the `agent:` frontmatter field.
2. **Scoped tool access**: The `tools:` field restricts which capabilities the agent can use within that workflow.
3. **User-supplied parameters**: The `${input:name}` syntax captures structured input at invocation time, eliminating ambiguity.
4. **Eligibility gates**: Prompts like `/quick-fix` include explicit eligibility checks. If the task exceeds scope, the prompt instructs the agent to stop and redirect.

### Anatomy of a Well-Formed Prompt

Every `.prompt.md` file follows this structure:

```yaml
---
agent: [target-agent]           # Routes to the right agent
description: [when to use]      # Helps Copilot suggest the prompt
argument-hint: "[what to provide]"
tools: [read, search, edit, execute]  # Scoped tool access
---
```

The body below the frontmatter is the prompt template itself:

1. **Intent statement**: What the prompt accomplishes (one line).
2. **Eligibility check** (if applicable): Conditions that must be true. If any condition fails, the agent stops and redirects the user.
3. **Process**: Numbered steps that structure the agent's workflow, preventing phase-skipping.
4. **Output format**: Exactly what the user should expect to receive.

### Parameterization and Reuse

The `${input:variable}` syntax lets prompts capture user intent at invocation time without free-form interpretation. For example, `/feature-plan` captures `${input:task}`, which the `concise-planning` skill transforms into an atomic checklist. The prompt does not guess. It asks.

This pattern enables reuse: the same agent (e.g., `senior-developer`) can be invoked through multiple prompts (`/quick-fix`, `/feature-plan`) with different scoping and different process constraints. The agent's capabilities are constant; the prompt shapes which capabilities are active.

### Anti-Patterns Intentionally Avoided

| Anti-Pattern | Why It Fails | What This System Does Instead |
|---|---|---|
| **Open-ended prompts** ("Help me with this code") | Agent guesses intent, often wrong | Parameterized input with explicit eligibility gates |
| **Tool overloading** (every prompt gets every tool) | Agent wastes tokens deciding which tool to use | Per-prompt `tools:` scoping restricts to what's relevant |
| **Embedded domain knowledge** (PySpark patterns in the prompt) | Duplicated across prompts, stale quickly | Domain knowledge lives in Skills, loaded on demand |
| **Missing output format** ("Just do the thing") | Unpredictable output structure | Every prompt specifies output format explicitly |
| **No exit condition** (prompt always runs to completion) | Agent forces a square peg into a round hole | Eligibility checks let the prompt reject out-of-scope tasks |

---

## 3. Context Engineering Layer

### Context-as-Architecture

Context engineering is not about "giving the model more information." It is about constructing the right information, in the right shape, at the right time, and discarding everything else. In a system with 15 agents, 24 skills, and a token budget that is both expensive and finite, context management is an architectural concern, not a convenience feature.

The system implements context management through three mechanisms: **tiered loading**, **session state**, and **subagent isolation**.

### Tiered Context Loading

All project context is organized into three tiers under `.copilot/context/`:

| Tier | When Loaded | Content | Size Target |
|---|---|---|---|
| **Tier 1** | Always, at session start | `PROJECT_CONTEXT.md` (the Project Bible), `ORIENTATION.md` (5-min quick-start), global instructions | < 200 lines |
| **Tier 2** | When task matches domain | `ARCHITECTURE.md`, `CODEBASE_PATTERNS.md`, `AGENT_GUIDE.md` | Per-file |
| **Tier 3** | Only when referenced | `DECISIONS.md`, skill references, historical templates | Per-reference |

The 200-line limit on Tier 1 is not arbitrary. It is a budget constraint. Every line loaded into Tier 1 is a line loaded into every agent, every session, every task. At scale, the difference between a 200-line and a 500-line Tier 1 is measurable in reasoning quality and token cost.

### PLAN-Phase Artifact Tier Classification

v8.0 introduces four new artifacts under `.copilot/stories/`. Their tier assignments follow the same budget logic: only what the current phase needs is loaded.

| Artifact | Path | Tier | Loaded When |
|---|---|---|---|
| `STORIES.md` | `.copilot/stories/STORIES.md` | **Tier 2** | PLAN, SHIP, and retrospective phases only. **Not loaded during BUILD.** |
| `US-{id}-PLAN.md` | `.copilot/stories/US-{id}-PLAN.md` | **Tier 1 (story-scoped)** | The sole BUILD-time anchor for that story's session. |
| `US-{id}-VALIDATION.md` | `.copilot/stories/US-{id}-VALIDATION.md` | **Tier 2** | story-planner (write) and close-story (verify). **Not loaded during BUILD.** |
| `reports/US-{id}-report.md` | `.copilot/stories/reports/US-{id}-report.md` | **Tier 3** | On demand only (close-story, retrospective). |

`STORIES.md` is intentionally Tier 2 (excluded from BUILD context) so the BUILD agent's only story-anchor is `US-{id}-PLAN.md`. This prevents context bleeding from sibling stories in the same wave: each BUILD session sees exactly one story's scope.

### PROJECT_CONTEXT.md and SESSION_STATE.md as Cognitive Anchors

Two files serve as the system's persistent memory:

**PROJECT_CONTEXT.md** (the Project Bible) is the authoritative source of truth about a project. It contains identity, tech stack, critical rules, deployment target, and team structure. Every agent loads it first. It is produced by the Discovery agents (Greenfield Interview or Brownfield Discovery) and maintained by the Context Engineer skill.

**SESSION_STATE.md** is the pipeline checkpoint file. It enables cross-session resume by recording: current pipeline position, completed steps, pending steps, blockers, context pointers, and decisions made. Any agent participating in a multi-phase pipeline must write this file at the end of its turn when work is incomplete. The schema is defined in `skills/context-engineer/references/session_state_schema.md`.

Together, these files solve the "cold start" problem. Without them, every new session starts blind. With them, agents can resume mid-pipeline without re-discovering context.

### Context Budget Management

The system treats the context window as a finite cognitive budget. Every token consumed by context is a token unavailable for reasoning. Budget management happens at four levels:

1. **Tiered loading** (described above): Only load what the current task needs.
2. **Skill-on-demand**: Skills are not pre-loaded. An agent reads a `SKILL.md` file only when the task domain matches. Once the skill's guidance is absorbed, the context budget is available for reasoning.
3. **Subagent isolation**: When an agent delegates research or fact-checking to the Researcher, that work happens in a separate context window. Only the summary returns, keeping the main agent's window clean.
4. **Compiled context for handoffs**: When delegating to a subagent, the orchestrator passes only the task spec, relevant file paths, and acceptance criteria. It never forwards full session history. This is the Context Isolation Principle defined in the `subagent-execution` and `task-routing` skills.

### How Skills Inject Knowledge Without Bloating Context

A skill is loaded into the context window, consumed, and then its guidance shapes the agent's behavior for the remainder of the task. The skill itself does not need to remain "resident." The model's reasoning incorporates it and then the context budget is freed for tool calls and implementation.

This is why skills are structured as workflows and checklists rather than encyclopedic references. The `guardian` skill does not contain every OWASP vulnerability in detail; it contains a structured review procedure and pointers to reference documents that are loaded only when a specific check requires them.

---

## 4. Intent Engineering Layer

### From Instructions to Intent

An instruction tells the agent what to generate. Intent tells it what must be true when it is done. The gap between them is where most agent failures live.

Consider the difference:

- **Instruction:** "Write tests for the user module."
- **Intent:** "A new team member can read the code and understand what it does without asking the author."

The instruction can be followed perfectly (tests written, tests pass) and still produce a useless result if the tests do not cover the scenarios a real user would encounter. Intent contracts close this gap.

### What an Intent Contract Is

Every agent in this system defines an **Intent Contract**, a set of conditions that must be true when the agent's work is done. These are outcome statements, not procedural checklists.

From the actual agent files:

**Architect:**
> A developer who has never seen this project can read the spec and implement the system without asking clarifying questions. Every module boundary is defined precisely enough that two independent teams could implement both sides and integrate on the first attempt.

**Guardian:**
> A team lead reading this report can make a ship/no-ship decision in under 5 minutes without re-reading the code. The report distinguishes between "tests pass" (mechanism) and "software works for the user" (outcome).

**Senior Developer:**
> The feature works correctly for the end user, not just for the test suite. Edge cases a real user would encounter are handled gracefully.

**Debug Detective:**
> The root cause is identified with evidence, not just the proximate symptom. No hypotheses were left untested or undocumented.

### Why Behavioral Rules Are Insufficient

The holdout validation system illustrates this precisely. Palisade Research (February 2025) documented that reasoning models, including o3 and Claude 3.7, engaged in test gaming even when explicitly told not to. They hardcoded return values. They rewrote tests to match buggy code. The behavioral instruction "do not look at the tests" is insufficient because reasoning models will use available information.

The solution is structural: implementation agents are structurally blind to holdout files. The instruction is "you MUST NOT read files in `.copilot/holdout/`," but the design does not rely on the instruction alone. The Architect writes holdout scenarios during specification and stores them in a separate directory. The spec references that scenarios exist but never includes them inline. The Guardian loads them during review. The entity writing the code never sees the criteria it will be evaluated against.

### The Validation Chain

The system uses three complementary validation mechanisms, each operating at a different level:

```text
Intent Contract              "What must be true when we are done?"
        │                     (outcome-level, per agent)
        ▼
Definition of Done           "Did the procedural checks pass?"
        │                     (mechanism-level: tests, lint, types)
        ▼
Holdout Validation           "Would a real user get what they came for?"
                              (user-level, structurally blind evaluation)
```

Each level depends on the one above it. Without an intent contract, the definition of done becomes a mechanical checklist disconnected from user outcomes. Without holdout validation, the definition of done measures what the code does, not what the user needs.

### Resolving Ambiguous Intent

The system resolves ambiguity *before* implementation begins, not during it:

1. **Architect's Pre-Design Dialogue**: The Architect must clarify five categories (problem scope, data characteristics, quality attributes, integration points, team context) before writing any spec. One question per message. No spec without answers.
2. **Scope Challenge (Phase 0)**: Every task is classified as REDUCTION, HOLD, or EXPANSION before design effort is invested. This prevents over-engineering simple fixes and ensures strategic features receive full specification.
3. **Scope Expansion Exercises**: For EXPANSION-mode tasks, the Architect answers four product-lens questions (10x Check, Platonic Ideal, Do-Nothing Test, Dream State Mapping) to surface hidden assumptions before module design begins.
4. **Open Questions section in spec**: Unresolved decisions are captured with an owner and a resolution deadline. They must be resolved before implementation starts, not papered over with assumptions.

---

## 5. Harness Engineering

Harness engineering is the discipline of shaping the environment in which a model operates. If prompt engineering is about what you say, and context engineering is about what the model knows, harness engineering is about the constraints, verification gates, escalation rules, and workflow structures that keep agents reliable.

### The Agent Registry

| Agent | Role | Pipeline Phase | Never Does |
|---|---|---|---|
| Greenfield Interview | Structured interview for new projects | Discovery | Assume decisions the user hasn't made |
| Brownfield Discovery | Systematic codebase mapping | Discovery | Guess what undocumented code does |
| Architect | System design and specification | Design | Implement code |
| story-master | Decompose SPEC into story backlog (PLAN path) | Plan | Write implementation plans or code |
| story-planner | Per-story implementation plan (PLAN path) | Plan | Implement code or review it |
| Senior Developer | Feature implementation and bug fixes | Build | Redesign architecture |
| Data Engineer | Data pipeline construction | Build | Build RAG pipelines |
| AI Engineer | LLM/RAG system construction | Build | Design data schemas |
| Data Analyst | Natural language to SQL | Build (utility) | Modify application code |
| Guardian | Code review and security audit | Review | Modify code (strictly read-only) |
| Release Manager | CI/CD pipelines and deployment | Ship | Write application code |
| close-story | Verify story completion, stamp STORIES.md | Ship (PLAN path) | Advance active story without full validation |
| Debug Detective | Root cause analysis | On-call | Apply fixes (hands off to developers) |
| Prompt Builder | Prompt creation and improvement | On-call | Implement features |
| Researcher | Fact-checking and documentation retrieval | Hidden | Generate code or modify files |

The "Never Does" column is as important as the role definition. Negative constraints prevent the most common failure mode of capable models: helpfully doing things outside their lane, usually making them worse.

### Task Routing Protocol

The `task-routing` skill defines a 6-check protocol before any delegation:

1. **Sequentiality Check**: Does step N depend on step N-1's output? If yes, single agent. Multi-agent coordination degrades sequential reasoning tasks by 39-70%.
2. **Decomposability Check**: Can the task be split into independent sub-problems without shared mutable state? If no, single agent.
3. **Domain Complexity Check**: High-complexity tasks (strict sequential dependencies, dynamic state evolution) strongly prefer single-agent execution.
4. **Competence Check**: Is the task within the current agent's expertise at >50% confidence? If yes, handle it internally. Capability saturation means delegation adds overhead without accuracy gain once baseline competence is reached.
5. **Tool Density Check**: Does the sub-task require 5+ distinct tool calls? If yes, single agent, because coordination overhead consumes the context budget needed for tool use.
6. **Cost-Benefit Check**: Will delegation increase token cost >2x for <10% likely improvement? If yes, single agent.

The default posture is **self-sufficiency**. Delegation is a cost (context loss, token overhead, error amplification risk), not a free upgrade.

### Subagent Strategy

Subagents are the mechanism for keeping context windows clean during complex operations. The principles:

- **One task per subagent**: Each subagent receives exactly one focused task. No multi-objective dispatches.
- **Context Isolation Principle**: Pass only the task spec, relevant file paths, and acceptance criteria. Never forward session history, reasoning steps, or unrelated context.
- **Status Protocol**: Every subagent returns one of four statuses (`DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, `BLOCKED`) so the orchestrator can take the right next action.
- **Two-Stage Review**: After a subagent returns `DONE`, the orchestrator runs spec compliance review (did it do the right thing?) followed by quality review (did it do the thing right?).
- **Token cost visibility**: Delegation tables in agent prompts include estimated token costs per handoff (~500-2000 tokens), making the cost of coordination explicit.

### Hook Enforcement Layer

Instruction-level guardrails shape agent behavior through textual guidance. A complementary layer operates at the platform level, outside the model entirely.

The `hooks/` directory contains 11 PowerShell scripts registered in `hooks.json` that fire automatically at VS Code agent lifecycle events:

| Hook | Event | Contract Enforced |
|---|---|---|
| `quality-gate.ps1` | Stop | Session cannot close while `ruff` or `ty` errors exist (auto-skipped when no `.py` files were modified) |
| `scan-secrets.ps1` | Stop | Scans all modified files for leaked credentials, API keys, and secret patterns before the session ends. Runs in block mode by default. |
| `block-destructive.ps1` | PreToolUse | Denies `run_in_terminal` calls matching destructive patterns: `rm -rf`, `Remove-Item -Recurse` (any param order), `DROP TABLE`, `git push --force`, `reg delete`, `diskpart`, `cipher /w`, `Clear-Content`, `del /s /q`, `Format-Volume`. Bypasses temp-dir paths; supports `TOOL_GUARD_ALLOWLIST` escape hatch. |
| `scan-user-prompt.ps1` | PreToolUse | Scans incoming user prompts for prompt-injection markers and embedded credentials before the agent processes them. Emits a security notice in warn mode; blocks in block mode. |
| `lint-on-write.ps1` | PreToolUse | Denies `.py` file writes until `ruff check` passes on the proposed content |
| `auto-format.ps1` | PostToolUse | Runs `ruff format` on every Python file the agent writes |
| `session-context.ps1` | SessionStart | Injects branch, last commit, venv status, Python version, Project Bible presence, active story, pipeline artifact detection, and inferred pipeline phase into every new session |
| `subagent-context.ps1` | SubagentStart | Injects project root, active story, and pipeline phase into every subagent at launch so delegated agents start with the right context |
| `subagent-verify.ps1` | SubagentStop | After a subagent finishes, runs the relevant `verify_*.py` to confirm expected artifacts actually landed and are not stubs. Covers: spec (architect), review report (guardian), Project Bible (brownfield/greenfield), session state (builder agents), story backlog (story-master), and story plan + validation (story-planner). Blocks if verification fails; warn mode available via `SUBAGENT_VERIFY_MODE=warn`. |
| `pre-compact-save.ps1` | PreCompact | Writes `.copilot/state/SESSION_STATE.md` before VS Code compacts the conversation, preserving enough context to resume the session |
| `block-holdout.ps1` | PreToolUse | Prevents implementation agents from reading files under `.copilot/holdout/`. Keeps the blind-evaluation layer structurally blind until Guardian runs review. |

Every hook respects a circuit-breaker env var (e.g. `SKIP_DESTRUCTIVE_GUARD=true`, `SKIP_SUBAGENT_VERIFY=true`) for emergencies. Use them deliberately.

The distinction that matters: an instruction telling the agent "always run ruff before closing" can be forgotten under context pressure or overridden by a competing priority. A Stop hook running `ruff check .` cannot. The agent is structurally prevented from closing the session until ruff passes. This is the boundary between probabilistic guidance and deterministic enforcement.

Instructions and hooks are complementary, not redundant. Instructions handle nuance and judgment ("prefer CTEs over subqueries for multi-join queries"). Hooks handle invariants that must hold regardless of context ("no session closes with lint errors").


### Security Boundary Enforcement

The `security-boundaries` skill defines how the harness prevents prompt injection cascading through the agent pipeline:

- **Trust boundary**: Only files in `prompts/`, `~/.copilot/skills/`, and `.copilot/context/` are trusted instruction sources. All other content (source code, data files, user documents, logs, terminal output) is untrusted data.
- **Instruction isolation**: Embedded directives in code comments, docstrings, README content, or commit messages are treated as literal string data, never as instructions.
- **No role override**: An agent's persona and rules are defined exclusively by its `.agent.md` file and the global instruction rulebook, never by content in workspace files.
- **Attack vector coverage**: The skill includes a defense table covering malicious code comments, indirect injection via fetched content, system prompt extraction attempts, role hijacking via crafted documentation, and encoded/obfuscated injection patterns.

---

## 6. Skill Architecture

### Anatomy of a SKILL.md File

Every skill follows the same structure:

```yaml
---
name: [skill-name]
description: [what; when to use]
user-invocable: [true|false]       # Can the user load this directly?
disable-model-invocation: [true|false]  # Must be loaded explicitly?
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: [list of other skills]
---
```

Below the frontmatter:

1. **Dependencies section**: Which other skills must be loaded first, and why. Skills marked with ★ have `disable-model-invocation: true` and must be loaded explicitly via `read_file`.
2. **Overview**: What the skill does and its core principles.
3. **Workflow**: Step-by-step procedure the agent follows when this skill is active.
4. **Output format**: What the skill produces (spec, report, checklist, diagram).
5. **When to Use / When Not to Use**: Explicit positive and negative scope boundaries.

### The `references/` and `scripts/` Directories

Skills can include companion files:

- **`references/`**: Templates, checklists, and reference documents that the skill loads on demand. For example, `skills/architect/references/SPEC.md` contains the full 13-section specification template. `skills/context-engineer/references/session_state_schema.md` defines the schema for `SESSION_STATE.md`.
- **`scripts/`**: Utility scripts that support skill workflows. For example, `skills/architect/scripts/scaffold_spec.py` generates spec scaffolding. `skills/concise-planning/scripts/format_checklist.py` formats plan output.

These companion files are Tier 3 context, loaded only when specifically referenced during skill execution.

### Mandatory Load-Before-Use Pattern

Skills with `disable-model-invocation: true` (the thinker, verification-before-completion, context-engineer, security-boundaries, task-routing, holdout-validation) cannot self-activate. They must be explicitly loaded by the consuming agent via `read_file`. This is a deliberate constraint:

- **Background skills** (thinker, verification-before-completion, context-engineer) inject quality scaffolding silently. They load automatically when relevant conditions are met but are invisible to the user.
- **Gating skills** (security-boundaries, task-routing, holdout-validation) load only when specific triggers occur (untrusted content, delegation decision, spec design/review).

The load-before-use pattern prevents context bloat. If all 24 skills were pre-loaded, the agent's context window would be consumed by domain knowledge before any task-specific reasoning could begin.

### Skill Composition

When a task spans multiple domains, multiple skills are loaded simultaneously. The agent files declare this in their "Skills to Load" section:

- The **Architect** loads `architect` + `brainstorming` + `thinker` + `holdout-validation`, and conditionally `excalidraw-diagram`.
- The **Senior Developer** loads `implementer` + `thinker` + `verification-before-completion`, and conditionally domain-specific skills like `data-engineering`.
- The **Guardian** loads `guardian` + `verification-before-completion`, and conditionally `genai-security` for AI-specific audits.

Skill composition follows a simple rule: each skill defines what it does and what it does not do. The `implementer` skill will not make architectural changes. The `architect` skill will not generate code. These negative boundaries prevent overlap and ensure that composed skills operate on different aspects of the same task.

### How Skills Encode Domain Knowledge

Skills are structured as **workflows and constraints**, not as encyclopedias. The `data-engineering` skill contains PySpark optimization patterns, Medallion architecture rules, and dbt transformation patterns, but it encodes them as decision procedures ("when building a Bronze-to-Silver transformation, apply these schema validation checks") rather than reference material ("here are all possible PySpark transformations").

This design choice optimizes for the model's reasoning: a workflow gives the model a procedure to follow, while an encyclopedia gives it information to wade through. The former consumes less context budget and produces more consistent results.

---

## 7. Design Decisions and Trade-offs

### Decision 1: Linear Pipeline Over Peer-to-Peer Mesh

**Choice**: Agents hand off work in a strict linear chain (Discovery → Design → Build → Review → Ship). No agent communicates directly with a peer.

**Alternatives Considered**: Peer-to-peer agent mesh (agents negotiate and coordinate freely), star topology (all agents report to a single coordinator), tree topology (hierarchical delegation).

**Rationale**: DeepMind's December 2025 study showed that independent swarms amplify errors up to 17x and that centralized coordination improves performance by over 80% on parallelizable tasks. The linear pipeline is the simplest topology that provides centralized coordination. It produces N-1 handoff points instead of N(N-1)/2 communication pathways, making coordination cost linear rather than quadratic.

**Trade-off**: The pipeline is sequential by default. Tasks that could theoretically be parallelized (e.g., Senior Developer and Data Engineer working on different modules simultaneously) must be orchestrated explicitly through the `subagent-execution` skill. The pipeline cannot automatically detect parallelism.

---

### Decision 2: Skills as Separate Files, Not Embedded in Agent Prompts

**Choice**: Domain knowledge lives in `skills/*/SKILL.md` files that are loaded on demand, not embedded in agent `.agent.md` files.

**Alternatives Considered**: Inline all domain knowledge in agent prompts (v1 approach), central knowledge base queried at runtime, RAG-based knowledge retrieval.

**Rationale**: Inline knowledge caused duplication (four agents needed the same PySpark patterns), staleness (updating a pattern meant editing four files), and context bloat (every agent carried every domain's knowledge, even when irrelevant). Separate skill files allow N agents to share 1 skill, updates propagate from a single source, and context budget is conserved because skills load only when needed.

**Trade-off**: Skill loading adds latency (a `read_file` call per skill) and requires agents to know which skills to load. If an agent fails to load a relevant skill, it operates without that domain knowledge. The "Skills to Load" section in each agent prompt mitigates this by explicitly declaring required skills.

---

### Decision 3: Holdout Validation via Instruction-Level Blindness

**Choice**: Implementation agents are instructed not to read `.copilot/holdout/` files. The Architect writes holdout scenarios during specification. The Guardian evaluates against them during review.

**Alternatives Considered**: File-system-level access controls (not supported by VS Code's agent model), unit tests authored by a separate test-writing agent (still visible to implementation agents), no holdout system (rely on Guardian review alone).

**Rationale**: Research shows reasoning models game tests even when told not to (Palisade Research, February 2025). Structural separation (making the criteria invisible to the entity being evaluated) is the only reliable mechanism. Instruction-level enforcement is the strongest mechanism currently available in VS Code's agent model.

**Trade-off**: This is a known limitation. The blindness is behavioral, not physical. If an implementation agent ignores the "MUST NOT read holdout files" instruction, the separation breaks. The fix requires upstream tooling changes (file-level agent permissions in VS Code), not design changes in this system.

---

### Decision 4: Intent Contracts Over Procedural Checklists

**Choice**: Every agent defines an Intent Contract (outcome conditions that must be true when work is done) in addition to, not replacing, procedural definitions of done.

**Alternatives Considered**: Procedural checklists only (run tests, pass lint, deploy), acceptance criteria written as user stories, no formal completion criteria.

**Rationale**: Procedural checklists measure process compliance ("did you follow the steps?") but cannot detect outcome failures ("does the software work for the user?"). A test suite can pass while a real user's workflow is broken. Intent contracts shift accountability to outcomes. They are written from the perspective of someone who has never seen the code (a user, a team lead, a new team member), making them externally verifiable.

**Trade-off**: Intent contracts are harder to automate. A linter can check if tests pass; it cannot check if "a team lead can make a ship/no-ship decision in under 5 minutes." Evaluation against intent contracts requires judgment, currently provided by the Guardian during review. This makes the Guardian a bottleneck for intent validation.

---

### Decision 5: 15 Agents with Tight Scoping Over 5-6 Generalist Agents

**Choice**: 15 agents, each with a narrowly scoped system prompt focused on one domain or pipeline phase.

**Alternatives Considered**: 5-6 generalist agents that combine roles (e.g., a single "Builder" agent for all implementation), 20+ micro-agents with even narrower scope, dynamically spawned agents per task.

**Rationale**: Each agent's system prompt is tightly focused so the model is not distracted by irrelevant domain knowledge. A `data-engineer` prompt contains PySpark patterns, Delta Lake writes, and dbt models. It does not contain RAG pipelines or SQL optimization. Domain expertise lives in skills (loaded on demand), not in agent count. The agents follow identical workflow patterns (state machine, retry, escalation) but with different domain content. Adding a new domain means creating a new agent prompt and a matching skill, not redesigning the workflow. The three additional (story-master, story-planner, close-story) are PLAN-phase agents with narrow scope: decomposition, per-story planning, and verify-and-stamp respectively. They activate only on the Plan Phase path, gated by a human decision at Gate 0, so they do not apply when SPEC is small or self-contained.

**Trade-off**: More agents means more handoff points and more potential for context loss at transitions. Each handoff costs ~500-2000 tokens in context transfer. The handoff chain structure (where the Guardian saves its review report to `.copilot/artifacts/review-report.md` for downstream agents to read) and the session state protocol mitigate this, but do not eliminate it.

---

### Decision 6: Subagent Status Protocol Over Free-Form Returns

**Choice**: Every subagent must return exactly one of four statuses (`DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, `BLOCKED`) with defined semantics and orchestrator actions.

**Alternatives Considered**: Free-form subagent responses parsed by the orchestrator, binary success/failure, no status protocol (orchestrator infers from output).

**Rationale**: Free-form responses require the orchestrator to spend context budget parsing and interpreting what the subagent meant. A formal protocol makes the handoff unambiguous: `BLOCKED` means escalate to Architect, `NEEDS_CONTEXT` means re-dispatch with missing information, `DONE_WITH_CONCERNS` means proceed to review but include the concerns. This eliminates an entire class of orchestration failures where the orchestrator misinterprets a subagent's output.

**Trade-off**: The protocol is rigid. A subagent that encounters a situation outside the four statuses must shoehorn its response into the closest match. In practice, this has not been a problem. The four statuses cover the decision space well.

---

### Decision 7: Artifact Persistence Over In-Context Handoff

**Choice**: Pipeline artifacts (specs, review reports, holdout files) are persisted to well-known paths under `.copilot/` rather than passed purely through conversation context.

**Alternatives Considered**: Pure in-context passing (each agent hands the full artifact to the next via conversation), external storage (database or API), no artifact persistence (each agent re-derives what it needs).

**Rationale**: Conversation context is ephemeral. It exists only within a single session and a single agent's context window. When sessions end or agents change, in-context artifacts are lost. Persisting to `.copilot/specs/SPEC.md`, `.copilot/artifacts/review-report.md`, and `.copilot/holdout/` means downstream agents can load upstream outputs in any session, even days later. The Context Engineer's file layout (defined in `skills/context-engineer/SKILL.md`) standardizes the paths so agents know where to look.

**Trade-off**: File persistence means agents must check for artifacts at known paths, adding a lookup step to each phase. The "MANDATORY" pre-implementation checklist in the Senior Developer agent (check for spec at `.copilot/specs/SPEC.md`) and the Guardian's fallback spec lookup encode this discipline into each agent's workflow.

---

### Decision 8: Hooks as Layer 0 Structural Enforcement

**Choice**: Add a platform-level hook harness (`hooks/*.ps1` + `hooks.json`) that enforces quality contracts outside the language model, complementing the instruction-based behavioral guidance in agent prompts.

**Alternatives Considered**: Rely entirely on agent instructions ("always run ruff before finishing"), Guardian review as the sole quality gate, Git pre-commit hooks (post-session, not within the active session), CI/CD quality gates (post-push).

**Rationale**: Agent instructions are probabilistic. A model may follow them 95% of the time but fails under context pressure, in long sessions, or when a competing priority seems more urgent. VS Code's hook API provides a lighter-weight enforcement point that fires within the agent session, not after it. A Stop hook blocking the session close is cheaper in total session cost than a Guardian re-review cycle triggered by a lint failure caught only at review time.

---

## What Was Deliberately Left Out

**Dynamic agent spawning**: The system uses a fixed registry of 15 agents. There is no mechanism to dynamically create new agents at runtime based on task characteristics. This was left out because the current roster covers the target domains (Data, GenAI, ML Engineering) and adding dynamic spawning would require a meta-agent layer with its own coordination overhead.

**Cross-agent shared memory within a session**: Agents communicate through artifacts and handoffs, not through a shared memory store. A shared memory system would reduce handoff friction but introduce consistency challenges (which agent's write wins?) and blur the clean separation between pipeline phases.

**Automated retrospectives**: The retrospective process exists as a prompt (`/retrospective`) and the Context Engineer skill includes templates, but retrospectives are not triggered automatically. This requires human discipline. The system cannot yet measure itself without a human pulling the trigger.

**Fine-grained progressive autonomy**: The system has a coarse autonomy slider (quick-fix = high trust, full pipeline = lower trust, 3-strike escalation = intervention), but it does not yet expand an agent's autonomy based on demonstrated reliability over time. This is a future improvement that the retrospective process should surface.

---

## Closing Note

The Mega Minions are not a collection of clever prompts. They are an engineered system with layered architecture, structural constraints, and deliberate trade-offs. Every design choice exists for a reason, and those reasons are grounded in research, in failure modes observed during development, and in the central thesis of this project:

**Capability is no longer scarce. Specification is.**

The system is designed to make specification tractable, implementation reliable, and validation structural. If you are extending it, the test is simple: does your change make the system better at specifying, implementing, or validating? If yes, it belongs. If it makes the system "more capable" without improving those three things, it is probably the wrong change.

---

*Architecture of the Mega Minions, authored for builders who want to understand before they extend.*

