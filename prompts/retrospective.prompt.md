---
agent: architect
description: Run a workflow retrospective for a fully completed discovery -> design -> build -> review -> ship cycle. Produces or updates RETROSPECTIVE.md, tracks rework incidents, runs an entropy audit, and surfaces recurring patterns. Only run after all cycle stages have reached the review gate and shipped; do not run for partially completed or interrupted cycles.
argument-hint: "[feature or sprint name to retrospect]"
tools:
  - read
  - search
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Run a retrospective for the cycle: **${input:cycle}**

**Workflow** (execute in strict sequence):

### Phase 1: Validate Foundation (PRIORITY: CRITICAL)

1. Read `skills/context-engineer/SKILL.md` (has `disable-model-invocation: true`)
2. Read `skills/context-engineer/references/templates-and-retrospectives.md`
3. **If either file is missing or inaccessible**: Log error, terminate process, notify user with missing file path.
4. Confirm both files contain required sections: retrospective template, rework-tracking rules, harness-review protocol, entropy-audit checklist.

### Phase 2: Gather Input Files (PRIORITY: REQUIRED)

Attempt to read each; if **all critical files are missing**, terminate with error.  
**Critical files** (at least 2 must exist):

- `.copilot/specs/SPEC.md` - original specification
- `.copilot/artifacts/review-report.md` - Guardian gate report

**Supporting files** (optional; use if available):

- `.copilot/state/SESSION_STATE.md` - pipeline checkpoint and retry counts
- `.copilot/context/DECISIONS.md` - architectural decision log

**Error handling**: If critical files missing, log exact file paths and halt with message: "Cannot complete retrospective: missing required input files (SPEC.md, review-report.md, or both). Verify cycle completion and file availability."

### Phase 3: Process Retrospective (PRIORITY: HIGH)

1. Apply template and rules from Phase 1 foundation files to cycle data
2. Track rework incidents per rules
3. Run entropy audit per checklist
4. Surface recurring patterns

### Phase 4: Generate Output (PRIORITY: HIGH)

1. Create `.copilot/retrospectives/RETROSPECTIVE-${input:cycle}.md` with findings covering: spec quality, handoff effectiveness, rework incidents, harness review, entropy audit, lessons learned
2. Append new ADRs to `.copilot/context/DECISIONS.md` from Harness Review (prioritize `SIMPLIFY` or `RETIRE` verdicts)

**Key Rule**: The skill and its references are the single source of truth; do not paraphrase here.
