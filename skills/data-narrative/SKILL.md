---
name: data-narrative
description: "Turns a raw dataset into a structured, evidence-grounded Markdown report where every claim traces back to the code or source that produced it. Orchestrates four specialist roles: Detective (external context), Analyst (exhaustive data profiling via data-science skill), Editor (narrative angle + report.md), and Inspector (provenance binding → inspector.json). USE FOR: any dataset-to-report workflow where auditability and claim traceability matter - analytical briefings, stakeholder reports, data-backed narratives. DO NOT USE FOR: SQL querying (use data-analyst), pipeline construction (use data-engineering), standalone EDA without a deliverable (use data-science), or architecture diagrams (use excalidraw-diagram)."
argument-hint: "[path to dataset, e.g. data/sales.csv or data/]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies:
    ["data-science", "security-boundaries", "verification-before-completion"]
---

# data-narrative Skill

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |
> Deps: data-science (Analyst), security-boundaries (Detective), verification-before-completion (Inspector gate)

Turns a raw dataset into a `report.md` where every claim is evidence-traced. Four sequential roles run as a fixed pipeline; each role reads what the previous one produced. The pipeline always runs in full - there are no skip-ahead paths.

---

## Behavioral Directives

- **Pipeline is sequential and non-negotiable.** Detective → Analyst → Editor → Inspector. No role may be skipped. No role may run before its predecessor has written its output file.
- **Do not generate statistics mentally.** Every number in `report.md` must come from an Analyst script. If the Editor needs a number the Analyst did not compute, re-task the Analyst before writing the report.
- **Output directory is fixed.** All artifacts go to `narrative-output/` in the current working directory. Create it if it does not exist.
- **Load sub-role SKILL.md files before running each role.** Each role has its own `SKILL.md` with detailed instructions. Read it before starting that role's work.
- **verification-before-completion applies at the end.** Before declaring the pipeline complete, run the Inspector verification gate (Step 5 below). Do not claim done without fresh evidence.

---

## Dependencies

Load these before starting:

```
~/.copilot/skills/data-narrative/detective/SKILL.md      - before running Detective
~/.copilot/skills/data-narrative/analyst/SKILL.md        - before running Analyst
~/.copilot/skills/data-narrative/editor/SKILL.md         - before running Editor
~/.copilot/skills/data-narrative/inspector/SKILL.md      - before running Inspector
~/.copilot/skills/data-science/SKILL.md                  - loaded by Analyst role
~/.copilot/skills/security-boundaries/SKILL.md           - loaded by Detective role
~/.copilot/skills/verification-before-completion/SKILL.md - loaded at Inspector gate
```

---

## Pipeline

### Pre-flight: Validate Input

Before running any role, determine whether the input is a **single file** or a **folder of files**, then follow the matching path.

#### Single file (e.g., `data/sales.csv`)

1. Confirm the file exists and is readable
2. Extract column names and 5 sample rows
3. Record: `{ "mode": "single", "files": ["data/sales.csv"], "schema": { ... } }`

#### Multiple files (e.g., `data/` or explicit file list)

1. List all `.csv` / `.xlsx` files in the folder (ignore hidden files and `__pycache__`)
2. For each file, read column names and 5 sample rows
3. Identify likely join keys: columns with the same name across files are join candidates - flag them
4. Assess relationship type:
   - **Same schema, different periods** (e.g., `jan.csv`, `feb.csv`) → treat as a single concatenated dataset; Analyst should union before profiling
   - **Different schemas, shared key** (e.g., `orders.csv` + `customers.csv`) → treat as a relational dataset; Analyst should join on the shared key before profiling
   - **Unrelated files** → ask the user which file(s) to focus on before continuing
5. Record: `{ "mode": "multi", "files": [...], "relationship": "union|join|unrelated", "join_key": "<col or null>" }`

Pass the full pre-flight record to the Detective so it has context about the full dataset shape.

#### Both cases

- Create `narrative-output/` if it does not exist
- Read `PROJECT_CONTEXT.md` if present - use domain constraints
- Write `narrative-output/preflight.json` with the pre-flight record so every downstream role can read it

If the dataset path is missing, unreadable, or relationship is `"unrelated"`, stop and ask the user before proceeding.

---

### Role 1 - Detective

**Load:** `~/.copilot/skills/data-narrative/detective/SKILL.md`

**Task:** Gather the external context that frames the dataset. Pass the Detective:

- Dataset name and file path
- Column names and 5 sample rows
- Any topic hint the user provided

