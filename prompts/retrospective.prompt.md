---
agent: architect
description: Run a workflow retrospective for a completed discovery -> design -> build -> review -> ship cycle. Produces or updates RETROSPECTIVE.md, tracks rework incidents, runs an entropy audit, and surfaces recurring patterns. Use after completing a feature cycle to capture lessons learned before starting the next one.
argument-hint: "[feature or sprint name to retrospect]"
tools:
  - read
  - search
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Run a retrospective for the cycle: **${input:cycle}**

**Workflow**: Load `skills/context-engineer/SKILL.md` via `read_file` (it has `disable-model-invocation: true` and cannot self-invoke). Then load `skills/context-engineer/references/templates-and-retrospectives.md` for the retrospective template, rework-tracking rules, harness-review protocol, and entropy-audit checklist. The skill and its references are the single source of truth; do not paraphrase here.

**Inputs to gather** (read whichever exist):

- `.copilot/specs/SPEC.md` - original specification
- `.copilot/artifacts/review-report.md` - Guardian gate report
- `.copilot/state/SESSION_STATE.md` - pipeline checkpoint and retry counts
- `.copilot/context/DECISIONS.md` - architectural decision log

**Output**:

- `.copilot/retrospectives/RETROSPECTIVE-${input:cycle}.md` covering spec quality, handoff effectiveness, rework incidents, harness review, entropy audit, and lessons learned.
- Append any new ADRs to `.copilot/context/DECISIONS.md` (especially `SIMPLIFY` or `RETIRE` verdicts from the Harness Review).
