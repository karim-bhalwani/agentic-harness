# Prompt Cheat Sheet

**Domain:** Data + AI Engineering  
**Scope:** Copy-paste prompts and slash commands for every agent, every phase  
**Version:** 9.0 | **Updated:** 01-July-2026

Copy-paste prompts for every agent and every phase. Find your situation, grab the example, go.

---

## How to Use This

**Agents** (`@name`): Open Copilot Chat (`Ctrl+Alt+I`) → click the agent selector dropdown at the top → pick the agent → type your request.

**Prompts** (`/name`): Type `/` in Copilot Chat to see the list, or copy examples below directly into the chat.

**The rule**: follow the pipeline order. Discover → Design → (Plan) → Build → Review → Ship. Don't skip phases for non-trivial work. The Plan phase is optional: after Design, you choose at Gate 0 whether to decompose into user stories first or build directly from the spec.

```text
Discover  →  Design  →  (Plan)  →  Build  →  Review  →  Ship
                           ↑
                     Optional path.
                     Human decides
                     at Gate 0.
```

> **Best practice**: Start a **new chat session** for each phase or stage. Agents perform best with a clean context window. A long conversation accumulates noise that degrades output quality. For example, use one session for `/design`, close it, then open a fresh session for `@senior-developer` to build from the spec.

---

## Quick Lookup Table

| I want to...                            | Use this                | Phase    |
| --------------------------------------- | ----------------------- | -------- |
| Start a brand new project               | `@greenfield-interview` | Discover |
| Map an existing codebase                | `@brownfield-discovery` | Discover |
| Explore data in a database              | `/sql-query`            | Discover |
| Query my project mem                   | `/mem-query`           | Discover |
| Design a feature or system              | `/design`               | Design   |
| Plan implementation steps               | `/feature-plan`         | Design   |
| Lock down acceptance criteria           | `/sprint-contract`      | Design   |
| Break a spec into a story backlog       | `@story-master`         | Plan     |
| Turn a story into an implementation plan| `@story-planner`        | Plan     |
| Verify and stamp a story as done        | `@close-story`          | Plan     |
| Build a feature from a spec             | `@senior-developer`     | Build    |
| Build a data pipeline                   | `@data-engineer`        | Build    |
| Build a RAG/AI system                   | `@ai-engineer`          | Build    |
| Fix a small bug or typo                 | `/quick-fix`            | Build    |
| Debug a failure or error                | `@debug-detective`      | Build    |
| Refine a rough prompt                   | `@prompt-builder`       | Build    |
| Review code before shipping             | `/code-review`          | Review   |
| Audit docs for staleness                | `/doc-garden`           | Review   |
| Health-check the project mem           | `/mem-lint`            | Review   |
| Set up CI/CD and deploy                 | `@release-manager`      | Ship     |
| Analyze code for fragility              | `/pre-mortem`           | Review   |
| Run a retrospective                     | `/retrospective`        | Ship     |
| Ingest a source into project mem       | `/mem-ingest`          | Ship     |

---

## End-to-End Walkthrough: Task Tracker App

This running example follows one app from idea to deployment across all 5 phases. Each step shows the exact prompt to copy and how context transfers between phases. **Start a new chat session for each phase.**

The handoff mechanism is simple: agents write artifacts to disk (specs, contracts, stories, plans, code). The next agent reads those files. You don't need to copy-paste output between sessions.

```text
 Phase 1          Phase 2            Phase 2b (optional)          Phase 3                Phase 4           Phase 5
 Discover    -->  Design        -->  Plan                    -->  Build             -->  Review       -->  Ship

 /greenfield      /design            @story-master                @senior-developer      /code-review      @release-manager
 -interview       /sprint-contract   @story-planner                                                        /retrospective
                                     @close-story

 Produces:        Produces:          Produces:                    Produces:              Produces:         Produces:
 PROJECT_         SPEC.md            STORIES.md                   Working code           Gate Report       CI/CD pipeline
 CONTEXT.md       CONTRACT-*.md      US-{id}-PLAN.md              + tests                PASS/FAIL         Changelog
                                     US-{id}-VALIDATION.md
```

