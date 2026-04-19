# 5-Minute Orientation Template

> **Purpose:** A one-page summary that lets any new team member (or agent) understand a project in 5 minutes. Generated from the Project Bible by Brownfield Discovery or Greenfield Interview. Lives at `.copilot/context/ORIENTATION.md`.

---

```markdown
# Project Orientation: [Project Name]

> **Generated:** [Date] | **Source:** [Brownfield Discovery / Greenfield Interview]
> **Read time:** ~5 minutes

## What Is This?

[One paragraph: what the project does, who uses it, and why it exists.]

## Tech Stack at a Glance

| Layer        | Technology       |
|-------------|------------------|
| Language     | [e.g., Python 3.12] |
| Framework    | [e.g., FastAPI]  |
| Database     | [e.g., PostgreSQL 16] |
| Deployment   | [e.g., Azure App Service] |
| CI/CD        | [e.g., GitHub Actions] |

## How to Run It

```bash
# Install dependencies
[command]

# Run locally
[command]

# Run tests
[command]
```

## Project Structure (Key Paths Only)

```text
[3-8 lines showing the most important directories and what they contain]
```

## Key Concepts (Domain Glossary)

| Term | Meaning |
|------|---------|
| [Term 1] | [One-sentence definition] |
| [Term 2] | [One-sentence definition] |
| [Term 3] | [One-sentence definition] |

## Architecture in One Diagram

```text
[Simple ASCII or Mermaid diagram showing major components and data flow.
Keep it to 5-8 boxes maximum.]
```

## Current State

- **Active development areas:** [what is being worked on]
- **Known pain points:** [top 2-3 issues or tech debt items]
- **Recent major changes:** [last significant change, if relevant]

## Where to Find Things

| I need to...           | Look in...               |
|-----------------------|--------------------------|
| Understand the API     | [path or doc link]       |
| See the data model     | [path or doc link]       |
| Find configuration     | [path or doc link]       |
| Read the full context  | `.copilot/context/`      |

## First Tasks for New Contributors

1. [Simple starter task, e.g., "Run the test suite and verify all tests pass"]
2. [Second task, e.g., "Read ARCHITECTURE.md for module boundaries"]
3. [Third task, e.g., "Pick an issue labeled 'good-first-issue'"]

```text

---

## Generation Rules

When producing an Orientation document:

1. **Brevity is mandatory.** The entire document must be readable in ~5 minutes (~500-800 words). If you cannot summarize it that tightly, the project needs better documentation, not a longer orientation.
2. **Confirmed facts only.** Every claim must trace to a file, command output, or user statement. Use `[UNKNOWN]` for anything you cannot verify.
3. **Run the commands.** Do not list build/test commands you have not actually executed. Mark unverified commands with `[NOT VERIFIED]`.
4. **Skip empty sections.** If a section does not apply (e.g., no database), omit it entirely.
5. **Update, do not duplicate.** If an `ORIENTATION.md` already exists, update it in place. Do not create a second file.