**Done when:** `narrative-output/detective.json` exists and contains at least 2 context items.

---

### Role 2 - Analyst

**Load:** `~/.copilot/skills/data-narrative/analyst/SKILL.md` + `~/.copilot/skills/data-science/SKILL.md`

**Task:** Run exhaustive profiling of the dataset and produce a findings manifest where every finding is paired with a Python script.

**Done when:**

- `narrative-output/analyst.json` exists with ≥ 3 findings
- At least one Python script exists in `narrative-output/analyst/`
- Every finding in `analyst.json` has a `code.script` that points to an existing file

**Analyst → Editor handoff check:** If the Analyst finds no findings of `"significance": "high"`, surface this to the user before proceeding - the dataset may be too sparse to support a meaningful narrative.

---

### Role 3 - Editor

**Load:** `~/.copilot/skills/data-narrative/editor/SKILL.md`

**Task:** Select a single narrative angle and draft the report.

**Done when:**

- `narrative-output/editor.md` exists (outline with chosen angle)
- `narrative-output/report.md` exists (full draft, ≤ 800 words body, no Provenance section yet)
- Every specific number in `report.md` appears verbatim in `analyst.json` or `detective.json`

**Editor → Inspector handoff check:** Cross-reference every statistic in `report.md` against `analyst.json` before handing off. If any number cannot be matched, re-task the Analyst to produce it before continuing.

---

### Role 4 - Inspector

**Load:** `~/.copilot/skills/data-narrative/inspector/SKILL.md` + `~/.copilot/skills/verification-before-completion/SKILL.md`

**Task:** Bind every claim in `report.md` to its upstream evidence and write the provenance manifest.

**Done when:**

- `narrative-output/inspector.json` exists and is schema-valid
- ≥ 80% of quantitative claims in `report.md` must be bound to a Python script in `narrative-output/analyst/` as their primary evidence source (evidence type: `code`). Claims sourced exclusively from `detective.json` may be tagged as evidence type `reference` and do not count toward the 80% threshold.
- `report.md` has the Provenance footer appended by the Inspector

**Verification gate:** After the Inspector writes `inspector.json`, confirm the file exists and contains a non-empty `claims[]` array. Report the claim count and evidence type distribution to the user.

---

## Completion Report

After all four roles complete, present this summary to the user:

```
data-narrative pipeline complete
================================
Dataset        : <path>
Report         : narrative-output/report.md
Provenance     : narrative-output/inspector.json
Angle          : <chosen angle in one sentence>
Claims bound   : <n> total | <code_count> code evidence | <ref_count> reference evidence
Analyst scripts: <count> scripts in narrative-output/analyst/

To verify all claims:
  python ~/.copilot/skills/data-narrative/inspector/scripts/verify_claims.py \
      --inspector narrative-output/inspector.json
```

---

## Output File Reference

| File                                   | Role               | Description                                                           |
| -------------------------------------- | ------------------ | --------------------------------------------------------------------- |
| `narrative-output/detective.json`      | Detective          | External context items with source URLs                               |
| `narrative-output/analyst.json`        | Analyst            | Findings manifest with code line references                           |
| `narrative-output/analyst/*.py`        | Analyst            | Python scripts - one per finding group                                |
| `narrative-output/analyst/plots/*.png` | Analyst            | Visualisations (if produced)                                          |
| `narrative-output/editor.md`           | Editor             | Editorial outline: chosen angle + section plan                        |
| `narrative-output/report.md`           | Editor + Inspector | Final narrative report with Provenance footer                         |
| `narrative-output/inspector.json`      | Inspector          | Provenance manifest (schema: inspector/references/output-schema.json) |

---

## Error Handling

| Situation                                                          | Action                                                                                                                                                        |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dataset not found                                                  | Stop, ask user for correct path                                                                                                                               |
| Detective finds no context (0 items)                               | Warn and continue - Editor will note "no external context available"                                                                                          |
| Analyst finds no high-significance findings                        | Stop, present findings list to user, ask whether to proceed                                                                                                   |
| Editor needs a number the Analyst did not compute                  | Re-task Analyst before writing report.md                                                                                                                      |
| Analyst re-tasked more than 2 times for the same missing statistic | Stop, report the statistic that cannot be produced and the reason, and ask the user whether to omit that claim from the report or provide the value manually. |
| Inspector cannot bind a claim to evidence                          | Flag in inspector.json as unbound; do not fabricate evidence                                                                                                  |
| Inspector coverage < 60%                                           | Report the gap to the user before declaring complete                                                                                                          |