> **Gate 0 (human decision)**: After Design, you decide: run the Plan phase (recommended for specs with 3+ stories or parallel teams) or build directly from the spec. The Plan phase is skipped by default for small, self-contained specs.

### Step 1: Discover (new chat session)

```text
@greenfield-interview I want to build a task tracker web app. Teams can create projects, assign tasks to members, set deadlines, and track progress with a kanban board. We'll use Python FastAPI for the backend and React for the frontend.
```

**What you get**: The agent interviews you across 6 phases. At the end, it writes `.copilot/context/PROJECT_CONTEXT.md` (the Project Bible).

**How to hand off**: Close this chat. The Project Bible is now on disk. Every agent in every future session loads it automatically.

---

### Step 2: Design (new chat session)

```text
/design Design the backend API for the task tracker. Core entities: Project, Task, User, Team. A task belongs to a project and is assigned to a user. Support CRUD for all entities, plus moving tasks between kanban columns (To Do, In Progress, Done). Include auth with JWT.
```

**What you get**: The Architect produces `.copilot/specs/TASK-TRACKER-API-SPEC.md` with module boundaries, API contracts, data models, error handling, and acceptance scenarios. The agent also writes `.copilot/holdout/HOLDOUT.md` with behavioral acceptance scenarios and runs verification gates (`verify_spec.py`, `verify_session_state.py`) before declaring done. If you see those scripts running, that's the agent confirming both artifacts are real (not stub) before handoff.

**How to hand off**: Close this chat. The spec file is on disk for the next agent.

---

### Step 2b: Contract (new chat session)

```text
/sprint-contract task-tracker-api
```

**What you get**: GIVEN/WHEN/THEN acceptance criteria extracted from the spec. Guardian reviews for testability. Saved to `.copilot/specs/CONTRACT-task-tracker-api.md`.

**How to hand off**: Close this chat. Both spec and contract are on disk.

---

### Step 3: Build (new chat session)

```text
@senior-developer Implement the task tracker API from .copilot/specs/TASK-TRACKER-API-SPEC.md. Start with the User and Auth modules, then Project and Task CRUD. Follow the acceptance criteria in .copilot/specs/CONTRACT-task-tracker-api.md.
```

**What you get**: Working code with tests. The developer reads both the spec and contract, studies your existing project patterns, and implements accordingly.

**If you hit a bug during build** (same or new session):

```text
@debug-detective POST /api/tasks returns 422 when I include the assignee_id field. Here's the request body and error response: [paste]
```

**How to hand off**: Close this chat. Code is written and committed locally.

---

### Step 4: Review (new chat session)

```text
/code-review Review src/api/ and src/services/ for the task tracker. Check against the spec at .copilot/specs/TASK-TRACKER-API-SPEC.md. Focus on auth security, input validation, and error handling.
```

**What you get**: Gate Report with verdict (PASS / NEEDS WORK / FAIL). If NEEDS WORK, fix the items and re-review.

**If review finds issues** (new session):

```text
@senior-developer Fix the issues from the code review: 1) Add rate limiting to auth endpoints 2) Sanitize user input in task description field 3) Add missing index on tasks.project_id
```

Then re-review in another new session.

**How to hand off**: Close this chat once you get PASS.

---

### Step 5: Ship (new chat session)

```text
@release-manager Set up GitHub Actions CI/CD for the task tracker: lint (ruff) → test (pytest) → build Docker image → deploy to Azure Container Apps. Include a staging environment with manual approval before production.
```

**After shipping** (new session):

```text
/retrospective Run a retro on the task-tracker-api build cycle. What went well with the spec-to-code handoff? Any rework?
```

**Capture knowledge** (new session):

```text
/mem-ingest Add the task tracker architecture decisions from .copilot/specs/TASK-TRACKER-API-SPEC.md to the project mem
```

---

### Summary: The Prompts That Built an App

#### Build Direct path (no Plan phase)

