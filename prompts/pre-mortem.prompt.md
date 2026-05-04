---
agent: guardian
description: Run a pre-mortem analysis on code to identify fragility against future edits. Produces fictional post-mortem reports for bugs that have not happened yet but plausibly could. Use when you want to harden code before it breaks, not after.
argument-hint: "[file, folder, or module to analyze]"
tools:
  - read
  - search
  - agent
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Analyze the following code for **fragility against future edits**: **${input:target}**

This is a pre-mortem, not a bug hunt. The code may be correct today. You are looking for places where a developer who lacks full context could make a seemingly reasonable change that breaks something non-obviously.

**Workflow**: Load `skills/guardian/references/fragility-catalogue.md` via `read_file`. The catalogue is the single source of truth for the fragility taxonomy, scope rules (production code, 3-7 findings per module, plausible scenarios only), the post-mortem format, and the report structure. Follow it; do not paraphrase here.

**Output**: A single Pre-Mortem Report at `.copilot/artifacts/pre-mortem-${input:target}.md` (or in conversation if the target is small). If you find an actual current bug during analysis, flag it separately at the top of the report.
