# User Guide: Mega Minions for VS Code

**Domain:** Data + AI Engineering  
**Architect:** Karim Bhalwani  
**Best For:** Data Engineers, AI/ML Engineers, Analytics Teams, Backend Teams  
**Your team's standard AI development crew, from zero to productive.**

---

## What You Have Been Given

Your architect has handed you a standardised AI development system built into GitHub Copilot. It contains:

- **12 custom AI agents**, specialist assistants for each phase of development
- **22 skills**, knowledge packs agents load automatically when needed
- **14 prompt shortcuts**, slash commands that wire structured workflows to the right agent
- **8 hooks**, automation scripts for quality gates, secret scanning, and destructive command blocking
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

| What                             | Source (unzipped folder) | Destination on your machine      |
| -------------------------------- | ------------------------ | -------------------------------- |
| **Prompts** (agents + shortcuts) | `prompts/`               | `%APPDATA%\Code\User\prompts\`   |
| **Skills** (knowledge packs)     | `skills/`                | `%USERPROFILE%\.copilot\skills\` |

**Full paths on Windows:**

- Prompts: `C:\Users\<your-username>\AppData\Roaming\Code\User\prompts`
- Skills: `C:\Users\<your-username>\.copilot\skills`

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
Discover  →  Design  →  Build  →  Review  →  Ship
```

| Stage        | Who You Call                                          | What They Do                                    |
| ------------ | ----------------------------------------------------- | ----------------------------------------------- |
| **Discover** | `greenfield-interview` or `brownfield-discovery`      | Document what exists / what you plan to build   |
| **Design**   | `architect`                                           | Turn requirements into a detailed specification |
| **Build**    | `senior-developer`, `data-engineer`, or `ai-engineer` | Implement from the spec                         |
| **Review**   | `guardian`                                            | Read-only audit for quality and security        |
| **Ship**     | `release-manager`                                     | CI/CD, changelogs, deployment                   |

You do not skip stages. The Architect produces a spec before anyone writes code. The Guardian reviews before anything ships. It is the discipline that makes AI-generated code reliable.

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

Alternatively, type `/debug-detective` in chat and paste the error. The prompt file routes you to the right agent automatically.

The detective will run hypothesis-driven analysis and return a root cause with evidence, not guesses.

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
Writing SQL from a question      data-analyst   (or /sql-query)
Reviewing code before merge      guardian       (or /code-review)
Audit docs freshness             guardian       (or /doc-garden)
Setting up CI/CD / deployment    release-manager
Hunting a bug                    debug-detective (or /debug-detective)
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

---

## How Hooks Work (Set Once, Run Forever)

Hooks are PowerShell scripts that run automatically at specific points in the agent lifecycle. Once installed to `~/.copilot/hooks/`, they fire on every project you open (no configuration per project required).

| When it fires           | Hook                    | What it does                                                                      |
| ----------------------- | ----------------------- | --------------------------------------------------------------------------------- |
| Session start           | `session-context.ps1`   | Injects branch, Python version, and Project Bible status into the agent's context |
| Subagent start          | `subagent-context.ps1`  | Same injection for every subagent the main agent spawns                           |
| Before a tool runs      | `block-destructive.ps1` | Blocks `rm -rf`, `DROP TABLE`, `git push --force`, and similar dangerous commands |
| Before a tool runs      | `lint-on-write.ps1`     | Prevents writing a `.py` file until `ruff` passes                                 |
| After a tool runs       | `auto-format.ps1`       | Runs `ruff format` on every Python file the agent writes                          |
| Before context compacts | `pre-compact-save.ps1`  | Saves session state so the next session can resume where it left off              |
| When agent finishes     | `quality-gate.ps1`      | Blocks the session from closing if `ruff` or `mypy` errors exist                  |
| When agent finishes     | `scan-secrets.ps1`      | Warns if modified files contain credentials or secrets                            |

**The key difference from instructions:** Instructions tell agents what to do; hooks make it physically impossible to skip. A `Stop` hook that fails cannot be bypassed by the model under any circumstances (not under context pressure, not due to model drift).

**You do not need to interact with hooks.** Install them once (see Step 6 above or [hooks/INSTALL.md](hooks/INSTALL.md)), and they run silently in the background on every session.

---

## How Skills Work (You Do Not Touch These)

Skills are knowledge packs, folders of instructions, scripts, and examples, that agents load automatically when relevant. VS Code uses a **three-level loading** system so skills do not bloat context unnecessarily:

