---
name: brainstorming
description: "Explore user intent, requirements, and design before implementation. Use when turning ideas into designs, validating requirements through dialogue, exploring multiple approaches, or creating design documentation for features, components, and functionality changes. DO NOT USE FOR: actual implementation (use implementer), system specifications (use architect), or planning checklists (use concise-planning)."
argument-hint: "[idea or feature to explore]"
license: MIT
compatibility: "VS Code, Claude Code"
metadata:
  version: "7.0"
  updated: "2026-04-12"
  dependencies: ["thinker", "concise-planning"]
---

# Brainstorming Ideas Into Designs

> Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani | Deps: thinker, concise-planning

## Dependencies

Load the following via `read_file` before using this skill. Skills marked ★ have `disable-model-invocation: true` and cannot self-invoke - they **must** be loaded explicitly.

- `skills/thinker/SKILL.md` ★ - structured reasoning scaffold
- `skills/concise-planning/SKILL.md` - atomic checklist output format

---

> **HARD-GATE**
>
> Do NOT write any code, scaffold any project, modify any file, or take ANY implementation action until you have (1) presented the design to the user, (2) the user has explicitly approved it, and (3) you have completed the Spec Self-Review below.
>
> This applies to EVERY task regardless of perceived simplicity. "This is too simple to need a design" is not an exception - it is a rationalization. Simple bugs can also have architectural implications. The gate applies.

---

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## The Process

### Understanding the idea

- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

### Exploring approaches

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

### Presenting the design

- Once you believe you understand what you're building, present the design
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

### Documentation

- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Write clearly and concisely: short sentences, active voice, no jargon
- Commit the design document to git

### Implementation (if continuing)

- Ask: "Ready to set up for implementation?"
- Create an isolated workspace (e.g., git worktree) for implementation
- Create a detailed implementation plan using the concise-planning skill

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense

## Outputs & Deliverables

- **Primary Output**: Design document (markdown) with architecture, components, data flow, and error handling
- **Secondary Output**: Validated design sections with stakeholder approval
- **Success Criteria**: Stakeholders agree design is buildable and complete
- **Quality Gate**: Design ready for handoff to `implementer`

## Definition of Done

- [ ] Design document written to `docs/plans/` with architecture, components, and data flow
- [ ] All design sections validated incrementally with stakeholder
- [ ] 2-3 approaches explored with trade-off analysis before final selection
- [ ] Acceptance criteria are specific and measurable
- [ ] Design is ready for handoff to `architect` or `implementer`

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