| # | Phase    | Prompt                                                                 | New Session? |
|---|----------|------------------------------------------------------------------------|--------------|
| 1 | Discover | `@greenfield-interview I want to build a task tracker web app...`      | Yes          |
| 2 | Design   | `/design Design the backend API for the task tracker...`               | Yes          |
| 3 | Contract | `/sprint-contract task-tracker-api`                                    | Yes          |
| 4 | Build    | `@senior-developer Implement from .copilot/specs/TASK-TRACKER-API...`  | Yes          |
| 5 | Review   | `/code-review Review src/api/ and src/services/...`                    | Yes          |
| 6 | Ship     | `@release-manager Set up GitHub Actions CI/CD...`                      | Yes          |

#### Plan Phase path (recommended for larger specs)

| # | Phase    | Prompt                                                                         | New Session? |
|---|----------|--------------------------------------------------------------------------------|--------------|
| 1 | Discover | `@greenfield-interview I want to build a task tracker web app...`              | Yes          |
| 2 | Design   | `/design Design the backend API for the task tracker...`                       | Yes          |
| 3 | Contract | `/sprint-contract task-tracker-api`                                            | Yes          |
| 4 | Plan     | `@story-master Decompose .copilot/specs/TASK-TRACKER-API-SPEC.md into stories` | Yes          |
| 5 | Plan     | `@story-planner Plan US-001 from .copilot/stories/STORIES.md`                  | Yes (per story) |
| 6 | Build    | `@senior-developer Build US-001 from .copilot/stories/US-001-PLAN.md`          | Yes (per story) |
| 7 | Review   | `/code-review Review src/api/ and src/services/...`                            | Yes          |
| 8 | Ship     | `@close-story US-001` then `@release-manager Set up GitHub Actions CI/CD...`   | Yes          |

> **Key takeaway**: You never copy-paste output between sessions. Agents write files (Project Bible, specs, contracts, stories, plans, code). The next agent reads those files. The file system is the handoff mechanism.

---

## Phase 1: Discover

> **Goal**: Understand what exists (or what you want to build) before touching code.
>
> **Running example**: This is where we ran `@greenfield-interview` for the task tracker app. Output: `.copilot/context/PROJECT_CONTEXT.md`.

### `@greenfield-interview`  -  Start a New Project

The agent interviews you one question at a time to produce a full Project Bible.

```text
@greenfield-interview I want to build a customer feedback analytics platform
```

```text
@greenfield-interview We need an internal tool for employees to submit and track IT support requests
```

```text
@greenfield-interview I'm building a multi-tenant SaaS API for invoice processing with Stripe integration
```

**What happens**: 6-phase interview (purpose, users, workflows, constraints, tech stack, open questions). Produces `.copilot/context/PROJECT_CONTEXT.md`.

**Next step**: `/design` to create architectural specs.

---

### `@brownfield-discovery`  -  Map an Existing Codebase

Use when you inherited a project, joined a team, or have zero documentation.

```text
@brownfield-discovery Map the codebase at src/ - I inherited this and have no docs
```

```text
@brownfield-discovery I just joined this team. Walk me through the project structure, entry points, and key dependencies
```

```text
@brownfield-discovery We have a legacy Flask app in backend/. Map the API routes, database models, and config patterns
```

**What happens**: Explores 10 layers (entry points, dependencies, config, domain model, data flows, conventions). Produces a Project Bible tagged `[CONFIRMED]`, `[INFERRED]`, or `[UNKNOWN]`.

**Next step**: Read the Bible, then `/design` or `@senior-developer` for changes.

---

### `/sql-query`  -  Explore Data

Use for ad-hoc queries, schema discovery, or generating reports.

```text
/sql-query Show me the top 10 customers by total order value in the last 90 days
```

```text
/sql-query What tables exist in the sales schema? Show me row counts and column names
```

```text
/sql-query Find all orders where the shipping date is more than 7 days after the order date
```

```text
/sql-query Compare monthly revenue this year vs last year, broken down by product category
```

**What happens**: Explores schema if needed, generates copy-ready T-SQL. Read-only (SELECT) by default. Assumptions documented in header comments.

---

