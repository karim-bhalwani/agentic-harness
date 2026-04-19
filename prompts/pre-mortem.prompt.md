---
agent: guardian
description: "Run a pre-mortem analysis on code to identify fragility against future edits. Produces fictional post-mortem reports for bugs that have not happened yet but plausibly could. Use when you want to harden code before it breaks, not after."
argument-hint: "[file, folder, or module to analyze]"
tools:
  - read
  - search
  - agent
version: "7.0"
updated: "2026-04-12"
---

Analyze the following code for **fragility against future edits**: **${input:target}**

This is a pre-mortem, not a bug hunt. The code may be correct today. You are looking for places where a developer who lacks full context could make a seemingly reasonable change that breaks something non-obviously.

## Instructions

1. Load `skills/guardian/references/fragility-catalogue.md` before starting analysis.
2. Read the target code deeply. Understand data flow, state management, implicit invariants, and relationships between components. Read callers and callees, not just the file in isolation.
3. For each fragility found, write a fictional post-mortem using the format from the catalogue. Each must reference actual functions, variables, and file paths.
4. Produce the report using the Report Structure from the catalogue.

## Scope Rules

- Focus on production code. Config files, migrations, and boilerplate are out of scope unless they contain logic other code depends on.
- Target 3-7 findings per module. Quality over quantity.
- Every imagined change must be plausible (refactoring, feature addition, dependency upgrade). No adversarial scenarios.
- If you find an actual current bug, flag it separately at the top of the report.

## Output

Produce a single Pre-Mortem Report with:

1. **Summary**: fragility posture, dominant themes, systemic vs. independent
2. **Post-Mortems**: each with severity, component, fragility type, what happened, the change, why it broke, how it was caught, hardening suggestions
3. **Themes and Recommendations**: cross-cutting patterns and structural fixes
