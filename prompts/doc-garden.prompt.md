---
agent: guardian
description: Audit documentation for staleness, dead cross-references, version mismatches, and contradictory guidance. Produces a Doc Health Report with specific findings and fix recommendations. Use on a regular cadence or after significant changes to keep the knowledge base trustworthy for agents.
argument-hint: "[scope: 'all', 'spec', 'context', 'state', or specific file/folder]"
tools:
  - read
  - search
  - execute
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Audit the documentation in this repository for freshness, accuracy, and internal consistency.

**Scope**: ${input:scope}

**Workflow**: Load `skills/guardian/references/doc-audit-checklist.md` via `read_file`. The checklist is the single source of truth for the 6 audit categories, severity definitions, the `audit.py --lint` cross-check, and the Doc Health Report format. Follow it; do not paraphrase here.

**Output**: `.copilot/artifacts/doc-health-report.md` (overwrite if it exists), plus a one-paragraph summary in this conversation pointing the user at the Critical findings first.
