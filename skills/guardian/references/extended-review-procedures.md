# Guardian Deep-Dive: Extended Review Procedures

> Deep-dive reference. Loaded on demand for full pre-landing reviews, entropy audits, wiki health, and quality grading.

## Documentation Staleness Detection

After reviewing code changes, check whether related documentation was updated.

**Procedure**:

1. **Identify changed modules**: From the diff, list the components, modules, or features that were modified.
2. **Scan for related docs**: Search for `.md` files in the repo root and `docs/` that reference those components (by name, path, or description).
3. **Cross-reference**: If a doc describes behavior that was changed in this diff but the doc was NOT updated, flag it.

**Output format** (appended to the review report):

```markdown
### Documentation Staleness

| Doc File    | Describes     | Stale? | Reason                                     |
| ----------- | ------------- | ------ | ------------------------------------------ |
| README.md   | CLI usage     | YES    | New --format flag added but not documented |
| docs/api.md | API endpoints | NO     | N/A                                        |

**Doc Verdict**: UP TO DATE | STALE DOCS DETECTED
```

**Rules**:

- Staleness findings are **Informational** severity (do not block merge).
- Only check `.md` files that are user-facing documentation, not internal notes or changelogs.
- If no documentation exists for the changed component, note "No docs found for [component]" as a Low-severity suggestion.

## Review Report Artifact Persistence

After completing the Three-Phase review, persist the full review report to disk.

**Target path**: `.copilot/artifacts/review-report.md`

**Procedure**:

1. Save the complete report to `.copilot/artifacts/review-report.md`. Create the directory if it does not exist.
2. The report must include all sections: Scope Audit, Phase 1 Critical, Phase 2 Informational, Documentation Staleness, Summary line.
3. Add a metadata header:

```markdown
---
date: YYYY-MM-DD
reviewed-files: [list of files in the diff]
scope-verdict: ON TRACK | DRIFT DETECTED | INCOMPLETE | N/A
doc-verdict: UP TO DATE | STALE DOCS DETECTED | N/A
summary: "N issues (X critical, Y informational)"
---
```

**Rules**:

- Each review **overwrites** the previous `review-report.md`.
- If the review was partial, omit missing sections but still write the file.
- This step is the **last action** in any pre-landing review.

## Receiving Feedback

### No Performative Agreement

These responses are **forbidden**:

- "You're absolutely right!"
- "Great point!"
- "That's a really good suggestion!"

Instead, do one of:

- **Agree and act**: "This changes the auth check. Fixing now."
- **Disagree with evidence**: "The current approach is intentional because `[specific reason]`."
- **Neutral restatement**: "The suggestion is to replace `X` with `Y`. Evaluating..."

### YAGNI Check for External Suggestions

Before implementing any suggestion that adds a "more professional" feature:

1. `grep_search` for existing callers or references to the proposed abstraction.
2. If zero results: "No existing usage found. Applying YAGNI - this abstraction has no current consumers."
3. If results exist: implement the suggestion.

## Entropy Management (Codebase Hygiene)

### Principles

- **Technical debt is a high-interest loan**: pay it down continuously in small increments.
- **Detect drift early**: flag patterns that deviate from established conventions.
- **Report pattern rot**: if the codebase contains conflicting approaches to the same problem, surface it as Medium-severity.

### During Reviews, Check For

- [ ] Stale or conflicting documentation
- [ ] Duplicated utilities or helpers
- [ ] Inconsistent naming, logging, or error handling patterns
- [ ] Dead code, commented-out blocks, or abandoned feature flags
- [ ] Dependencies no longer used or superseded

### Remediation Approach

- Recommend targeted refactoring PRs (small, focused, one pattern at a time).
- Suggest linter rules or CI checks to enforce the preferred pattern.
- When a "golden pattern" exists elsewhere, cite it as the consolidation target.

## Quality Grading (Opt-In)

When `.copilot/quality/` exists, append a quality grade entry after every review.

**Procedure**:

1. Load the [quality_grades.md](./quality_grades.md) template.
2. If `.copilot/quality/QUALITY_GRADES.md` does not exist, create it from the template.
3. After completing the review, derive the grade and append one entry (never modify previous entries).

**Grade derivation**:

| Condition                                              | Grade |
| ------------------------------------------------------ | ----- |
| 0 Critical + 0 High, tests pass, docs current          | A     |
| 0 Critical, 1-2 High with clear remediation            | B     |
| 1+ Critical OR 3+ High                                 | C     |
| Scope drift detected OR spec coverage < 70%            | D     |
| Architectural misalignment or security redesign needed | F     |

**Skip signal**: If `.copilot/quality/` does not exist, skip grading.

## Mem Knowledge Artifact Health Check

When auditing documentation, extend checks to include the project's knowledge mem if `llmmem/mem/index.md` exists.

### Checks

- **Index vs. filesystem drift**: Compare `llmmem/mem/index.md` entries against actual files. Report missing files and unlisted articles.
- **Cross-reference integrity**: Verify all markdown links within mem articles resolve to existing files.
- **Raw reference integrity**: Verify all Raw field links point to existing `llmmem/raw/` files.
- **Contradictory claims**: Scan for factual conflicts between mem articles.
- **Orphan detection**: Identify mem articles with zero inbound links.
- **Stale content**: Check if mem articles reference code patterns the codebase has moved on from.

### Output Format

```markdown
### Mem Health

| Issue         | Type             | File                                                                    | Details                                      | Severity |
| ------------- | ---------------- | ----------------------------------------------------------------------- | -------------------------------------------- | -------- |
| Broken link   | Index drift      | llmmem/mem/index.md                                                    | Entry for `scaling-laws.md` but file missing | Medium   |
| Orphan page   | No inbound links | llmmem/mem/concepts/old-pattern.md                                     | Zero references from other articles          | Low      |

**Wiki Verdict**: HEALTHY | NEEDS ATTENTION | NOT PRESENT
```

**Rules**:

- Wiki health findings are **Informational** severity.
- If `llmmem/mem/index.md` does not exist, report `Wiki Verdict: NOT PRESENT` and skip.


