# SPEC.md Template (Architect Skill)

> Authoritative template for the architect skill's primary output. Loaded by reference from `~/.copilot/skills/architect/SKILL.md`.

This template applies to **EXPANSION** and **HOLD** modes only. REDUCTION mode produces no spec.

For **EXPANSION** mode, all thirteen sections are required - a specification that omits any section leaves room for interpretation and is not considered complete.

For **HOLD** mode, only sections 1, 3, 4, and 5 are required. Omit sections 2, 6–13 unless the feature introduces a new module boundary or data model change (see the Per-Mode Checklists in `SKILL.md`).

## Mandatory Frontmatter (Schema Version Contract)

Every `SPEC.md` **MUST** begin with a YAML frontmatter block that declares the artifact schema version. Downstream agents (Guardian, Senior Developer, Data Engineer, AI Engineer) read this version and refuse to operate on schemas they do not recognise.

```yaml
---
spec_schema_version: 1 # see tests/contracts/schema_versions.py
version: "0.1" # this individual spec document
status: "Draft" # Draft | In Review | Approved | Blocked | Deprecated
date: "01-July-2026"
owner: "<lead architect>"
holdout_reference: ".copilot/holdout/HOLDOUT-<feature-name>.md"
scope_mode: "EXPANSION" # REDUCTION | HOLD | EXPANSION
---
```

The matching `HOLDOUT-<feature-name>.md` file MUST declare:

```yaml
---
holdout_schema_version: 1
feature: "<feature-name>"
owner: "<lead architect>"
scenarios: <count, 3-10 typical>
---
```

Bumping a schema version is a **breaking change**: every consumer must be updated in lockstep. The full schema set lives under `tests/contracts/schemas/` and is validated by `tests/contracts/test_artifact_schemas.py`.

## Core Sections (1–4): System Design & Structure

1. **System Overview**: High-level goal, scope boundaries, identified business primitives, and the problem being solved. What is explicitly out of scope.
2. **Module Boundaries**: Proposed directory and file layout; responsible module per concern; one-sentence description test for every module; Mermaid component diagram showing component flow.
3. **API Contracts**: Method, path, payload, and response for every interface (RFC 7807 for errors). Includes event schemas for async interfaces. Input/output types and validation rules must be fully specified.
4. **Data Models**: Table/object schemas with field types, nullability, validation rules, and index strategy. Includes read schema and write schema separately where they differ.

## Operational Sections (5–9): Quality, Safety & Deployment

5. **Error Handling**: Error taxonomy (categories and codes); which errors are recoverable vs fatal; retry strategy per category; logging and alerting obligations per severity. Must include an **Error & Rescue Map** (see below).
6. **Security Considerations**: Authentication and authorization model; trust boundaries between modules; data sensitivity classification; secrets management approach; input validation requirements; known threat surface (STRIDE analysis for security-critical features).
7. **Performance Requirements**: Latency targets (p50/p95/p99); throughput requirements; known bottlenecks and mitigation strategy; caching policy; resource constraints (memory, CPU, I/O).
8. **Testing Strategy**: Unit test scope and coverage target; integration test boundaries; E2E scenarios for critical user workflows; determinism requirements (mocking time, network, randomness); CI tier per test type.
9. **Deployment Considerations**: Target environment; configuration and environment variables; migration plan for schema changes; rollback procedure; observability hooks (logging, tracing, alerting).

## Decision Sections (10–13): Unknowns, Risks & Acceptance

10. **Open Questions**: Decisions that are unresolved at spec time, each with an owner and resolution deadline. These must be resolved before implementation begins. If any Open Questions remain unresolved at spec completion, set frontmatter `status` to `"Blocked"` and do not advance to concise-planning until all questions have an owner-confirmed resolution documented in this section.
11. **Risks**: Identified design risks with likelihood, impact, and mitigation strategy. Includes architectural assumptions that, if wrong, would require significant rework.
12. **Deferred Decisions**: Design choices deliberately postponed with documented rationale, acceptance criteria for when they must be revisited, and who owns the revisit.
13. **Acceptance Scenarios**: Reference to the holdout file (`.copilot/holdout/HOLDOUT-<feature-name>.md`). Three to ten intent-level behavioral scenarios authored by the Architect, stored in the holdout directory. Scenarios are NOT included inline - they are referenced only. The spec records the holdout file path so stakeholders can locate it. Implementation agents must not open or read the holdout file contents; they may only see the reference path recorded here.

## Error & Rescue Map (Required in Section 5)

Every spec must include a structured Error & Rescue Map that enumerates every codepath that can fail. This prevents vague "handle errors appropriately" prose and forces systematic analysis of every failure mode.

**Step 1: Map codepaths to failure modes.**

```text
CODEPATH / METHOD          | WHAT CAN GO WRONG           | EXCEPTION / ERROR CLASS
----------------------------|-----------------------------|--------------------------
UserService.create          | Duplicate email             | IntegrityError
                            | DB connection timeout       | ConnectionTimeoutError
                            | Validation failure          | ValidationError
LLMService.generate         | API timeout                 | TimeoutError
                            | Rate limit (429)            | RateLimitError
                            | Malformed response          | JSONDecodeError
                            | Model refusal               | ContentFilterError
```

**Step 2: Map each error to its rescue action and user impact.**

```text
EXCEPTION / ERROR CLASS     | RESCUED? | RESCUE ACTION              | USER SEES              | TESTED?
-----------------------------|----------|----------------------------|------------------------|--------
IntegrityError               | Y        | Return 409 with message    | "Email already exists" | Y
ConnectionTimeoutError       | N <- GAP | --                         | 500 error <- BAD       | N
ValidationError              | Y        | Return 422 with details    | Field-level errors     | Y
TimeoutError                 | Y        | Retry 2x, then raise       | "Service unavailable"  | Y
RateLimitError               | Y        | Exponential backoff        | Transparent retry      | Y
JSONDecodeError              | N <- GAP | --                         | 500 error <- BAD       | N
ContentFilterError           | N <- GAP | --                         | 500 error <- BAD       | N
```

**Critical Gap Rule:** Any row with `RESCUED=N`, `TESTED=N`, and `USER SEES=500/Silent` is a **CRITICAL GAP** that must be resolved before the spec is approved. No spec passes Design Review with unresolved critical gaps.
