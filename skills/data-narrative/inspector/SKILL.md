---
name: data-narrative-inspector
description: "Inspector sub-role of the data-narrative skill. Links every claim in report.md back to its upstream evidence (Analyst code line or Detective source URL). Produces inspector.json — the machine-verifiable provenance manifest for the narrative. Loaded and invoked by the data-narrative orchestrator only."
user-invocable: false
license: MIT
compatibility: "VS Code"
metadata:
  version: "1.0"
  updated: "22-June-2026"
  dependencies: []
---

# data-narrative — Inspector Role

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

The Inspector is the final quality gate before the narrative is delivered. It reads the finished `report.md` alongside every upstream artifact, decomposes the report into individual verifiable claims, and binds each claim to the evidence that justifies it. The output is `inspector.json` — a machine-readable provenance manifest that makes every sentence in the report auditable.

---

## Behavioral Directives

- **Bind claims, not sections.** Operate at the sentence level, not the paragraph level. One claim = one entry in `claims[]`.
- **No new analysis.** The Inspector reads and links; it does not recompute, rephrase, or invent. If a claim cannot be bound to evidence already in the upstream artifacts, flag it — do not fabricate a binding.
- **Two evidence types only.** `code` (Analyst script + line range) and `reference` (Detective URL + excerpt). Every claim must have at least one. Mark `evidence_type` as `"both"` when it has both.
- **Prefer code over reference for quantitative claims.** If a number was computed by the Analyst, bind it to code. Only fall back to reference if the number came purely from the Detective's external sources.
- **Unverifiable claims are flagged, not dropped.** If a claim cannot be bound, include it in `claims[]` with `evidence_type: "reference"` and `evidence.reference.url: ""` plus a `verify_note` explaining why it cannot be grounded. The human will decide whether to remove or rephrase.

---

## Inputs (read before starting)

| File                              | Description                                                                |
| --------------------------------- | -------------------------------------------------------------------------- |
| `narrative-output/report.md`      | Finished narrative report from the Editor/orchestrator                     |
| `narrative-output/analyst.json`   | Findings with code file + line references from the Analyst                 |
| `narrative-output/detective.json` | Context items with source URLs from the Detective                          |
| `narrative-output/editor.md`      | Editorial outline — used to confirm which findings made it into the report |
| `narrative-output/analyst/`       | Actual Python scripts produced by the Analyst                              |

---

## Workflow

### Step 1: Parse Report Claims

Read `report.md` sentence by sentence. Extract every sentence that:

- States a specific number, percentage, or statistic
- Makes a comparative claim ("X is higher than Y", "increased by Z%")
- Attributes a fact to an external source
- Names a specific finding as a key insight

Assign each a `claim_id` in the format `claim-001`, `claim-002`, etc. (zero-padded to 3 digits).

### Step 2: Bind to Analyst Code

For each extracted claim, search `analyst.json` for the finding that produced it. When found:

- Set `evidence_type: "code"` (or `"both"` if also reference-backed)
- Set `evidence.code.script` to the relative path of the Python script in `narrative-output/analyst/`
- Set `evidence.code.line_start` / `line_end` to the lines in that script where the result is computed
- Set `evidence.code.result_variable` to the variable that holds the reported value

### Step 3: Bind to Detective References

For contextual or background claims not produced by code, search `detective.json` for a matching context item:

- Set `evidence_type: "reference"` (or `"both"` if also code-backed)
- Set `evidence.reference.url` to the source URL from `detective.json`
- Set `evidence.reference.excerpt` to the relevant passage from the source

### Step 4: Flag Unbound Claims

Any claim that has no matching Analyst finding and no matching Detective source:

- Mark `evidence_type: "reference"` and set `evidence.reference.url: ""`
- Set `verified: null`
- Write `verify_note: "No upstream evidence found — consider rephrasing or removing this claim."`

### Step 5: Write inspector.json

Produce `narrative-output/inspector.json` conforming to the schema at `references/output-schema.json`.

Required fields:

```json
{
  "meta": {
    "dataset": "<path/name of source dataset>",
    "report_file": "narrative-output/report.md",
    "generated_at": "<ISO 8601 UTC timestamp>",
    "roles": {
      "detective": "narrative-output/detective.json",
      "analyst":   "narrative-output/analyst.json",
      "editor":    "narrative-output/editor.md"
    }
  },
  "claims": [ ... ],
  "summary": null
}
```

Leave `summary: null` — `verify_claims.py` populates this when the human runs verification.

### Step 6: Append Provenance Footer to report.md

Append a `## Provenance` section at the end of `report.md`:

```markdown
## Provenance

This report was produced by the `data-narrative` skill. Every quantitative
claim traces to the Analyst code that computed it; every contextual claim
traces to the Detective source that supplied it.

To verify all claims, run:
```

```bash
python skills/data-narrative/inspector/scripts/verify_claims.py \
    --inspector narrative-output/inspector.json
```

```markdown
Full provenance manifest: `narrative-output/inspector.json`
Schema: `skills/data-narrative/inspector/references/output-schema.json`
```

---

## Output

| File                              | Description                                   |
| --------------------------------- | --------------------------------------------- |
| `narrative-output/inspector.json` | Provenance manifest (schema-compliant)        |
| `narrative-output/report.md`      | Updated in place — Provenance footer appended |

---

## Coverage Target

Aim to bind ≥ 80% of quantitative claims to code evidence. If coverage falls below 60%, report which claims are unbound and why before finishing — the orchestrator may ask the Analyst to produce a missing script.