### `/mem-query`  -  Ask Your Project Mem

Use when the answer might already be documented in your team's mem.

```text
/mem-query What authentication strategy did we choose and why?
```

```text
/mem-query How does the data pipeline handle late-arriving events?
```

```text
/mem-query What were the key decisions from the Q1 architecture review?
```

**What happens**: Searches the project mem for relevant entries and returns sourced answers.

---

## Phase 2: Design

> **Goal**: Define what to build, how it fits together, and what "done" looks like, before writing any code.
>
> **Running example**: New chat session. The Architect reads the Project Bible automatically, then we ran `/design` for the task tracker API. Output: `.copilot/specs/TASK-TRACKER-API-SPEC.md`.

### `/design`  -  Design a Feature or System

The Architect challenges scope, asks clarifying questions, then produces a full specification.

```text
/design New authentication system with OAuth2 and API key support
```

```text
/design REST API for a multi-tenant task management system - each tenant has isolated data
```

```text
/design Real-time notification service that supports email, SMS, and in-app push via a pluggable provider pattern
```

```text
/design Data ingestion pipeline: CSV uploads from S3, validate schema, deduplicate, write to Delta Lake Bronze layer
```

```text
/design Migrate our monolith's user service into a standalone microservice without downtime
```

**What happens**: Phase 0 Scope Challenge (REDUCTION / HOLD / EXPANSION), 5 pre-design questions, then a `SPEC.md` with module boundaries, API contracts, error handling, and acceptance scenarios.

**Next step**: `/sprint-contract` to lock acceptance criteria. Then choose your path at Gate 0: `@story-master` for the Plan Phase, or hand the spec directly to a build agent.

---

### `/feature-plan`  -  Plan Before Implementing

Produces an actionable checklist without writing code. Good for medium-complexity changes where you want to think before coding.

```text
/feature-plan Add pagination to the /api/users endpoint
```

```text
/feature-plan Refactor the email service to support multiple providers (SendGrid, SES, SMTP)
```

```text
/feature-plan Add role-based access control to the admin dashboard - we need admin, editor, and viewer roles
```

```text
/feature-plan Migrate database from SQLite to PostgreSQL without losing existing data
```

**What happens**: Goal, Assumptions, Step-by-step plan (verb-driven), Risks, Estimated steps. No code written until you approve.

**Next step**: Approve the plan, then `@senior-developer` to execute.

---

### `/sprint-contract`  -  Lock Down Acceptance Criteria

Use after `/design` and before implementation. Creates a testable contract between builder and reviewer.

```text
/sprint-contract auth-module
```

```text
/sprint-contract notification-service
```

```text
/sprint-contract Acceptance criteria for the CSV upload feature described in .copilot/specs/CSV-UPLOAD-SPEC.md
```

**What happens**: Extracts deliverables and GIVEN/WHEN/THEN acceptance criteria from the spec. Guardian reviews for coverage and testability. Saves to `.copilot/specs/CONTRACT-<feature>.md`.

---

## Phase 2b: Plan (Optional)

> **Goal**: Decompose the spec into a story backlog, plan each story atomically, and track progress with a structured artifact trail. Skip this phase for small, self-contained specs (single developer, < 3 stories, no parallel teams).
>
> **When to use it**: The spec has multiple independent stories, parallel teams will build different modules, or you want fine-grained progress tracking and per-story verification before shipping.
>
> **Gate 0**: After Design, you decide. `@story-master` to enter the Plan Phase. Or hand the spec directly to a build agent.

### `@story-master`  -  Decompose a Spec into a Story Backlog

Reads the spec, groups work into user stories, assigns them to delivery waves, and writes `STORIES.md`.

```text
@story-master Decompose .copilot/specs/TASK-TRACKER-API-SPEC.md into user stories
```

```text
@story-master Break the auth and notification modules from the spec into stories - we have two developers working in parallel
```

```text
@story-master Create a story backlog from .copilot/specs/DATA-PIPELINE-SPEC.md, group into two waves: Bronze-Silver first, Silver-Gold second
```

