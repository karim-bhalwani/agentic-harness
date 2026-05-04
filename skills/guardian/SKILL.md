---
name: guardian
description: "Comprehensive quality assurance, security auditing, automated testing, and performance optimization. Covers code review, OWASP Top 10, testing pyramid, E2E automation, visual regression, and vulnerability scanning. Use when reviewing code, hunting bugs, scanning for vulnerabilities, profiling performance, building test suites, or validating implementation quality. DO NOT USE FOR: writing production code (use implementer), system design (use architect), debugging root cause analysis (use systematic-debugging), or LLM-specific security (use genai-security)."
argument-hint: "[code to review]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: []
---

# Guardian Skill - QA, Security, Testing & Performance

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani | Tiered: core (~150 lines) + on-demand references

Unified reference for code quality gates. For extended procedures (doc staleness, entropy, wiki health, quality grading, feedback rules), load the deep-dive reference.

## Code Review Standards

### SOLID & Clean Code

- Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion

### Review Checklist

- [ ] Naming clarity (no abbreviations without context)
- [ ] Cognitive complexity < 15 per function
- [ ] No dead code or commented-out blocks
- [ ] Error paths tested and handled
- [ ] Type hints on all public interfaces

### Pre-Landing Review (Four-Phase)

0. **Phase 0 (SCOPE AUDIT)**: Verify implementation matches spec before assessing quality. See Scope Drift Detection below.
1. **Phase 1 (CRITICAL)**: SQL & Data Safety, Race Conditions, LLM Trust Boundary, Auth. Blocks merge. Load [review-checklist.md](./references/review-checklist.md) for full checklist.
2. **Phase 2 (INFORMATIONAL)**: Side Effects, Dead Code, Test Gaps, Performance, Crypto, Doc Staleness. Advisory only.
3. **Phase 3 (FRAGILITY, opt-in)**: Future-edit fragility analysis. For each non-trivial function, ask: "What plausible change by a developer without full context would break this?" Load [fragility-catalogue.md](./references/fragility-catalogue.md) for the 10-pattern catalogue and post-mortem format. Activate via `/pre-mortem` prompt or when explicitly requested.

### Scope Drift Detection

Before reviewing quality, verify implementation matches the spec/plan:

1. Identify the spec (conversation context, `.copilot/specs/SPEC.md`, or PR description)
2. Extract actionable items from the spec
3. Classify each as: **DONE**, **PARTIAL**, **NOT DONE**, **CHANGED**, **SCOPE CREEP**
4. Report as a Scope Audit table with verdict: ON TRACK | DRIFT DETECTED | INCOMPLETE

If no spec is available, skip and note "No spec/plan in context; scope audit skipped."

## Testing Pyramid (Summary)

- **Unit (70-80%)**: one behavior per test, no I/O, descriptive names
- **Integration (15-20%)**: test component boundaries, isolated state
- **E2E (5-10%)**: critical user workflows only, stable selectors, screenshot on failure
- **Deterministic**: control time, randomness, network; no sleep()

## Security Auditing (OWASP Top 10 Summary)

- **A01 Broken Access Control**: authorize every endpoint, default-deny, IDOR checks
- **A02 Cryptographic Failures**: TLS 1.2+, AES-256-GCM, no MD5/SHA-1, secrets in vault
- **A03 Injection**: parameterized queries, input validation, output encoding
- **A04 Insecure Design**: STRIDE threat model, rate limiting, circuit breakers
- **A05 Misconfiguration**: remove defaults, disable stack traces, security headers
- **A06 Vulnerable Components**: pin versions, CVE scanning in CI
- **A07 Auth Failures**: MFA, lockout, session rotation
- **A08 Data Integrity**: verify signatures, no pickle/eval
- **A09 Logging Failures**: structured logging, no secrets in logs
- **A10 SSRF**: allowlist outbound URLs, block internal ranges

For GenAI/LLM security, load the `genai-security` skill.

## Performance Profiling (Summary)

**Measure first**: CPU (cProfile, py-spy), Memory (tracemalloc), I/O (connection pool metrics), Latency (p95/p99).

**Optimization priorities**: Algorithm complexity > I/O reduction > Caching > Concurrency > Memory.

## Calibration

Load calibration examples when judgment is uncertain:

- [true_positives.md](./references/calibration_examples/true_positives.md) - Bugs Guardian MUST catch
- [false_positives.md](./references/calibration_examples/false_positives.md) - Patterns that look suspicious but are correct
- [severity_calibration.md](./references/calibration_examples/severity_calibration.md) - Over/under-graded findings

## Mandatory Report Structure

```markdown
## Guardian Review Report

### Scope Audit

[Scope drift table or "No spec/plan in context; scope audit skipped."]

### Summary

[Overall health assessment and risk level]

### Gate Status: [PASS | FAIL | NEEDS WORK]

### Findings

| # | Severity | Category | Finding | Remediation |

### Strengths

[Acknowledge well-designed patterns]

### Test Coverage Assessment

### Documentation Staleness

[Load extended-review-procedures.md for full procedure]
```

## Definition of Done

- [ ] Scope audit completed (or noted as skipped)
- [ ] Review report follows Mandatory Report Structure
- [ ] All Critical/High findings have specific remediation steps
- [ ] Gate status explicitly stated
- [ ] Documentation staleness check completed
- [ ] Strengths section acknowledges well-designed patterns

## Constraints

- Does NOT modify code (read-only analysis and reporting)
- Does NOT implement fixes (hand off to implementation agent)
- Does NOT replace formal security audits or compliance certifications

## Scripts

- [scripts/verify_review.py](./scripts/verify_review.py) - Verification gate for `.copilot/artifacts/review-report.md`. Run from the orchestrating agent (typically Release Manager) before gating on the review verdict. Guardian itself cannot write files (no `editFiles` tool); the orchestrator or user persists the report. Exits 1 if the report is missing, too short, or lacks expected tokens (Findings/Verdict/Severity/Scope).

## References

Load on demand for specific sub-tasks:

- [extended-review-procedures.md](./references/extended-review-procedures.md) - Doc staleness detection, artifact persistence, feedback rules, entropy management, quality grading, wiki health. **Load for full pre-landing reviews.**
- [code-review.md](./references/code-review.md) - Code review checklist and criteria.
- [review-checklist.md](./references/review-checklist.md) - Phase 1/2 checklist with suppressions.
- [review_report.md](./references/review_report.md) - Structured review report template.
- [quality_grades.md](./references/quality_grades.md) - Quality grading template (opt-in when `.copilot/quality/` exists).
- [calibration_examples/](./references/calibration_examples/) - True positives, false positives, severity calibration.
- [fragility-catalogue.md](./references/fragility-catalogue.md) - 10-pattern fragility catalogue for pre-mortem analysis. Identifies code that is correct today but fragile against future edits. Loaded by Phase 3 review and `/pre-mortem` prompt.
- [doc-audit-checklist.md](./references/doc-audit-checklist.md) - 6-category documentation freshness, accuracy, and consistency audit. Defines scope modes, severity levels, and the Doc Health Report format. Loaded by the `/doc-garden` prompt.

### Scripts

- [generate_review_report.py](./scripts/generate_review_report.py) - Programmatic review report scaffolding.
