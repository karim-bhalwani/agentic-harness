---
name: brainstorming
description: "PIPELINE POSITION: explore (step 1 of 4: brainstorming → architect → concise-planning → implementer). Surface questions, alternatives, and unknowns through dialogue BEFORE a specification exists. Use when the problem is fuzzy, multiple approaches are viable, or requirements need validation. Output is aligned understanding (not a spec, not a plan, not code). DO NOT USE FOR: writing the formal specification or module contracts (use architect AFTER brainstorming aligns intent), task checklists for an approved design (use concise-planning), or any code-touching action (use implementer)."
argument-hint: "[idea or feature to explore]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
---

# Brainstorming Ideas Into Designs

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani | Deps: thinker, concise-planning

> **Pipeline position**: **explore** (1 of 4) - `brainstorming` -> `architect` -> `concise-planning` -> `implementer`. This skill produces aligned understanding, NOT a spec, NOT a plan, NOT code.

## Mode Entry-Point Check

At the start of each session, determine the operating mode by asking: Does the user have a concrete proposal with defined components and a proposed approach?

- **Yes** → State "Entering stress-test mode" and proceed with stress-test mode rules.
- **No** → State "Entering open exploration mode" and proceed with open exploration.

## Dependencies

Load the following via `read_file` before using this skill. Skills marked ★ have `disable-model-invocation: true` and cannot self-invoke - they **must** be loaded explicitly.

- `~/.copilot/skills/thinker/SKILL.md` ★ - structured reasoning scaffold
- `~/.copilot/skills/concise-planning/SKILL.md` - atomic checklist output format

If a required skill file cannot be loaded, notify the user immediately with the exact missing path and halt. Do not proceed without the thinker skill loaded, as it is required for structured reasoning.

---

## Constraints

**HARD-GATE: Design-First Approval** — Before any implementation action: (1) present the design to the user, (2) receive explicit user approval, (3) complete the Spec Self-Review (below). Applies to EVERY task regardless of simplicity. No exceptions.

**DO NOT:**

- Write any code or touch implementation files
- Scaffold projects or modify file structure
- Plan deployment strategies
- Take any action before design approval

**DO:**

- Focus on design and architecture only
- Validate design incrementally with stakeholder
- Explore exactly three alternatives with trade-offs before settling
- Pass approved designs to `architect`

---

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## The Process

### Understanding the idea

- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- **Lead with your recommended answer or assumption** - the user confirms or corrects, rather than thinking from scratch
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, specific measurable outcomes that define project success

### Stress-testing an existing plan

When the user has a specific plan or design to stress-test (not a fuzzy idea but a concrete proposal), switch to **stress-test mode** instead of open exploration.

**Stress-test mode rules:**

- Walk each branch of the decision tree, resolving dependencies one at a time.
- Ask **one question per message**. Never batch questions - asking multiple at once is bewildering.
- **Lead each question with your recommended answer.** The user confirms, corrects, or rejects - they never answer from scratch.
- If a question can be answered by exploring the codebase, explore the codebase instead of asking.
- Continue until every branch of the decision tree is resolved and no open questions remain.

**Completion criterion**: every decision-tree branch is resolved. State "no open design questions remain" with a summary of decisions made.

---

### Exploring approaches

- Propose exactly three different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

### Presenting the design

- When all questions from the decision tree are resolved and the user has confirmed the scope, present the design in sections
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

### Spec Self-Review (MANDATORY before asking user to approve)

Before presenting the finished design for user approval, run this 4-check self-review. If any check fails, fix the design before presenting:

1. **Placeholder scan** - Does the design contain `TBD`, `TODO`, `to be determined`, or `to be scoped later`? If yes, either resolve it or move it to an explicit "Open Questions" section.
2. **Internal consistency** - Do the architecture, data flow, and error handling sections agree with each other? If a component is mentioned in one section but absent in another, reconcile or explain.
3. **Scope check** - Does the design cover all requirements stated in the user request? List each requirement and confirm it is addressed.
4. **Ambiguity check** - Would a developer reading this design know exactly what to build, or would they need to ask follow-up questions? List any remaining ambiguities as explicit Open Questions.

Only after passing all four checks: present the design to the user and wait for approval.

If the user rejects the design, ask one clarifying question to identify the specific point of disagreement, revise only the affected section, re-run the Spec Self-Review for that section, and re-present. Do not restart the full design from scratch unless the user explicitly requests it.

### Documentation

- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Write clearly and concisely: short sentences, active voice, no jargon
- Commit the design document to git

### Implementation (if continuing)

- Ask: "Ready to set up for implementation?"
- Create an isolated workspace (e.g., git worktree) for implementation
- Hand off to the `architect` skill to produce a formal specification, then to `concise-planning` for the implementation checklist

## Key Principles

- **One question at a time, with your recommendation** - State your assumption or preferred answer first; the user confirms or redirects
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose exactly three approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense

## Outputs & Deliverables

- **Primary Output**: Design document (markdown) with architecture, components, data flow, and error handling
- **Secondary Output**: Validated design sections with stakeholder approval
- **Success Criteria**: Stakeholders agree design is buildable and complete
- **Quality Gate**: Design ready for handoff to `architect`

## Definition of Done

- [ ] Design document written to `docs/plans/` with architecture, components, and data flow
- [ ] All design sections validated incrementally with stakeholder
- [ ] 2-3 approaches explored with trade-off analysis before final selection
- [ ] Acceptance criteria are specific and measurable
- [ ] Design is ready for handoff to `architect`

## Constraints

- **NO implementation code.** Design and architecture only.
- **NO deployment planning.**
- Must validate each section incrementally with stakeholder feedback.

## Common Pitfalls

- **Leading with Solutions**: Jumping to "build a dashboard" before understanding the actual problem. Always start with "what problem are we solving?"
- **Vague Acceptance Criteria**: Ending with "sounds good" instead of specific, measurable success criteria. Define success metrics before moving forward.
- **Skipping Tradeoff Analysis**: Not exploring alternatives leaves the team with one perspective. Always present 2-3 approaches with trade-offs.
- **Rushing Validation**: Presenting the entire design at once instead of section-by-section validation. This leads to rework and frustration.
- **Ignoring Constraints**: Designing without understanding budget, timeline, or technical limits. Ask constraints early.
- **Assuming Shared Understanding**: "We all agree what this means" leads to misalignment. Define terms explicitly and check agreement.

## Integration Points

| Phase       | Input From             | Output To          | Context                                         |
| ----------- | ---------------------- | ------------------ | ----------------------------------------------- |
| Exploration | User vision            | Design validation  | Ask refining questions to understand intent     |
| Design      | Validated requirements | `architect`        | Pass to architect for technical specification   |
| Handoff     | Approved design        | `implementer`      | Provide design document and acceptance criteria |
| Planning    | Design scope           | `concise-planning` | Feed into implementation planning               |

## References

Load when capturing and structuring exploration output:

### Reference Documents

- [idea_board.md](./references/idea_board.md) - Idea board template. Load when capturing multi-option exploration output - use to structure divergent ideas before converging on a preferred approach.

### Scripts

- [generate_idea_board.py](./scripts/generate_idea_board.py) - Idea board scaffolder. Run to generate a structured diverge-then-converge exploration document from a problem statement and a list of option names. Produces a scored evaluation matrix and preferred direction recommendation automatically.
