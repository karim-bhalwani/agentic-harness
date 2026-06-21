---
agent: senior-developer
description: Fast lane for small, low-risk changes that bypass the full pipeline. Typo fixes, config tweaks, minor style improvements, one-liner bug fixes, and small papercuts. Use when the change is single-file, under ~20 lines, introduces no new dependencies, and the correct outcome is obvious.
argument-hint: "[describe the small fix needed]"
tools:
  - read
  - search
  - edit
  - execute
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Apply this quick fix: **${input:fix}**

If the input fix description is invalid or unclear, respond with: "The fix description is ambiguous. Please clarify."

**Eligibility check** (all must be true, otherwise use `/feature-plan` instead):

- Single file change (or 2-3 files for a rename/refactor ripple)
- Under ~20 lines changed
- No new dependencies introduced
- No architectural or API contract changes
- Fix description includes a clear expected outcome, verifiable through automated tests or a defined manual checklist
- Not a security-critical code path

If ANY condition is false, stop and say: "This exceeds quick-fix scope. Use `/feature-plan` to plan it properly."

**Process** (streamlined, no spec required):

1. **Read** the target file and surrounding context
2. **Match conventions** of the existing code (naming, style, patterns)
3. **Apply** the minimal change that solves the stated problem
4. **Verify** by running lint/typecheck if configured; run affected tests if they exist
5. **Self-check**: re-read the diff. Is it correct, complete, and minimal?

**Output**:

- State what was changed and why (one sentence)
- Show the diff or changed lines
- Note any test results if tests were run

No spec. No Guardian review. No handoff. Just fix it.
