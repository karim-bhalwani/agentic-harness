---
agent: guardian
description: Audit documentation for staleness, dead cross-references, version mismatches, and contradictory guidance. Produces a Doc Health Report with specific findings and fix recommendations. Use on a regular cadence or after significant changes to keep the knowledge base trustworthy for agents.
argument-hint: "[scope: 'all', 'spec', 'context', 'state', or specific file/folder]"
tools:
  - read
  - search
  - execute
  - edit
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Audit the documentation in this repository for:

- **Freshness**: Documentation reflects current product versions, features, and API behaviors; outdated timestamps or deprecated references.
- **Accuracy**: Technical content is correct, code examples run without errors, and claims are verifiable against source code or specifications.
- **Internal Consistency**: Definitions, terminology, and guidance are uniform across all docs; cross-references are valid; no contradictory instructions.

**Scope**: ${input:scope}

**Priority 1: Load Audit Criteria**
Load `~/.copilot/skills/guardian/references/doc-audit-checklist.md` via `read_file`. If inaccessible, halt and report: "Critical: doc-audit-checklist.md is inaccessible. Cannot proceed without audit criteria."

**Priority 2: Audit One Category at a Time**
For each category in the checklist (in order), scan the documentation and record findings with severity levels. Focus on one category completely before moving to the next.

**Priority 3: Validate Cross-References**
Execute `audit.py --lint` to check for broken links and version mismatches. If `audit.py --lint` is not found or exits with an error, record a Critical finding: "audit.py --lint failed: [error output]. Cross-reference validation incomplete." and continue to Priority 4.

**Priority 4: Generate Report**
Create `.copilot/artifacts/doc-health-report.md` with all findings, organized by severity (Critical first, then High, Medium). If the target directory does not exist, create it before writing the report. If the write fails, output the full report content directly in the conversation and note the write failure.

**Priority 5: Summarize**
Provide a one-paragraph summary in conversation, highlighting Critical findings only.
