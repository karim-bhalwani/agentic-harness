---
name: ops
description: "CI/CD pipelines, GitHub Actions workflows, Docker configurations, deployment automation, and release management patterns. Use when building CI/CD, writing GitHub Actions, creating Docker configs, automating deployments, managing releases, or setting up infrastructure-as-code. DO NOT USE FOR: writing application-specific business logic (use implementer), designing high-level system architecture or topology (use architect), performing security audits (use guardian), or orchestrating data pipelines like Airflow DAGs (use data-engineering)."
argument-hint: "[CI/CD or deployment task]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: []
---

# Ops Skill - CI/CD, Deployment & Automation

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani | Tiered: core (~140 lines) + on-demand references

Unified reference for operational automation. For copy-ready templates (GitHub Actions, Docker, Terraform, release checklists), load the deep-dive reference.

## Core Principles

- **Immutable artifacts**: every build produces a versioned, unchangeable artifact
- **Environment parity**: dev/staging/prod from same templates
- **Secrets in vaults**: never in code, config, or CI logs
- **Rollback before deploy**: document rollback plan BEFORE deployment

## Mechanical Enforcement

> When a behavioral rule fails twice in retrospectives, promote it to a mechanical check. Linters and CI are more reliable than prompt instructions.

### Promote-to-Code Decision Rule

1. **Trigger**: behavioral rule caused rework 2+ times
2. **Action**: write a mechanical check (pre-commit hook, lint rule, or CI job)
3. **Record**: log in `.copilot/context/DECISIONS.md` as an ADR
4. **Remove redundancy**: mechanical enforcement becomes primary; prompt instruction becomes documentation

### Enforcement Layers

| Layer                | Catches                                              | Speed   | Scope      |
| -------------------- | ---------------------------------------------------- | ------- | ---------- |
| **Pre-commit hooks** | Style, structure, obvious violations                 | Seconds | Per-commit |
| **CI workflow**      | Cross-file issues, Bible freshness, doc staleness    | Minutes | Per-PR     |
| **Guardian review**  | Design quality, logic correctness, architectural fit | Minutes | Per-PR     |

Load [mechanical-enforcement.md](./references/mechanical-enforcement.md) for copy-ready pre-commit, ruff, and CI config templates.

## Quick Reference: Key Patterns

### GitHub Actions

- Standard CI: lint > test > security scan (parallel where possible)
- Reusable workflows via `workflow_call` for DRY deployment
- Matrix strategy for cross-version/cross-OS testing
- Cache pip/npm dependencies with `actions/cache@v4`

### Docker

- Multi-stage builds, pin base image versions, non-root user
- `.dockerignore` for build context optimization
- Health checks for orchestrated deployments

### Deployment

- Azure: OIDC via `azure/login@v2`, deployment slots for zero-downtime
- Databricks: Asset Bundles for pipeline deployment
- Blue-green or canary for stateless services
- Database migrations: forward-only with backward compatibility

### Release Management

- Semantic versioning: `MAJOR.MINOR.PATCH`
- Changelog in Keep a Changelog format
- Release checklist: CI green, changelog updated, version bumped, security scan clean, staging tested, rollback documented, tag pushed

### Infrastructure as Code

- Terraform: modules for reuse, remote state backend, environment variables
- Idempotent: running twice produces same result

For full templates and examples of all patterns above, load [cicd-patterns-deep-dive.md](./references/cicd-patterns-deep-dive.md).

## Definition of Done

- [ ] CI pipeline runs green (lint, test, security scan)
- [ ] Docker image builds and runs with health check passing
- [ ] Rollback plan documented before deployment
- [ ] Secrets managed via vault/env vars (none in code)
- [ ] Release checklist completed
- [ ] Mechanical enforcement in place for P1 invariants

## Constraints

- Does NOT write application business logic (pipelines and automation only)
- Does NOT manage secrets directly (provides vault integration patterns)
- Does NOT perform security audits (consult guardian)
- Does NOT design system architecture (consult architect)

## Common Pitfalls

- Over-complex pipelines: start simple, add stages only when justified
- Missing rollback plan: every deployment needs one
- Secret leakage: never echo secrets in logs
- Flaky tests in CI: quarantine, don't ignore
- Manual steps in "automated" pipelines: if it requires human intervention, it's not automated

## Integration Points

- **guardian**: Reviews CI/CD configurations for security and quality
- **release-manager**: Consumes pipeline outputs for release decisions
- **architect**: Provides infrastructure architecture and deployment topology
- **data-engineering**: Deploys data pipelines via Airflow/Databricks workflows

## References

Load on demand for specific sub-tasks:

- [cicd-patterns-deep-dive.md](./references/cicd-patterns-deep-dive.md) - Full GitHub Actions templates (CI, reusable workflows, matrix, caching, PR automation), Docker patterns, deployment configs (Databricks, Azure), release management (semver, changelog, checklist), IaC (Terraform). **Load when building or modifying pipelines.**
- [mechanical-enforcement.md](./references/mechanical-enforcement.md) - Pre-commit hooks, ruff rules, GitHub Actions enforcement workflows.

### Scripts

- [check_pipeline_health.py](./scripts/check_pipeline_health.py) - CI/CD config validator (hard-coded secrets, unpinned images, deprecated runners, missing timeouts).
- [lint_agent_legible_errors.py](./scripts/lint_agent_legible_errors.py) - Linter enforcing agent-legible error messages with remediation hints.
