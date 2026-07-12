# User Guide: Mega Minions for VS Code

**Domain:** Data + AI Engineering  
**Architect:** Karim Bhalwani  
**Best For:** Data Engineers, AI/ML Engineers, Analytics Teams, Backend Teams  
**Your team's standard AI development crew, from zero to productive.**

---

## What You Have Been Given

Your architect has handed you a standardised AI development system built into GitHub Copilot. It contains:

- **16 custom AI agents**, specialist assistants for each phase of development
- **26 skills**, knowledge packs agents load automatically when needed
- **16 prompt shortcuts**, slash commands that wire structured workflows to the right agent
- **15 hooks**, automation scripts (all registered in `hooks.json`, including `verify-hook-integrity.ps1` as a SessionStart integrity check) for quality gates, secret scanning, holdout access enforcement, destructive command blocking, prompt-injection detection, post-subagent artifact verification, retrospective reminders, subagent budget caps, and artifact manifest logging
- **Reference documents**: philosophy, architecture, and comprehensive pattern guides for the whole team

This is your team's **standard**. Everyone uses the same agents, the same patterns, and the same quality bar. That is the point.

---

## Before You Start: Two-Minute Setup Check

### Step 1: VS Code

If you do not have VS Code installed:

1. Download from [code.visualstudio.com](https://code.visualstudio.com)
2. Install it with all default options

### Step 2: GitHub Copilot Extension

1. Open VS Code
2. Press `Ctrl+Shift+X` (Windows) to open the Extensions panel
3. Search for **GitHub Copilot** and install it. Chat is now bundled inside the same extension (VS Code 1.100+)
4. Sign in with your GitHub account when prompted (you need a Copilot & GitHub Enterprise subscription)

### Step 3: Unzip the Shared Files

1. Locate the `.zip` file shared by your architect.
2. Unzip the contents to a folder on your local machine.
3. Verify that you see the `prompts/` and `skills/` folders in the file explorer.

### Step 4: Install the Skills and Prompts

> **This is the most important setup step.** Without it, the custom agents and skills will not be available in VS Code Copilot Chat.

The skills and prompts need to be copied to two specific locations on your machine. Once placed there, VS Code picks them up automatically; they work globally across **every project you open**.

#### Where things go

| What                                | Source (unzipped folder) | Destination on your machine            |
| ----------------------------------- | ------------------------ | -------------------------------------- |
| **Prompts** (agents + shortcuts)    | `prompts/`               | `%APPDATA%\Code\User\prompts\`         |
| **Skills** (knowledge packs)        | `skills/`                | `%USERPROFILE%\.copilot\skills\`       |
| **Instructions** (coding standards) | `instructions/`          | `%USERPROFILE%\.copilot\instructions\` |

**Full paths on Windows:**

- Prompts: `C:\Users\<your-username>\AppData\Roaming\Code\User\prompts`
- Skills: `C:\Users\<your-username>\.copilot\skills`
- Instructions: `C:\Users\<your-username>\.copilot\instructions`

---

**Prompts:**

1. Open File Explorer and navigate to the unzipped `prompts\` folder
2. Select all files (`Ctrl+A`)
3. Navigate to `C:\Users\<your-username>\AppData\Roaming\Code\User\`
4. Create a `prompts` folder here if one does not exist
5. Paste all files into it

**Skills:**

1. Open File Explorer and navigate to the unzipped `skills\` folder
2. Select all folders (`Ctrl+A`)
3. Navigate to `C:\Users\<your-username>\`
4. Create a `.copilot` folder if one does not exist, then create a `skills` folder inside it
5. Paste all skill folders into `.copilot\skills\`

**Instructions:**

1. Open File Explorer and navigate to the unzipped `instructions\` folder
2. Select all files (`Ctrl+A`)
3. Navigate to `C:\Users\<your-username>\`
4. If `.copilot` folder does not exist, create it
5. Create an `instructions` folder inside `.copilot` (if it doesn't exist)
6. Paste all instruction files into `.copilot\instructions\`

> **Tip:** `AppData` is a hidden folder. In File Explorer, type `%APPDATA%` directly into the address bar and press Enter. It will take you straight there without needing to unhide hidden folders.

---

### Step 5: Verify Setup Works

1. Open VS Code
2. Open Copilot Chat (`Ctrl+Alt+I` on Windows)
3. Click the agent selector dropdown at the top of the chat panel
4. You should see **architect**, **senior-developer**, **guardian**, and others in the list
5. Select **architect** and type a test message (e.g., "hello")

If you see custom agents in the dropdown, setup is complete. If not, double-check that files were pasted to the correct paths in Step 4.

---

### Step 6: Install Hooks for Automatic Quality Gates

Hooks are automation scripts that enforce quality standards automatically. They block destructive commands, run formatters, scan for leaked secrets, and inject context at session start.

**Benefits:** Automatic linting, prevented accidents (rm -rf blocks), secret detection before commit.

**How to install:** See [hooks/INSTALL.md](hooks/INSTALL.md) for detailed setup (5 minutes). If you skip this step, agents still work perfectly - hooks are a convenience for quality automation.

---

#### Keeping skills and prompts up to date

When the architect updates the shared files with new or improved agents, re-run the steps above to copy the new files. Your Project Bible and specs are stored inside your projects, not in these folders, so updating never touches your work.

---

## The Mental Model: One Idea to Understand Everything

Before touching anything, understand this one idea:

> **Think of the Mega Minions as a team of specialists, not a single assistant.**

You would not ask your database expert to write the deployment pipeline. You would not ask the security auditor to also write the feature. The Mega Minions work the same way. Each one has a job, does that job well, and passes the work to the next specialist.

The work flows in a pipeline:

```text
Discover  →  Design  →  [Plan]  →  Build  →  Review  →  Ship
```

| Stage        | Who You Call                                                            | What They Do                                                                   |
| ------------ | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Discover** | `greenfield-interview` or `brownfield-discovery`                        | Document what exists / what you plan to build                                  |
| **Design**   | `architect`                                                             | Turn requirements into a detailed specification                                |
| **Plan**     | `story-master`, then `story-planner`                                    | Decompose SPEC into stories and per-story plans (Gate 0: Plan Phase path only) |
| **Build**    | `senior-developer`, `data-engineer`, `data-scientist`, or `ai-engineer` | Implement from the spec                                                        |
| **Review**   | `guardian`                                                              | Read-only audit for quality and security                                       |
| **Ship**     | `release-manager`                                                       | CI/CD, changelogs, deployment                                                  |

You do not skip stages. The Architect produces a spec before anyone writes code. When Gate 0 routes to Plan Phase (3 or more deliverables, shared dependencies, or a Scope change), the PLAN phase runs before any BUILD agent touches code. The Guardian reviews before anything ships. It is the discipline that makes AI-generated code reliable.

---

## How to Invoke an Agent

### Understanding the Chat View

VS Code ships with three **built-in default agents** you already have:

| Built-in Agent | Purpose                                               |
| -------------- | ----------------------------------------------------- |
| **Agent**      | Full access: can read files, run terminals, edit code |
| **Ask**        | Read-only Q&A, safe for questions and exploration     |
| **Plan**       | Planning mode, research and plan before acting        |

The Mega Minions are **custom agents** that sit alongside these in the same dropdown. They give each specialist role its own tailored behaviour and tool access.

### Agents Dropdown (how you switch agents)

1. Open GitHub Copilot Chat (`Ctrl+Alt+I` on Windows)
2. At the top of the Chat input field you will see the **current agent name** (e.g. "Agent"). Click it to open the agents dropdown
3. Select the agent you want, for example **architect**
4. The Chat view is now in architect mode. Type your request and press Enter

---

## Your First Week: Build Muscle Memory

Work through these in order. Each one is a real workflow you will repeat constantly.

---

### Day 1: Understand What You Are Building

**Existing project:**

```text
[Switch to: brownfield-discovery]
Map this codebase. Start with the package managers and work down.
```

The agent will systematically explore the code and produce a **Project Bible**, a structured document that becomes the shared context for every other agent. Save it at `.copilot/context/PROJECT_CONTEXT.md`.

**New project:**

```text
[Switch to: greenfield-interview]
I want to build a data pipeline that ingests data into a data lake
```

The agent will ask you structured questions one at a time and produce a founding Project Bible from your answers.

> **Why this matters:** Every other agent reads the Project Bible before doing any work. The quality of everything downstream depends on how clearly this document captures your project. Do not skip it.

---

### Day 2: Design Before You Build

Once you have a Project Bible and a feature to implement:

```text
[Switch to: architect]
Design the ingestion layer for the data pipeline.
See the Project Bible at .copilot/context/PROJECT_CONTEXT.md
```

The Architect will first ask you to choose a **scope mode** (REDUCTION for simple fixes, HOLD for features within existing architecture, EXPANSION for new modules). Then it asks clarifying questions and produces a `SPEC.md` covering module boundaries, API contracts, data models, error handling (with an Error & Rescue Map), security, performance requirements, and testing strategy.

**Read the spec before approving it.** If something looks wrong, say so:

```text
[Switch to: architect]
The error handling section assumes synchronous retries but our pipeline is async.
Revise section 5.
```

Implementation does not begin until you are happy with the spec.

> **Optional (Acceptance Criteria Negotiation):** For multi-agent or multi-day builds, run `/sprint-contract` between Design and Build to formally negotiate scope, agent assignments, and acceptance criteria before implementation starts.

---

### Day 3: Implement From the Spec

Hand the approved spec to the right builder:

```text
[Switch to: senior-developer]
Implement the authentication module from the approved spec at .copilot/specs/SPEC.md
```

or for data work:

```text
[Switch to: data-engineer]
Build the Salesforce ingestion pipeline from the approved spec at .copilot/specs/SPEC.md
```

The builder will:

1. Read the spec
2. Run existing tests to establish a baseline
3. Write tests first and confirm they fail (RED)
4. Implement code to make tests pass (GREEN)
5. Run linters and type checks before claiming done

You will see responses starting with `## **Senior Developer**: [what it is doing]`. This is the standard output format so you always know which agent is speaking.

---

### Day 4: Review Before You Merge

After implementation, invoke Guardian:

```text
[Switch to: guardian]
Review the implementation in src/auth/ against the spec at .copilot/specs/SPEC.md.
Run a full code review and security audit.
```

Guardian will run a **three-phase review** and produce a structured report with **severity-rated findings**:

- **Critical**, must be fixed before merge (security vulnerabilities, data corruption risks)
- **High**, should be fixed before merge
- **Medium**, fix soon, not blocking
- **Low**, consider fixing, not urgent

A Critical or High finding means the work goes back to the builder with the report. This is normal. Do not merge until these are resolved.

---

### Day 5: Debug When Things Break

When something breaks in development or production:

```text
[Switch to: debug-detective]
Application throws KeyError: 'customer_id' in the ETL job.
Here is the stack trace: [paste stack trace]
```

Alternatively, type `@debug-detective` in chat and paste the error. The agent runs the same workflow with no prompt shell neededd.

The detective will run hypothesis-driven analysis and return a root cause with evidence, not guesses.

---

## PLAN Phase Walkthrough

### When Does the PLAN Phase Activate?

After the Architect produces `SPEC.md` and you review it at Gate 0, you choose whether to route work directly to a BUILD agent (Build Direct path) or activate the PLAN phase. The PLAN phase is the right choice when your SPEC has `Scope: EXPANSION` or `Scope: REDUCTION` (any size), or when it has 3 or more deliverables with shared dependencies. Clicking `[ Approve: Plan Phase ]` at Gate 0 triggers the full backlog and planning workflow described below.

### Step-by-Step Walkthrough

1. **Architect produces `SPEC.md` and stops at Gate 0.** The SPEC includes a Scope tag (`HOLD`, `EXPANSION`, or `REDUCTION`) and the Architect's routing recommendation.
2. **Human clicks `[ Approve: Plan Phase ]`.** You can override the Architect's recommendation; the button click is your final decision.
3. **story-master decomposes the SPEC** into `.copilot/stories/STORIES.md` (stories, execution waves, dependency graph, security flags, risk levels) plus `.copilot/stories/.active-story` (a pointer to the first story). story-master stops at Gate 1.
4. **Human reviews the backlog at Gate 1.** Check story decomposition, wave groupings, and dependency chains. Adjust the `.active-story` pointer if needed, then invoke story-planner.
5. **Human invokes story-planner** (no argument reads `.active-story`; an explicit `US-{id}` argument or `STORY_ID` env var overrides). story-planner scans the live codebase for patterns to follow, emits a Plan Preview for your confirmation, runs SPEC Directive Traceability (every MUST / SHALL / never directive mapped to a task), audits test infrastructure (prepends T-00 scaffolding tasks for missing test files), and runs a separate-judge Plan Checker Loop (AC coverage, SPEC directives, dependency boundary, task atomicity). Output: `US-{id}-PLAN.md` + `US-{id}-VALIDATION.md`. story-planner stops at Gate 2.
6. **Human reviews the plan at Gate 2** and clicks a BUILD handoff button (Senior Developer, Data Engineer, or AI Engineer).
7. **BUILD agent walks the task list**, ticks each checkbox, runs the Validate command after each task, and writes `reports/US-{id}-report.md` before handing off to Guardian.
8. **Guardian reviews the implementation.** If the story is Security-Sensitive, Guardian auto-loads the `genai-security` skill. A Critical or High finding routes work back to the BUILD agent.
9. **Release Manager runs the standard ship steps** (CI check, changelog, merge) and clicks `[ Close Story ]`.
10. **close-story stamps the STORIES.md row** (`Status: done`), updates `.active-story` to the next not-started story in the wave, and confirms all tasks and acceptance criteria are complete.

### Build Direct vs Plan Phase: Which Path?

| Signal                                                         | Recommended path                                                              |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `Scope: HOLD`, 2 or fewer deliverables, no shared dependencies | Build Direct - pick the matching specialist (Senior Dev, Data Eng, or AI Eng) |
| `Scope: HOLD`, 3 or more deliverables, or shared dependencies  | Plan Phase                                                                    |
| `Scope: EXPANSION` or `REDUCTION` (any size)                   | Plan Phase                                                                    |
| Used `/feature-plan` directly (no `SPEC.md` exists)            | Build Direct                                                                  |

These are the Architect's recommendations only. You have final say by clicking the button that matches your intent at Gate 0.

### Branch and PR Conventions

When working a PLAN phase story, follow these conventions to keep PRs traceable to the backlog:

- **Branch:** `story/US-{id}-{kebab-slug}` (example: `story/US-01-user-auth`)
- **PR title:** `US-{id}: {story title}` (example: `US-01: User authentication`)
- **PR body:** must include `Closes US-{id}` and a link to `.copilot/stories/reports/US-{id}-report.md`
- **One story per PR.** Stories listed as Coupled Pairs in `STORIES.md` get separate PRs; call out the mandated merge order in each PR body.

### Working Multiple Stories in Parallel

If your team is working multiple stories in the same wave simultaneously, each developer should set `STORY_ID` in their shell before invoking story-planner or the BUILD agent:

```powershell
$env:STORY_ID = "US-03"
```

The `STORY_ID` env var overrides `.active-story` for `session-context.ps1`, `quality-gate.ps1`, and story-planner's story resolution. This lets two developers work wave-1 stories side by side without racing on the shared `.active-story` file.

---

## The Daily Cheatsheet

Keep it handy until the patterns are natural. For full copy-paste examples with detailed explanations, see [PROMPT-CHEATSHEET.md](PROMPT-CHEATSHEET.md).

> **HOW TO READ THIS TABLE:** The agent column shows who to select from the **agents dropdown** in Chat.

```text
WHAT ARE YOU DOING?              AGENTS DROPDOWN → SELECT:
────────────────────────────────────────────────────────────
Joining a project cold           brownfield-discovery
Starting from scratch            greenfield-interview
Designing a new feature          architect      (or /design)
Writing code from a spec         senior-developer
Building a data pipeline         data-engineer
Building an AI / RAG system      ai-engineer
Writing SQL from a question      @data-analyst  (or /sql-query)
Dataset → evidence-grounded report /data-narrative
Reviewing code before merge      guardian       (or /code-review)
Audit docs freshness             guardian       (or /doc-garden)
Setting up CI/CD / deployment    release-manager
Hunting a bug                    @debug-detective
Creating or improving a prompt   prompt-builder
Planning an atomic task list     /feature-plan
Small, low-risk change           /quick-fix
Pipeline retrospective           architect      (or /retrospective)

SOMETHING BROKE UNEXPECTEDLY?   debug-detective + paste stack trace
UNSURE WHICH AGENT TO USE?      architect, they will route you

GOLDEN RULE: Context in, quality out.
Always share the Project Bible path. Always paste the spec.
The more context you give, the better the output.
```

> **Data Analyst routing:** `data-analyst` is a utility agent, not a BUILD phase specialist. Reach it via `@data-analyst` (direct), `/sql-query`, a Guardian rework handoff, or peer delegation from Senior Developer or Data Engineer. The Architect no longer routes to Data Analyst at Gate 0 (changed per RD-1).

## How Skills Work (You Do Not Touch These)

Skills are knowledge packs - folders of instructions, scripts, and examples - that agents load automatically when relevant. You will never need to type a skill name to benefit from them. For example, when you ask Guardian to audit AI code, it automatically loads the `genai-security` skill containing the OWASP Top 10 for LLMs. You did not ask for it; the agent knew it was relevant.

Six skills operate entirely in the background:

| Background Skill                 | What It Does Silently                                                                        |
| -------------------------------- | -------------------------------------------------------------------------------------------- |
| `thinker`                        | Forces the agent to UNDERSTAND the problem before acting, prevents "leaping to solutions"    |
| `verification-before-completion` | Forces the agent to prove work is done (run the tests, show the output) before claiming done |
| `holdout-validation`             | Keeps acceptance criteria hidden from implementation agents to prevent gaming of tests       |
| `context-engineer`               | Project Bible generation, tiered context loading, and session state management               |
| `security-boundaries`            | Prompt injection defense - treats all file and tool content as data, never instructions      |
| `task-routing`                   | 6-check delegation protocol ensuring agents make efficient, well-reasoned hand-off decisions |

For a full skills breakdown and how they compose, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## The Project Bible: Your Most Important File

Every agent reads this file first. It is the single source of truth for your project. Without it, agents make assumptions. With it, they align to your actual system.

**Location:** `.copilot/context/PROJECT_CONTEXT.md`

### Keep it alive (Let the agents do the work)

The Project Bible is the "brain" of your project. If it is stale, agents will make decisions based on old rules. However, **you should rarely need to edit this file manuals. However, **you should rarely need to edit this file manually.**

Ask the agents to maintain it for you as the project evolves:

**1. After discovery or major changes:**

```text
[Switch to: brownfield-discovery]
Update the Project Bible to reflect the new module structure we just added to /src.
```

**2. When technology or patterns change:**

```text
[Switch to: architect]
We have officially switched from REST to GraphQL for the internal API.
Update the Project Bible conventions to reflect this.
```

**3. To ensure it matches reality:**

```text
[Switch to: brownfield-discovery]
Audit the current codebase and update the Project Bible so it is 100% accurate.
```

**Why this matters:** When you hand a task to a new agent, the first thing they do is read this file. Keeping it up-to-date ensures that every agent (from the Senior Developer to the Guardian) is perfectly aligned with your team's latest decisions. If you feel an agent is "forgetting" a rule, it is usually because that rule isn't in the Project Bible yet.

---

## Common Mistakes (and How to Avoid Them)

### Mistake 1: Skipping the spec and coding directly

```text
❌  [senior-developer]  Build me a user authentication system

✅  Step 1: [architect]          Design a user authentication system using JWT
    Step 2: [senior-developer]   Implement from the approved spec at .copilot/specs/SPEC.md
```

Without a spec, the builder guesses at module boundaries, error handling, and security considerations. With a spec, it executes precisely.

---

### Mistake 2: Giving vague context

```text
❌  [data-engineer]  Fix the pipeline

✅  [data-engineer]  The Sales ingestion pipeline at src/ingestion/sales.py fails
                    with a schema mismatch error on the Opportunity object.
                    Spec is at .copilot/specs/SPEC.md. Stack trace: [paste error]
```

The more specific the context, the more precise the output. Vague in, vague out.

---

### Mistake 3: Merging without a Guardian review

The guardian exists specifically to catch what builders miss: security vulnerabilities, edge cases, performance problems, and test gaps. A review is not optional overhead. It is the quality gate.

---

### Mistake 4: Not updating the Project Bible

When your team makes a significant architectural decision (adopts a new pattern, changes the auth approach, switches databases), update the Project Bible. An agent reading a stale Project Bible will give you answers aligned to your old system, not your current one.

---

### Mistake 5: Asking one agent to do everything

```text
❌  [architect]  Design, implement, review, and deploy a new feature

✅  Step 1: [architect]         Design the feature
            [review spec with your team]
    Step 2: [senior-developer]  Implement the spec
    Step 3: [guardian]          Review the implementation
    Step 4: [release-manager]   Deploy
```

The pipeline exists for a reason. Design quality, implementation quality, and review quality each require a different lens.

---

## How Agents Hand Off to Each Other

Every agent has a **handoff button** at the end of their response. When the Architect finishes a spec, you will see something like:

```text
─────────────────────────────────────────────
Handoff: Click below to send this spec to the Senior Developer
[ Hand off to Senior Developer → ]
─────────────────────────────────────────────
```

Click it. The handoff passes just the relevant context (decisions, spec, findings) to the next agent without re-sending everything. This is intentional; it keeps each agent's context clean and focused on its current task.

---

## When Things Go Wrong

### Agent gives a wrong or low-quality answer

Correct it directly and specifically:

```text
That error handling is wrong for async code.
We use asyncio with exponential backoff, not synchronous retries.
Revise section 5 of the spec.
```

Agents learn from corrections within a session. The correction will hold for the rest of the conversation.

### Agent loops or gets stuck

The agents have a built-in 3-strike rule. If the same step fails three times, the agent will stop and escalate to you with a clear description of what is blocked. Answer the escalation with the missing information and the agent continues.

### The code does not compile or tests fail

Do not accept it. Say so:

```text
The tests are failing with: [paste error]
Fix this before we continue.
```

Agents are instructed not to claim work is done without running verification. If one does and the code is broken, correct it explicitly. Good agents catch this themselves; sometimes they need a push.

---

## Frequently Asked Questions

**Q: Do I need to read all the `.md` files in this shared folder?**

Not immediately. Start with this guide and `MEGA-MINIONS.md` for the agent roster. Read `CORE_PRINCIPLES.md` when you want to understand why the system is designed the way it is. The skill files in `skills/` are for agents, not for you to read manually.

---

**Q: Can I just use Copilot normally without invoking agents?**

Yes. The team's standards are defined in the `instructions/` folder (`core-behavior.instructions.md`, `python-standards.instructions.md`, `sql-standards.instructions.md`, `yaml-standards.instructions.md`, `powershell-standards.instructions.md`, `typescript-standards.instructions.md`, `markdown-standards.instructions.md`, `json-standards.instructions.md`, and `git-commit-standards.instructions.md`). Once you have copied these files to `.copilot\instructions\` (as described in Step4), they apply automatically to **all** Copilot interactions in your editor, even if you don't explicitly switch to a Mega Minion agent. However, using the specific agents will provide much deeper reasoning and specialized tools for their respective tasks.

---

**Q: What if I am not sure which agent to use?**

Select **architect** from the agents dropdown. It will either handle your request or tell you which agent is the right one and use the handoff button to route you there.

---

**Q: The agent said something is done but the code looks wrong. Who is right?**

You are. Treat agents like new team members: capable, enthusiastic, but not perfect. Review their output. Run the tests. If something is wrong, correct it explicitly. The agent will adjust.

---

**Q: Can agents see my private code?**

GitHub Copilot operates under our organisation's data privacy settings. Never paste production credentials, passwords, or personally identifiable data into the chat window.

---

**Q: Do I need to manually update the Project Bible every time I change something?**

**No.** In fact, it is better to ask an agent to do it. You can ask the `architect` to update the Bible when logic changes, or `brownfield-discovery` to update it after you've added new modules. This ensures the file format remains consistent and readable for other agents. See the [Keep it alive](#keep-it-alive-let-the-agents-do-the-work) section for additional details

---

## Next Steps

Once you are comfortable with basic workflows:

- **Full agent catalog with capabilities and handoff chains** → [MEGA-MINIONS.md](MEGA-MINIONS.md)
- **Copy-paste examples for every agent and slash command** → [PROMPT-CHEATSHEET.md](PROMPT-CHEATSHEET.md)
- **When to delegate vs. handle yourself** → See agent handoff chains in [MEGA-MINIONS.md](MEGA-MINIONS.md)
- **Give your project a living memory** → [LLM-MEM-GUIDE.md](LLM-MEM-GUIDE.md)
- **Understand the philosophy behind the system** → [CORE_PRINCIPLES.md](CORE_PRINCIPLES.md)
- **Architecture and engineering deep dive** → [ARCHITECTURE.md](ARCHITECTURE.md)

---

Version 9.0 | July 01, 2026 | Part of the Mega Minions system | Verified against VS Code docs