**What happens**: Reads the spec and Project Bible, creates user stories with acceptance criteria, groups them into delivery waves, writes `.copilot/stories/STORIES.md`. Runs `verify_stories.py` before declaring done.

**Gate 1 (human)**: Review `STORIES.md`. Approve wave structure and story scope before continuing.

**Next step**: `@story-planner` for each story in Wave 1.

---

### `@story-planner`  -  Plan a Single Story

Takes one approved story and produces an atomic implementation plan plus a validation checklist.

```text
@story-planner Plan US-001 from .copilot/stories/STORIES.md
```

```text
@story-planner Create an implementation plan for US-003 - the JWT auth story. Spec is at .copilot/specs/AUTH-SPEC.md
```

```text
@story-planner Plan US-007 (CSV upload pipeline). Include data quality checks and rollback steps.
```

**What happens**: Explores the codebase for affected modules, produces `US-{id}-PLAN.md` (atomic implementation steps) and `US-{id}-VALIDATION.md` (acceptance checklist). Runs `verify_plan.py` and `verify_validation.py` before declaring done.

**Gate 2 (human)**: Review the plan. Approve before handing to build.

**Next step**: `@senior-developer` (or specialist) with the plan file as input.

---

### `@close-story`  -  Verify and Stamp a Story Done

After a story is built and reviewed, close-story validates all acceptance criteria and stamps the `STORIES.md` row as complete.

```text
@close-story US-001
```

```text
@close-story US-003 - confirm the JWT auth story is complete. Code is in src/auth/.
```

```text
@close-story US-007 and update STORIES.md with the completion date
```

**What happens**: Reads `US-{id}-VALIDATION.md`, checks each acceptance criterion against the code and tests, stamps the STORIES.md row (`✅ Done`), and flags any unmet criteria. Will not stamp done if criteria are unmet.

**Next step**: Once all stories in a wave are stamped, `@release-manager` for ship.

---

> **Goal**: Write the code. Each agent is a specialist. Pick the one that matches your task.
>
> **Running example**: New chat session. We pointed `@senior-developer` at the spec and contract files. The agent read both and implemented the task tracker API with tests.
>
> **Plan Phase path**: If you ran `@story-planner`, point the build agent at `US-{id}-PLAN.md` instead of the spec directly. The plan file is the sole context anchor for that story's build session.

### `@senior-developer`  -  General Features, Bug Fixes, Refactoring

Your go-to for most implementation work. Works best when given a spec or clear requirements.

```text
@senior-developer Implement the auth module from .copilot/specs/AUTH-SPEC.md
```

```text
@senior-developer Add input validation to all POST endpoints in src/api/routes/ - reject missing required fields with 422
```

```text
@senior-developer Refactor src/services/payment.py - extract the Stripe logic into a separate PaymentProvider class
```

```text
@senior-developer Add unit tests for the UserService class in src/services/user_service.py - cover create, update, delete, and edge cases
```

```text
@senior-developer The signup form doesn't validate email format on the backend. Add validation using Pydantic and return a clear error message
```

**What happens**: Reads spec/context, studies existing patterns, writes failing tests first (Red), implements (Green), verifies. Uses 3-strike retry on failures before escalating.

---

### `@data-engineer`  -  Data Pipelines, PySpark, dbt, Airflow

Use for anything involving data movement, transformation, or orchestration.

```text
@data-engineer Build a PySpark pipeline that reads from Bronze orders table, deduplicates by order_id, and writes to Silver
```

```text
@data-engineer Create a dbt model that joins customers with their latest subscription status and calculates churn risk
```

```text
@data-engineer Write an Airflow DAG that runs the nightly ETL: extract from Postgres, transform in Spark, load to Delta Lake
```

```text
@data-engineer Add data quality checks to the Silver customers table - check for nulls in email, duplicates on customer_id, and valid date ranges
```

```text
@data-engineer Our Bronze-to-Silver pipeline is failing on schema evolution. The source added a new column last week. Fix the pipeline to handle schema changes gracefully
```

**What happens**: Asks 6 clarification questions (source schema, write strategy, quality checks), then builds: schema definition, transform logic, quality gates, Delta write, orchestration config.