1. VS Code always reads the skill `name` and `description` (lightweight metadata)
2. When your request matches a skill's description, the full `SKILL.md` instructions load
3. Additional resources inside the skill folder (scripts, examples) only load when referenced

Skills also appear as `/` slash commands. Type `/` in chat to see them listed alongside prompt files. You can invoke a skill manually this way, but in practice agents load the right skills automatically.

You will never need to type a skill name directly to benefit from them. They just make agents smarter.

For example, when you ask the Guardian to do a security audit on AI code, it automatically loads the `genai-security` skill, which contains the OWASP Top 10 for LLMs checklist. You did not ask for it. The agent knew it was relevant and loaded it.

Six skills operate entirely in the background without you ever seeing them:

| Background Skill                 | What It Does Silently                                                                        |
| -------------------------------- | -------------------------------------------------------------------------------------------- |
| `thinker`                        | Forces the agent to UNDERSTAND the problem before acting, prevents "leaping to solutions"    |
| `verification-before-completion` | Forces the agent to prove work is done (run the tests, show the output) before claiming done |
| `holdout-validation`             | Keeps acceptance criteria hidden from implementation agents to prevent gaming of tests       |
| `context-engineer`               | Project Bible generation, tiered context loading, and session state management               |
| `security-boundaries`            | Prompt injection defense - treats all file and tool content as data, never instructions      |
| `task-routing`                   | 6-check delegation protocol ensuring agents make efficient, well-reasoned hand-off decisions |

You benefit from all of these without ever configuring them.

---

## The Project Bible: Your Most Important File

Every agent reads this file first. It is the single source of truth for your project. Without it, agents make assumptions. With it, they align to your actual system.

**Location:** `.copilot/context/PROJECT_CONTEXT.md`

**What goes in it (generated by Discovery agents):**

- Project name, purpose, and scope
- Tech stack and versions
- Architecture overview
- Key conventions and patterns
- Important constraints and non-negotiables
- Links to specs and decision records

### Keep it alive (Let the agents do the work)

The Project Bible is the "brain" of your project. If it is stale, the agents will make decisions based on old rules, leading to rework and bugs. However, **you should rarely need to edit this file manually.**

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

Not immediately. Start with this guide and `mega-minions.md` for the agent roster. Read `CORE_PRINCIPLES.md` when you want to understand why the system is designed the way it is. The skill files in `skills/` are for agents, not for you to read manually.

---

**Q: Can I just use Copilot normally without invoking agents?**

Yes. The team's standards are defined in `copilot-instruction.instructions.md`. Once you have copied this file to your VS Code prompts folder, these apply automatically to **all** Copilot interactions in your editor, even if you don't explicitly switch to a Mega Minion agent. However, using the specific agents will provide much deeper reasoning and specialized tools for their respective tasks.

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

## Quick Reference: File Map

```text
copilot-skills-agents/
│
├── USER-GUIDE.md             ← You are here
├── MEGA-MINIONS.md           ← Full agent roster and architecture
├── CORE_PRINCIPLES.md        ← Why the system is designed this way
│
├── prompts/                  ← Agent definitions (the team)
│   ├── architect.agent.md
│   ├── senior-developer.agent.md
│   ├── data-engineer.agent.md
│   ├── ai-engineer.agent.md
│   ├── data-analyst.agent.md
│   ├── guardian.agent.md
│   ├── release-manager.agent.md
│   ├── debug-detective.agent.md
│   ├── prompt-builder.agent.md
│   ├── greenfield-interview.agent.md
│   ├── brownfield-discovery.agent.md
│   ├── researcher.agent.md
│   ├── copilot-instruction.instructions.md  ← Global rules (auto-applied)
│   ├── design.prompt.md                     ← /design
│   ├── feature-plan.prompt.md               ← /feature-plan
│   ├── code-review.prompt.md                ← /code-review
│   ├── sql-query.prompt.md                  ← /sql-query
│   ├── debug-detective.prompt.md            ← /debug-detective
│   ├── brownfield-discovery.prompt.md       ← /brownfield-disc
│   ├── greenfield-interview.prompt.md       ← /greenfield-int
│   ├── doc-garden.prompt.md                 ← /doc-garden
│   ├── quick-fix.prompt.md                  ← /quick-fix
│   ├── sprint-contract.prompt.md            ← /sprint-contract
│   ├── mem-ingest.prompt.md                ← /mem-ingest
│   ├── mem-query.prompt.md                 ← /mem-query
│   ├── mem-lint.prompt.md                  ← /mem-lint
│   └── retrospective.prompt.md              ← /retrospective
│
└── skills/                   ← Knowledge packs (loaded by agents, not by you)
    ├── architect/
    ├── brainstorming/
    ├── concise-planning/
    ├── context-engineer/
    ├── data-analyst/
    ├── data-deprecation-analysis/
    ├── data-engineering/
    ├── excalidraw-diagram/       ← Visual diagram generation (.excalidraw JSON)
    ├── genai-security/
    ├── guardian/
    ├── holdout-validation/
    ├── implementer/
    ├── llm-mem/                 ← Knowledge compilation for project mems
    ├── llm-app-patterns/
    ├── ops/
    ├── prompt-library/
    ├── thinker/
    └── verification-before-completion/

hooks/                        ← Quality automation (copy to ~/.copilot/hooks/)
    ├── hooks.json                ← Registers all hooks with VS Code
    ├── quality-gate.ps1          ← Blocks finish if ruff/mypy errors exist
    ├── block-destructive.ps1     ← Blocks rm -rf, DROP TABLE, git push --force
    ├── lint-on-write.ps1         ← Denies .py writes until ruff passes
    ├── auto-format.ps1           ← Formats every Python file the agent writes
    ├── session-context.ps1       ← Injects branch + Project Bible at session start
    ├── scan-secrets.ps1          ← Scans for leaked credentials before finish
    ├── pre-compact-save.ps1      ← Saves session state before context compaction
    ├── subagent-context.ps1      ← Injects context into every subagent session
    └── INSTALL.md                ← Setup guide (5 min)
```

