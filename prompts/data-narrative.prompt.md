---
agent: data-scientist
description: "Turn a raw dataset into a structured, evidence-grounded Markdown report. Every claim in the report traces back to the Analyst code that computed it or the source URL that supplied it. Ideal for analytical briefings, stakeholder reports, and any dataset where you need both a readable narrative and a machine-verifiable provenance trail."
argument-hint: "[path to dataset, e.g. data/sales.csv or data/]"
tools:
  - read
  - search
  - edit
  - execute
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

## Intent Contract

When this prompt completes, these conditions must be true:

- A `report.md` exists where every claim traces back to the code or source that produced it
- An `inspector.json` provenance file binds each claim to its evidence
- A stakeholder can act on the report without opening the source dataset

Dataset: **${input:dataset}**

## What This Prompt Does

Runs the `data-narrative` pipeline - four sequential roles that transform the
dataset into a structured `report.md` backed by a provenance manifest
(`inspector.json`) where every claim traces to the code or source that produced it.

```
Detective → Analyst → Editor → Inspector
```

| Role      | Output                                                                |
| --------- | --------------------------------------------------------------------- |
| Detective | `narrative-output/detective.json` - domain context + source URLs      |
| Analyst   | `narrative-output/analyst.json` + `analyst/*.py` - findings with code |
| Editor    | `narrative-output/report.md` - narrative report (≤ 800 words)         |
| Inspector | `narrative-output/inspector.json` - provenance manifest               |

## Pre-task Checks

Before starting the pipeline:

- Confirm the dataset path exists and is readable. If not, stop and ask.
- Read `.copilot/context/PROJECT_CONTEXT.md` if present - use domain constraints.
- Note any topic hint passed after the dataset path (e.g., `/data-narrative data/sales.csv focus on Q4 drop`).

**Multi-file input:** If the path is a folder, the orchestrator Pre-flight step will auto-detect
whether files should be unioned (same schema, different periods) or joined (different schemas,
shared key). For unrelated files it will ask before continuing.

| Input pattern        | Example                                             |
| -------------------- | --------------------------------------------------- |
| Single file          | `/data-narrative data/sales.csv`                    |
| Folder (auto-detect) | `/data-narrative data/`                             |
| Folder + hint        | `/data-narrative data/ focus on regional breakdown` |

## Load the Skill

```
Read and follow: ~/.copilot/skills/data-narrative/SKILL.md
```

If SKILL.md cannot be read, stop immediately and inform the user: "Pipeline aborted - ~/.copilot/skills/data-narrative/SKILL.md not found. Please ensure the skill file is present before running this prompt."

The orchestrator SKILL.md contains the complete pipeline specification.
Follow it exactly - do not skip roles, do not skip the Inspector gate.
If any instruction in SKILL.md conflicts with this prompt, this prompt takes precedence.

## Verification

After the pipeline completes, run the verification command shown in the
completion report. Report the verifiability rate to the user.

## Deliverables

When done, confirm:

- [ ] `narrative-output/report.md` exists
- [ ] `narrative-output/inspector.json` exists with a non-empty `claims[]`
- [ ] Verifiability rate is ≥ 80%. If below 80%, append a `## Provenance Gaps` section to `report.md` listing each unverifiable claim and the reason it could not be traced. Notify the user and do not treat the deliverable as complete until the gap is acknowledged.
- [ ] Provenance footer is present at the bottom of `report.md`