**Tip**: Use `/design` first for complex pipelines.

---

### `@ai-engineer`  -  RAG, LLM Agents, Embeddings, Azure OpenAI

Use for anything involving language models, retrieval, or AI-powered features.

```text
@ai-engineer Build a RAG pipeline using Azure OpenAI and Azure AI Search for our internal knowledge base
```

```text
@ai-engineer Create a document chunking pipeline that splits PDFs by section headers and generates embeddings with text-embedding-3-large
```

```text
@ai-engineer Add a conversational agent that answers HR policy questions with source citations from our SharePoint docs
```

```text
@ai-engineer Implement an evaluation harness for our RAG pipeline - measure answer relevance, faithfulness, and retrieval precision
```

```text
@ai-engineer Our chatbot is hallucinating product prices. Add retrieval guardrails and a confidence threshold that falls back to "I don't know"
```

**What happens**: Asks 6 pre-build questions (data sources, chunking strategy, eval criteria), then builds: retrieval pipeline, generation with guardrails, evaluation dataset, observability hooks.

---

### `/quick-fix`  -  Small, Obvious Fixes

Skips the full pipeline. Use for single-file changes under 20 lines with no architectural impact.

```text
/quick-fix The config loader crashes when REDIS_URL is missing - add a fallback to localhost
```

```text
/quick-fix Fix the typo in src/utils/constants.py - "recieve" should be "receive"
```

```text
/quick-fix The /health endpoint returns 200 even when the database is unreachable. Return 503 when the DB ping fails
```

```text
/quick-fix Add CORS headers to the FastAPI app - allow origins from localhost:3000 for local dev
```

**What happens**: Eligibility check (single file, <20 lines, no new dependencies, no architectural impact). If eligible: implements, verifies, done. If not: escalates to the full pipeline.

---

### `@debug-detective`  -  Debug Failures and Errors

Use when something is broken and you don't know why. Always paste the actual error output.

```text
@debug-detective The API returns 500 on POST /api/orders - here's the stack trace:
Traceback (most recent call last):
  File "src/api/routes/orders.py", line 45, in create_order
    order = OrderService.create(payload)
  File "src/services/order_service.py", line 23, in create
    db.session.commit()
sqlalchemy.exc.IntegrityError: UNIQUE constraint failed: orders.reference_id
```

```text
@debug-detective The Spark job fails after 20 minutes with OOM on the executor nodes. Job config: 4 executors, 8GB each. Input: 50GB parquet from S3
```

```text
@debug-detective CI pipeline passes locally but fails in GitHub Actions with "Module not found: src.utils.helpers". Here's the Actions log: [paste log]
```

```text
@debug-detective Users report the dashboard loads in 15+ seconds. It was under 2 seconds last week. Nothing was deployed since then
```

**What happens**: Systematic investigation: observe symptom, form 2-3 ranked hypotheses, test against evidence, confirm root cause, propose minimal fix. Never guesses without evidence.

**Tip**: The more context you paste (stack traces, logs, config), the faster the diagnosis.

---

### `@prompt-builder`  -  Refine a Rough Prompt

Use when you have a vague idea for a prompt and want a polished, production-ready version.

```text
@prompt-builder "write me a prompt that makes an AI summarize meeting notes into action items"
```

```text
@prompt-builder I need a system prompt for a customer support chatbot that stays on-topic, never makes up policies, and escalates to a human when uncertain
```

```text
@prompt-builder Improve this prompt: "analyze the code and find bugs" - make it more specific for a Python FastAPI codebase
```

**What happens**: Analyzes gaps, applies prompt engineering techniques (role, decomposition, output format, constraints), returns a polished, copy-ready version.

---

### `@data-analyst`  -  SQL Queries and Data Exploration

Use when you need complex SQL queries, schema exploration, or Data Vault querying patterns.

```text
@data-analyst Write a query to find customers who placed orders in January but not in February
```

```text
@data-analyst Explore the Data Vault model - show me how to join the Customer Hub through the Order Link to get order history with the latest satellite attributes
```

