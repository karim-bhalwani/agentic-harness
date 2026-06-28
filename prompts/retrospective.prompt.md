---
agent: architect
description: Run a workflow retrospective for a fully completed discovery -> design -> build -> review -> ship cycle. Produces or updates RETROSPECTIVE.md, tracks rework incidents, runs an entropy audit, and surfaces recurring patterns. Only run after all cycle stages have reached the review gate and shipped; do not run for partially completed or interrupted cycles.
argument-hint: "[feature or sprint name to retrospect]"
tools:
  - read
  - search
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

## Intent Contract

When this prompt completes, these conditions must be true:

- The retrospective captures what worked, what did not, and what to change
- Every lesson is tied to a specific workflow phase (discovery, design, build, review, ship)
- Actionable improvements are identified with clear ownership

Run a retrospective for the cycle: **${input:cycle}**

**Workflow** (execute in strict sequence):

### Phase 1: Validate Foundation (PRIORITY: CRITICAL)

1. Read `~/.copilot/skills/context-engineer/SKILL.md` (has `disable-model-invocation: true`)
2. Read `~/.copilot/skills/context-engineer/references/templates-and-retrospectives.md`
3. **If either file is missing or unreadable**: immediately halt and output: "Foundation file [filename] is missing or unreadable. Cannot proceed until resolved." Do not proceed to Phase 2.
4. Confirm both files contain all required sections: retrospective template, rework-tracking rules, harness-review protocol, entropy-audit checklist. If any required section is missing from either foundation file, halt and notify the user: "Foundation file [filename] is missing required section: [section name]. Cannot proceed until resolved."

### Phase 2: Gather Input Files (PRIORITY: REQUIRED)

Read both critical files. **Both must exist.** If either is missing or unreadable, immediately halt and output: "Cannot complete retrospective: missing required input files (SPEC.md, review-report.md, or both). Verify cycle completion and file availability." Do not proceed to Phase 3.

**Critical files** (both must exist):

- `.copilot/specs/SPEC.md` - original specification
- `.copilot/artifacts/review-report.md` - Guardian gate report

**Supporting files** (optional; use if available):

- `.copilot/state/SESSION_STATE.md` - pipeline checkpoint and retry counts
- `.copilot/context/DECISIONS.md` - architectural decision log

### Phase 3: Process Retrospective (PRIORITY: HIGH)

1. Apply template and rules from Phase 1 foundation files to cycle data
2. Track rework incidents per rules
3. Run entropy audit per checklist
4. Surface recurring patterns

### Phase 4: Generate Output (PRIORITY: HIGH)

1. Create `.copilot/retrospectives/RETROSPECTIVE-${input:cycle}.md` with findings covering: spec quality, handoff effectiveness, rework incidents, harness review, entropy audit, lessons learned. If writing this file fails, halt and notify the user with the exact file path and error reason. Do not proceed to step 2.
2. Append all new ADRs to `.copilot/context/DECISIONS.md`. ADRs with `SIMPLIFY` or `RETIRE` verdicts must be listed first and marked with a `[HIGH PRIORITY]` prefix.

**Key Rule**: The skill and its references are the single source of truth; do not paraphrase here.
