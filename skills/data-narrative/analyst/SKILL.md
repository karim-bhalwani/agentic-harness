---
name: analyst
description: "Analyst sub-role of the data-narrative skill. Delegates exhaustive dataset profiling to the data-science skill, then emits analyst.json - a structured list of findings where every finding carries a pointer to the script and line that produced it. Loaded and invoked by the data-narrative orchestrator only."
user-invocable: false
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: ["data-science"]
---

# data-narrative - Analyst Role

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

The Analyst runs exhaustive analysis on the dataset and produces a structured findings manifest where every result is paired with the code that generated it. The goal is completeness: surface every pattern, trend, correlation, and anomaly the data can support - not just the obvious ones. The Editor selects which findings are worth narrating; the Analyst's job is to produce the full menu.

---

## Behavioral Directives

- **Load `data-science` skill first.** Follow its EDA Workflow as the authoritative sequence for profiling: shape, types, missingness, distributions, outliers, correlations, and class balance. The 7-step list in Step 1 below is a fallback reference only - use it if the `data-science` skill is unavailable or does not specify a step for a given analysis type. The `data-science` skill is the authoritative reference for statistical testing, modeling, and experiment analysis.
- **Completeness over selection.** Run every analysis the dataset permits. Do not pre-filter by what seems interesting - that is the Editor's job.
- **Code for every finding.** Every finding in `analyst.json` must have a companion Python script in `narrative-output/analyst/`. No finding should be computed mentally or approximated.
- **One script per finding group.** Group related computations (e.g., all distribution stats for a column) into a single script. Do not split trivially related computations across multiple files.
- **Scripts must be self-contained and reproducible.** Each script reads the source dataset from a path argument or a well-known relative path (`data/`, the dataset name passed in). It must run cleanly with standard libraries (pandas, numpy, scipy, matplotlib).
- **Emit line references.** After writing each script, record the exact line numbers where the key result variable is computed. The Inspector depends on this.

---

## Inputs

| Input                             | Description                                                                                                     |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `narrative-output/preflight.json` | Pre-flight record - read this first to know the mode (single/multi), file list, relationship type, and join key |
| `narrative-output/detective.json` | Context from the Detective - domain background and definitions                                                  |

**Multi-file handling:**

- `"relationship": "union"` → concatenate files into one DataFrame before profiling (`pd.concat`). Add a `source_file` column so findings can trace back to the origin file if needed.
- `"relationship": "join"` → merge on `join_key` before profiling (`pd.merge`). Profile the joined result as the primary unit of analysis. Also profile individual files to support cross-file comparisons (e.g., "customers in region X have 2× higher order value") - these are the most valuable angle for the Editor. If `join_key` is missing from `preflight.json` or is not present in all files, halt the merge, report the specific error in the Step 4 summary (e.g., "join_key 'customer_id' not found in orders.csv"), and profile individual files independently as a fallback.
- If the `relationship` field is absent or contains an unrecognised value, treat each file as independent and profile them separately. Record a warning in the Step 4 summary describing the unrecognised value and the fallback taken.

## Outputs

| File                            | Description                                 |
| ------------------------------- | ------------------------------------------- |
| `narrative-output/analyst.json` | Structured findings manifest (schema below) |
| `narrative-output/analyst/*.py` | One Python script per finding group         |

---

## Workflow

### Step 1: Understand the Dataset

Load `narrative-output/detective.json` to read domain context before touching the data. This prevents misinterpreting column names or units (e.g., knowing "revenue" is in thousands, not raw dollars). If `narrative-output/detective.json` is absent or cannot be parsed, proceed without domain context and record a warning in the Step 4 summary: "detective.json unavailable - column names and units interpreted at face value." Do not halt execution.

Then profile the dataset using the `data-science` EDA Workflow sequence:

1. Shape and dtypes (`df.shape`, `df.dtypes`, sample 10 rows)
2. Missing data (per-column null counts and %)
3. Distributions (histograms for numerics, value counts for categoricals)
4. Outliers (IQR or z-score on numerics)
5. Correlations (pairwise for numerics; flag |r| > 0.7)
6. Temporal patterns if a date column exists (trend, seasonality, anomalies)
7. Group comparisons if categorical columns exist (means, proportions by group)

### Step 2: Write Findings Scripts

For each analysis area in the EDA Workflow sequence (Steps 1–7), write a Python script to `narrative-output/analyst/` regardless of whether the results appear interesting. Only omit a script if the analysis is structurally inapplicable to the dataset (e.g., no date column exists for temporal analysis). Name scripts descriptively:

- `distributions.py` - column distributions and summary stats
- `correlations.py` - correlation matrix and top pairs
- `trend_<column>.py` - time trend for a specific column
- `group_compare_<col>.py` - group comparison for a categorical breakdown
- `outliers.py` - outlier detection results

Every script must:

1. Accept dataset path via `argparse` or read from `data/` by default
2. Print key results to stdout in a structured format (JSON or labeled text)
3. Save any plots to `narrative-output/analyst/plots/` as PNG files
4. Exit 0 on success

### Step 3: Produce analyst.json

Write `narrative-output/analyst.json` with this structure:

```json
{
  "dataset": "<dataset path or name>",
  "generated_at": "<ISO 8601 UTC>",
  "findings": [
    {
      "finding_id": "finding-001",
      "title": "Short descriptive title",
      "description": "One or two sentences describing the finding in plain English",
      "finding_type": "distribution|trend|correlation|outlier|group_comparison|anomaly|other",
      "significance": "high|medium|low",
      "result_value": "<the specific number, range, or conclusion>",
      "code": {
        "script": "narrative-output/analyst/distributions.py",
        "line_start": 42,
        "line_end": 51,
        "result_variable": "top_category_share"
      },
      "plot": "narrative-output/analyst/plots/distributions.png"
    }
  ]
}
```

`significance` guidance:

- **high**: finding would likely anchor a paragraph in the final story (large effect, clear trend, striking anomaly)
- **medium**: supporting detail worth mentioning
- **low**: context or background, probably cut by the Editor

### Step 4: Report to Orchestrator

After writing `analyst.json`, summarise:

- Total findings produced
- Count by significance level
- Any columns that yielded no interesting findings (so the Editor knows what to skip)
- Any data quality issues encountered (missing data patterns, suspect values)

---

## Quality Bar

A finding qualifies for `analyst.json` only if:

- It is computed by code, not estimated mentally
- The result is specific (a number, a percentage, a named category) - not vague ("there is some variation")
- The companion script runs cleanly from the command line
