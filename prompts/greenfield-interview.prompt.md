---
agent: greenfield-interview
description: Conduct a structured founding interview to produce a Project Bible for a greenfield project. Uses the greenfield-interview agent to transform a rough idea into a declared intent document covering goals, constraints, architecture preferences, and acceptance criteria. Use before writing a single line of code on a new project.
argument-hint: "[project idea, product concept, or problem to solve]"
tools:
  - read
  - search
  - agent
version: "7.0"
updated: "2026-04-12"
---

Use the `greenfield-interview` agent to conduct a founding interview for: **${input:project_idea}**

**Interview objectives** (gather all before producing output):

- **Purpose**: what problem does this solve? Who experiences it?
- **Users**: who are the primary and secondary users?
- **Core workflows**: what are the 3-5 most important things users need to do?
- **Constraints**: budget, timeline, regulatory, technology stack preferences
- **Quality priorities**: rank these - performance, security, maintainability, time-to-market
- **Scale expectations**: initial load, growth trajectory, data volume
- **Integration requirements**: existing systems, third-party services, APIs
- **Non-goals**: what is explicitly out of scope?

**Interview protocol**:

- Ask one focused question at a time - do not interrogate with lists
- Probe ambiguous answers with a single follow-up before moving on
- When a topic is unclear, offer 2-3 concrete options to choose from
- Signal when enough information has been gathered to proceed

**Output format** (Founding Project Bible):

1. **Project intent**: 3-sentence summary - what, who, why
2. **Core user workflows**: numbered, each with actor + action + outcome
3. **Constraints and non-goals**: two explicit lists
4. **Quality priority stack**: ordered ranking with rationale
5. **Proposed tech stack**: with brief justification for each choice `[DECLARED]`
6. **Open questions**: decisions deferred - each with a recommended default
7. **Acceptance criteria**: 3-5 measurable conditions that define "done for v1"

Tag all outputs `[DECLARED]` - these are founding intent, not confirmed code. Save to `.copilot/context/PROJECT_CONTEXT.md`. Hand off to `architect` to convert into a technical specification.