```text
@data-analyst I need a monthly revenue dashboard query with year-over-year comparison, broken down by region and product line
```

**What happens**: Explores schema, generates optimized T-SQL with CTEs, proper aliasing, and documented assumptions.

---

## Phase 4: Review

> **Goal**: Catch bugs, security issues, and quality problems before anything ships.
>
> **Running example**: New chat session. We ran `/code-review` pointing at the implemented code and the original spec. Guardian produced a Gate Report.

### `/code-review`  -  Review Code Before Merging

```text
/code-review Review src/auth/ before we merge to main
```

```text
/code-review Review the changes in this PR - focus on security and error handling
```

```text
/code-review Full review of src/api/ and src/services/ - we're preparing for a production release
```

```text
/code-review Review the new data pipeline in src/etl/bronze_to_silver.py - check for data loss risks and schema handling
```

**What happens**: Guardian runs scope drift check (does it match the spec?), static analysis, security scan (OWASP Top 10), performance review. Produces a Gate Report: **PASS**, **NEEDS WORK**, or **FAIL**.

---

### `/doc-garden`  -  Audit Documentation Health

```text
/doc-garden Check all skills for broken cross-references and stale version numbers
```

```text
/doc-garden Audit the docs/ folder for outdated content, dead links, and inconsistencies
```

```text
/doc-garden Review README.md and ARCHITECTURE.md - check they match the current project structure
```

**What happens**: Scans for broken links, version mismatches, naming inconsistencies, contradictory guidance. Produces a health report with actionable fixes.

---

### `/mem-lint`  -  Health-Check the Project Mem

```text
/mem-lint Run a health check on the project mem
```

```text
/mem-lint Check mem.entries for stale content and missing citations
```

**What happens**: Audits mem.for coverage gaps, stale entries, broken sources, and structural issues.

---

## Phase 5: Ship

> **Goal**: Get it deployed, documented, and learn from the cycle.
>
> **Running example**: New chat session. We used `@release-manager` to set up CI/CD, then `/retrospective` to capture lessons learned.

### `@release-manager`  -  CI/CD, Deployment, Changelogs

```text
@release-manager Set up a GitHub Actions pipeline for lint → test → build → deploy to Azure
```

```text
@release-manager Create a release checklist for v2.0 - we're shipping the new auth system and the updated API
```

```text
@release-manager Add a staging environment to our GitHub Actions workflow with manual approval before production deploy
```

```text
@release-manager Generate a changelog from the last 2 weeks of merged PRs
```

**What happens**: Asks 5 intake questions, generates CI/CD pipeline, changelog, deploy plan with rollback strategy, quality gates. Includes Release Gatekeeper review.

---

### `/retrospective`  -  Learn from the Cycle

Run after a feature ships to capture what worked and what didn't.

```text
/retrospective Run a retro on the auth-module feature cycle
```

```text
/retrospective We just shipped the data pipeline redesign. What went well and what should we change?
```

```text
/retrospective Analyze the last sprint - focus on rework incidents and handoff friction between design and build
```

**What happens**: Gathers artifacts (spec, gate report, session state, decisions), assesses spec quality, handoff effectiveness, rework incidents. Produces a retrospective with lessons learned.

---

### `/mem-ingest`  -  Capture Knowledge for Future Sessions

Use after decisions are made, post-mortems are written, or research is completed.

```text
/mem-ingest Add the auth system design decisions from .copilot/specs/AUTH-SPEC.md to the project mem
```

```text
/mem-ingest Ingest our post-mortem from the June 15 outage into the mem.under "Incidents"
```

```text
/mem-ingest Add the API rate-limiting research notes I wrote in docs/rate-limiting-research.md
```

**What happens**: Extracts key facts, decisions, and rationale from the source document and adds structured entries to the project mem.

---

## Agent Reference Card

