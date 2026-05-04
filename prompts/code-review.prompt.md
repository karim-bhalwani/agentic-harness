---
agent: guardian
description: Request a structured code review from the Guardian agent. Produces a PASS/FAIL/NEEDS WORK gate report with security, quality, and performance findings. Use when you want a formal review before merging or shipping.
argument-hint: "[file, folder, or PR to review]"
tools:
  - read
  - search
  - agent
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Review the following code: **${input:target}**

**Process** (do not duplicate skill content here, always defer to the skill):

1. Load `skills/guardian/SKILL.md` via `read_file`. The skill is the single source of truth for review scope (Security / Correctness / Performance / Maintainability / Architecture), severity calibration, and report format.
2. Run the Review Workflow defined in that skill against `${input:target}`.
3. Produce the review report using the skill's `review_report.md` template.
4. Persist to `.copilot/artifacts/review-report.md` so `release-manager` can verify it via `verify_review.py`.

A team lead must be able to make a ship/no-ship decision from this report without re-reading the code.
