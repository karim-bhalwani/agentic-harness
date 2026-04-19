---
agent: architect
description: Run a workflow retrospective for a completed discovery → design → build → review → ship cycle. Loads the context-engineer skill to produce or update RETROSPECTIVE.md, track rework incidents, and surface recurring patterns. Use after completing a feature cycle to capture lessons learned before starting the next one.
argument-hint: "[feature or sprint name to retrospect]"
tools:
  - read
  - search
version: "7.0"
updated: "2026-04-12"
---

Load `skills/context-engineer/SKILL.md` via `read_file` before proceeding (this skill has `disable-model-invocation: true` and cannot self-invoke). Follow the **Workflow Retrospective** section of that skill.

Run a retrospective for the cycle: **${input:cycle}**

## Steps

1. **Gather artifacts** - Read the following files if they exist:
   - `.copilot/specs/SPEC.md` - original specification (source of intent)
   - `.copilot/artifacts/review-report.md` - Guardian gate report (source of rework incidents)
   - `.copilot/state/SESSION_STATE.md` - pipeline checkpoint (source of escalations and retries)
   - `.copilot/context/DECISIONS.md` - architectural decision log (source of mid-cycle pivots)

2. **Assess spec quality** - Did the spec have ambiguities that caused rework? Did any holdout failures reveal an intent gap?

3. **Assess handoff effectiveness** - Which handoffs preserved context cleanly? Which caused backtracking or required re-explanation?

4. **Tally rework incidents** - Fill the Rework Incidents table using state machine retry counts from context and Guardian findings counts from the gate report.

5. **Identify patterns** - If the same category of rework appears across this cycle (or across 3+ cycles in prior retrospectives), flag it as a structural gap and recommend a fix (new skill, convention update, or workflow change).

6. **Harness review** - For each agent, skill, and workflow step used in this cycle, answer:
   - **What model limitation does this component compensate for?** (e.g., "Guardian exists because models grade their own work too leniently")
   - **Is that limitation still present?** Test by asking: could the builder agent have done this adequately without the component?
   - **Verdict**: `KEEP` (still load-bearing), `SIMPLIFY` (partially redundant, reduce scope), or `RETIRE` (no longer needed).
   - If a new model was used in this cycle, explicitly re-evaluate every component. Default to stripping scaffolding that isn't demonstrably load-bearing.
   - Record results in the Harness Review table of the retrospective output.

7. **Produce output** - Write or update `.copilot/retrospectives/RETROSPECTIVE-${input:cycle}.md` using the RETROSPECTIVE.md template from the context-engineer skill. Create the directory if it does not exist.

8. **Entropy audit** - Load `skills/context-engineer/references/entropy_audit.md` and run each checklist category against the codebase. Append the Entropy Audit Results table to the retrospective output. If the overall entropy score is HIGH, recommend a dedicated cleanup sprint before new feature work.

9. **Update DECISIONS.md** - If any lessons learned warrant an Architectural Decision Record (ADR), append it to `.copilot/context/DECISIONS.md`. If the Harness Review produced any `SIMPLIFY` or `RETIRE` verdicts, record those as ADRs with the rationale.

## Output

A completed `RETROSPECTIVE-${input:cycle}.md` at `.copilot/retrospectives/` covering:

- Specification quality assessment
- Handoff effectiveness per agent pair
- Rework Incidents table (agent, retries, escalations, root cause)
- Agent value assessment
- Harness Review table (component, assumption, still valid?, verdict)
- Entropy Audit Results table (category, items found, severity, action)
- Lessons learned with actionable recommendations

