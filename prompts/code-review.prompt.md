---
agent: guardian
description: Request a structured code review from the Guardian agent. Produces a PASS/FAIL/NEEDS WORK gate report with security, quality, and performance findings. Use when you want a formal review before merging or shipping.
argument-hint: "[file, folder, or PR to review]"
tools:
  - read
  - search
  - agent
version: "7.0"
updated: "2026-04-12"
---

Review the following code: **${input:target}**

Scope:

- **Security**: OWASP Top 10, injection, auth, secrets exposure
- **Correctness**: logic errors, edge cases, null handling, type safety
- **Performance**: N+1 queries, unnecessary allocations, blocking I/O
- **Maintainability**: naming, complexity, dead code, missing tests
- **Architecture**: module boundary violations, coupling, cohesion

Produce a structured review report using `review_report.md` template format:

1. **Verdict**: PASS | NEEDS WORK | FAIL + one-sentence rationale
2. **Critical findings** (block merge): numbered list, each with file+line reference and remediation
3. **Warnings** (fix before next sprint): numbered list
4. **Suggestions** (optional improvements): numbered list
5. **Test coverage assessment**: what's missing, what's sufficient

A team lead must be able to make a ship/no-ship decision from this report without re-reading the code.