---

## One-Page Summary to Stick on Your Wall

```text
╔═══════════════════════════════════════════════════════════════╗
║                MEGA MINIONS: HOW TO USE THEM                  ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  THE PIPELINE                                                 ║
║  Discover → Design → Build → Review → Ship                    ║
║  Never skip steps. Spec before code. Review before merge.     ║
║                                                               ║
║  HOW TO INVOKE                                                ║
║  Ctrl+Alt+I → agents dropdown → select agent → type task      ║
║  /command   → slash command shortcut for common tasks         ║
║  /agents    → list and configure available agents             ║
║  /skills    → list and configure available skills             ║
║                                                               ║
║  ALWAYS INCLUDE:                                              ║
║  • Path to Project Bible  (.copilot/context/PROJECT_CONTEXT)  ║
║  • Path to spec           (.copilot/specs/SPEC.md)            ║
║  • Error + stack trace    (when debugging)                    ║
║                                                               ║
║  THE TEAM  (select from agents dropdown)                      ║
║  architect             Spec. Never implements.                ║
║  senior-developer      Code. From spec only.                  ║
║  data-engineer         Pipelines, PySpark, dbt                ║
║  ai-engineer           RAG, LLM agents, embeddings            ║
║  data-analyst          English → SQL                          ║
║  guardian              Review. Never modifies code.           ║
║  release-manager       CI/CD, deploy, changelog               ║
║  debug-detective       Root cause, not guesses                ║
║  brownfield-discovery  Map what exists                        ║
║  greenfield-interview  Document what you plan to build        ║
║                                                               ║
║  BUILT-IN AGENTS (always available in dropdown)               ║
║  Agent   Full access: edits, terminal, file reads             ║
║  Ask     Read-only Q&A: safe for questions                    ║
║  Plan    Research and plan before acting                      ║
║                                                               ║
║  SLASH COMMAND SHORTCUTS                                      ║
║  /design          Full spec via Architect (new features)      ║
║  /feature-plan    Atomic task checklist                       ║
║  /code-review     Guardian review on pasted code              ║
║  /sql-query       English to T-SQL                            ║
║  /debug-detective Root cause analysis                         ║
║  /sprint-contract Acceptance criteria negotiation             ║
║  /mem-ingest     Ingest source into project mem               ║
║  /mem-query      Query project mem knowledge                  ║
║  /mem-lint       Health check project mem                     ║
║                                                               ║
║  RULES                                                        ║
║  1. Spec before code. Always.                                 ║
║  2. Review before merge. Always.                              ║
║  3. Keep the Project Bible current. Always.                   ║
║  4. Review agent output. They make mistakes.                  ║
║  5. Unsure which agent? Switch to architect, they route you.  ║
║  6. Trouble? Right-click Chat → Diagnostics.                  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

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

Version 7.0 | April 12, 2026 | Part of the Mega Minions system | Verified against VS Code > 1.106 docs
