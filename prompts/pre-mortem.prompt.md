---
agent: guardian
description: Run a pre-mortem analysis on code to identify fragility against future edits. Produces fictional post-mortem reports for failure scenarios catalogued as likely in the fragility catalogue. Use when you want to harden code before it breaks, not after.
argument-hint: "[file, folder, or module to analyze]"
tools:
  - read
  - search
  - agent
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Analyze the following file, folder, or module for **fragility against future edits**: **${input:target}**

This is a pre-mortem, not a bug hunt. The code may be correct today. You are looking for places where a developer who lacks full context could make a seemingly reasonable change that breaks something non-obviously.

**Workflow**: Follow these steps in order:

1. Load `~/.copilot/skills/guardian/references/fragility-catalogue.md` via `read_file` - this is the single source of truth. If the file cannot be read, stop and respond with: "Pre-mortem analysis cannot proceed: fragility-catalogue.md was not found at ~/.copilot/skills/guardian/references/. Please verify the path and retry."
2. Ensure all findings align with the fragility taxonomy defined in the catalogue.
3. Limit findings to 3–7 per module (scope: production code only). If the target contains no production code files, respond with a one-line note at the top of the report: "No production code found in target - pre-mortem analysis skipped."
4. Focus exclusively on scenarios that have a clear and documented likelihood of occurring based on the fragility catalogue; do not introduce scenarios that are not represented in the catalogue taxonomy.
5. Use the post-mortem format and report structure from the catalogue exactly; do not paraphrase.

**Output**: A single Pre-Mortem Report at `.copilot/artifacts/pre-mortem-${input:target}.md` (or respond inline if the target is a single file under 150 lines of code). If you find an actual current bug during analysis, flag it separately at the top of the report.