| Agent                  | Phase    | Role                                       | Modifies Code? |
| ---------------------- | -------- | ------------------------------------------ | -------------- |
| `greenfield-interview` | Discover | Interview for new projects                 | No             |
| `brownfield-discovery` | Discover | Map existing codebases                     | No             |
| `architect`            | Design   | System design and specifications           | No             |
| `story-master`         | Plan     | Decompose spec into story backlog          | No             |
| `story-planner`        | Plan     | Per-story implementation plan + validation | No             |
| `close-story`          | Plan/Ship| Verify acceptance criteria, stamp done     | No             |
| `senior-developer`     | Build    | Features, bug fixes, refactoring           | Yes            |
| `data-engineer`        | Build    | PySpark, Delta Lake, dbt, Airflow          | Yes            |
| `ai-engineer`          | Build    | RAG, LLM agents, embeddings, Azure OpenAI  | Yes            |
| `data-analyst`         | Any      | Natural language to T-SQL (utility)        | No (read-only) |
| `guardian`             | Review   | Code review, security, performance         | No (read-only) |
| `debug-detective`      | Build    | Root cause analysis                        | No (proposes)  |
| `release-manager`      | Ship     | CI/CD, deployment, changelogs              | Yes            |
| `prompt-builder`       | Build    | Refine rough prompts                       | No             |
| `researcher`           | (any)    | Fact-checking (internal, not user-invoked) | No             |

---

## Common Prompt Patterns (What Makes a Good Prompt)

### Bad vs. Good

| Bad (vague)                        | Good (specific, actionable)                                                                  |
| ---------------------------------- | -------------------------------------------------------------------------------------------- |
| "Fix the bug"                      | "The /api/orders endpoint returns 500 when quantity is 0. Here's the trace: [paste]"         |
| "Build a pipeline"                 | "Build a PySpark pipeline: read Bronze orders, deduplicate by order_id, write to Silver"     |
| "Review the code"                  | "Review src/auth/ before merge. Focus on security and input validation"                      |
| "Design something for users"       | "Design a REST API for multi-tenant task management with isolated data per tenant"           |
| "Make it faster"                   | "The dashboard query takes 15s. Here's the query and EXPLAIN plan: [paste]"                  |

### The Formula

```text
[What you want] + [Where it applies] + [Constraints or context]
```

**Examples applying the formula**:

- `@senior-developer` Add retry logic to `src/services/api_client.py` for HTTP 429 responses, max 3 retries with exponential backoff
- `/design` Webhook system for order status updates, must support at least 1000 events/sec, retry failed deliveries for 24h
- `@debug-detective` Memory leak in the worker process, RSS grows 50MB/hour, here's the memory profile: [paste]

---

## Tips for New Users

1. **Start with context.** No Project Bible? Run `@greenfield-interview` or `@brownfield-discovery` first. Everything works better with context.
2. **Spec before code.** Use `/design` before calling build agents for non-trivial work. This saves more time than it costs.
3. **Consider the Plan Phase for larger specs.** If your spec has 3+ stories or parallel developers, run `@story-master` → `@story-planner` before building. Each story gets its own focused build session with a clean plan file as context.
4. **Review before ship.** Use `/code-review` before merging. The Guardian catches things you miss when you're deep in implementation.
5. **Close stories before shipping.** If you used the Plan Phase, run `@close-story` for each story before `@release-manager`. It validates acceptance criteria and stamps the backlog.
6. **Small fixes skip the pipeline.** Use `/quick-fix` for typos, config tweaks, and one-line fixes. No need for the full ceremony.
7. **Paste errors, not descriptions.** "It doesn't work" is not helpful. Paste the actual stack trace, error log, or screenshot.
8. **One agent, one job.** Don't ask the Architect to write code. Don't ask the Developer to review code. Each agent is a specialist.
9. **Give context, get quality.** The more you tell the agent (file paths, error messages, constraints, business rules), the better the output.
10. **Chain agents, don't overload one.** A feature flow looks like: `/design` → `/sprint-contract` → (optional: `@story-master` → `@story-planner`) → `@senior-developer` → `/code-review` → `@release-manager`. Each step feeds the next.
11. **New chat per phase.** Start a fresh chat session for each pipeline stage. Agents work best with a clean context. Long conversations accumulate noise and degrade quality.


