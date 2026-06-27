---
agent: guardian
description: Request a structured code review from the Guardian agent. Produces a PASS/FAIL/NEEDS WORK gate report with security, quality, and performance findings. Use when you want a formal review before merging or shipping.
argument-hint: "[file, folder, or PR to review]"
tools:
  - read
  - search
  - agent
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

{% if input:target %}
Review the following code: **${input:target}**

**Process**:

1. Load `~/.copilot/skills/guardian/SKILL.md` via `read_file`. The skill is the single source of truth for review scope (Security / Correctness / Performance / Maintainability / Architecture), severity calibration, and report format. If `~/.copilot/skills/guardian/SKILL.md` cannot be read, stop and respond with: "Error: Could not load SKILL.md from `~/.copilot/skills/guardian/SKILL.md`. Ensure the file exists and is readable before retrying. Review cannot proceed without it."
2. Run the Review Workflow defined in that skill against `${input:target}`.
3. Produce the review report using the skill's `review_report.md` template.
4. Persist to `.copilot/artifacts/review-report.md`, overwriting any existing file. Do not append or version the filename.

A team lead must be able to make a ship/no-ship decision from this report without re-reading the code.
{% else %}
**Error**: Missing or invalid target. Please provide a file, folder, or PR to review via the `target` parameter.

Example usage:

- `target: src/main.js`
- `target: ./api/controllers`
- `target: PR#42`

Cannot proceed without a valid review target.
{% endif %}
