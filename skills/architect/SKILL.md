---
name: architect
description: "PIPELINE POSITION: specify (step 2 of 4: brainstorming → architect → concise-planning → implementer). Produce the formal SPEC.md after brainstorming has aligned intent. Defines module boundaries, API contracts, data models, and replaceability constraints. Output is a specification artifact at .copilot/specs/SPEC.md. DO NOT USE FOR: unstructured requirement exploration (use brainstorming FIRST for alignment), atomic task checklists for an already-approved design (use concise-planning), writing implementation code (use implementer), code review or security audit (use guardian), debugging errors (use systematic-debugging), or CI/CD pipeline design (use ops). NOTE: Scope determination (REDUCTION/HOLD/EXPANSION) is part of the Architect role and comes first."
argument-hint: "[system component to design]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: ["brainstorming", "thinker"]
---

# Architect Skill - System Design & Specification

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani | Deps: brainstorming, thinker

> **Pipeline position**: **specify** (2 of 4) - `brainstorming` -> **`architect`** -> `concise-planning` -> `implementer`. This skill produces `.copilot/specs/SPEC.md`. It runs AFTER `brainstorming` has aligned intent and BEFORE `concise-planning` sequences execution.

## Dependencies

Load the following via `read_file` before using this skill. Skills marked ★ have `disable-model-invocation: true` and cannot self-invoke - they **must** be loaded explicitly.

- `skills/thinker/SKILL.md` ★ - structured reasoning scaffold (UNDERSTAND → EXTRACT → HIGHLIGHT → APPLY)
- `skills/brainstorming/SKILL.md` - requirement exploration and idea-to-design dialogue

## Overview

The Architect skill focuses on the "What" and "Where" of a system, rather than the "How." It is used to design robust, scalable, and maintainable software architectures using black-box principles.

## Core Principles

1. **Black Box Interfaces**: Modules are defined by what they do, hiding how they do it.
2. **Replaceable Components**: Design modules so they can be rewritten from scratch using only their interface.
3. **Single Responsibility**: One module = one clear purpose.
4. **Primitive-First Design**: Identify core data types (primitives) and design the system around their flow.
5. **Human-Centric**: Optimize designs for cognitive load - one developer should be able to understand any single module.

## Workflow

0. **Scope Challenge**: Determine scope mode (REDUCTION / HOLD / EXPANSION) before any design work. REDUCTION skips the spec process. HOLD uses a lightweight spec. EXPANSION runs the full workflow including Scope Expansion Exercises.
1. **Understand**: Analyze requirements and identify core business logic primitives.
2. **Define Boundaries**: Determine where modules start and end.
3. **Design Contracts**: Define API endpoints, data models, and interface protocols.
4. **Map Dependencies**: Ensure no circular dependencies exist (Dry-run Dependency Map).
5. **Output Specification**: Produce a `SPEC.md` that serves as the source of truth for implementation.
6. **Save Specification**: Save the completed `SPEC.md` to `.copilot/specs/SPEC.md` so downstream agents (Guardian, Developer) can locate it outside the conversation context.

### Scope Modes

| Mode          | When                                                | Design Depth                                                 |
| ------------- | --------------------------------------------------- | ------------------------------------------------------------ |
| **REDUCTION** | Bug fix, config change, dead code removal           | No spec. Fix, review, done.                                  |
| **HOLD**      | Feature within existing architecture                | Lightweight spec, skip module design if boundaries unchanged |
| **EXPANSION** | New module/service/data model, architectural change | Full spec with Scope Expansion Exercises                     |

### Scope Expansion Exercises (EXPANSION mode only)

Before module design, answer these product-lens questions to surface assumptions:

1. **10x Check**: If this needed 10x load/users/data, would we design it the same? What breaks?
2. **Platonic Ideal**: What does the perfect version look like? What compromises are we making and why?
3. **Do-Nothing Test**: What happens if we don't build this? What is the cost of inaction?
4. **Dream State Mapping**: Describe the ideal user experience. Work backwards to system design.

Document answers in the spec under a **Scope Analysis** section (before Module Boundaries).

## Mandatory Output: `SPEC.md` Template

Every architectural design must produce or update a specification following this structure. **All thirteen sections are required** - a specification that omits any section leaves room for interpretation and is not considered complete.

### Mandatory Frontmatter (Schema Version Contract)

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

### Core Sections (1–4): System Design & Structure

1. **System Overview**: High-level goal, scope boundaries, identified business primitives, and the problem being solved. What is explicitly out of scope.
2. **Module Boundaries**: Proposed directory and file layout; responsible module per concern; one-sentence description test for every module; Mermaid component diagram showing component flow.
3. **API Contracts**: Method, path, payload, and response for every interface (RFC 7807 for errors). Includes event schemas for async interfaces. Input/output types and validation rules must be fully specified.
4. **Data Models**: Table/object schemas with field types, nullability, validation rules, and index strategy. Includes read schema and write schema separately where they differ.

### Operational Sections (5–9): Quality, Safety & Deployment

5. **Error Handling**: Error taxonomy (categories and codes); which errors are recoverable vs fatal; retry strategy per category; logging and alerting obligations per severity. Must include an **Error & Rescue Map** (see below).
6. **Security Considerations**: Authentication and authorization model; trust boundaries between modules; data sensitivity classification; secrets management approach; input validation requirements; known threat surface (STRIDE analysis for security-critical features).
7. **Performance Requirements**: Latency targets (p50/p95/p99); throughput requirements; known bottlenecks and mitigation strategy; caching policy; resource constraints (memory, CPU, I/O).
8. **Testing Strategy**: Unit test scope and coverage target; integration test boundaries; E2E scenarios for critical user workflows; determinism requirements (mocking time, network, randomness); CI tier per test type.
9. **Deployment Considerations**: Target environment; configuration and environment variables; migration plan for schema changes; rollback procedure; observability hooks (logging, tracing, alerting).

### Decision Sections (10–13): Unknowns, Risks & Acceptance

10. **Open Questions**: Decisions that are unresolved at spec time, each with an owner and resolution deadline. These must be resolved before implementation begins.
11. **Risks**: Identified design risks with likelihood, impact, and mitigation strategy. Includes architectural assumptions that, if wrong, would require significant rework.
12. **Deferred Decisions**: Design choices deliberately postponed with documented rationale, acceptance criteria for when they must be revisited, and who owns the revisit.
13. **Acceptance Scenarios**: Reference to the holdout file (`.copilot/holdout/HOLDOUT-<feature-name>.md`). Three to ten intent-level behavioral scenarios authored by the Architect, stored in the holdout directory. Scenarios are NOT included inline - they are referenced only. Implementation agents must not read the holdout file.

### Error & Rescue Map (Required in Section 5)

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

## When to Use

- Starting a new feature.
- Major system refactors.
- Defining database schemas or API contracts.
- Identifying and isolating system risks.

## Outputs & Deliverables

- **Primary Output**: `SPEC.md` - Complete technical specification document
- **Success Criteria**: All stakeholders approve the specification before implementation begins
- **Quality Gate**: Specification passes review by implementer and guardian skills

## Standards & Best Practices

### Boring Technology Bias

- **Prefer stable, well-established technologies** over novel or bleeding-edge alternatives. Technologies described as "boring" (mature APIs, broad community support, extensive documentation) are easier for agents to reason about because they are well-represented in LLM training data.
- **Composability and API stability** matter more than feature novelty. A dependency the agent can fully internalize and reason about in-repo is worth more than a flashy library with sparse docs.
- **When in doubt, reimplement small utilities** rather than pulling in opaque upstream packages. A tightly integrated helper with full test coverage and predictable behavior beats a generic third-party package the agent cannot inspect or reason about.
- This is not anti-innovation - it is risk-aware. Novel dependencies increase the surface area where agents guess instead of reason.

### Black Box Design

- Define modules by their contracts, not implementations
- Ensure each module has a single, clear responsibility
- Design for replaceability - any module should be rewritable from its interface

### Data Flow Architecture

- Identify core business primitives early
- Map data transformations through the system
- Ensure no circular dependencies in the dependency graph

## Definition of Done

### Required Sections (All 13 Must Be Present)

**System Design & Structure**

- [ ] 1. System Overview: goal, scope, business primitives, out-of-scope boundaries
- [ ] 2. Module Boundaries: directory layout, one-sentence test, Mermaid diagram
- [ ] 3. API Contracts: method, path, payload, response, error codes (RFC 7807)
- [ ] 4. Data Models: schemas with field types, nullability, validation, indexes

**Quality, Safety & Deployment**

- [ ] 5. Error Handling: taxonomy, rescue map, retry strategy, logging obligations
- [ ] 6. Security Considerations: auth, trust boundaries, threat surface (STRIDE)
- [ ] 7. Performance Requirements: latency targets (p50/p95/p99), bottlenecks
- [ ] 8. Testing Strategy: coverage target, integration boundaries, CI tier
- [ ] 9. Deployment Considerations: environment, config, migration, rollback

**Decision & Risk Management**

- [ ] 10. Open Questions: unresolved decisions with owner and deadline
- [ ] 11. Risks: likelihood, impact, and mitigation per risk
- [ ] 12. Deferred Decisions: rationale, revisit criteria, owner
- [ ] 13. Acceptance Scenarios: reference to `.copilot/holdout/HOLDOUT-<feature-name>.md` (not inline)

### Design Quality Gates

**Architecture & Dependencies**

- [ ] Dependency graph verified acyclic (no circular dependencies)
- [ ] Replaceability confirmed: modules can be reimplemented from interface alone
- [ ] Every module passes "one-sentence description" test

**Specification Completeness**

- [ ] Error & Rescue Map complete (every codepath → failure mode → rescue action)
- [ ] No critical gaps in Error & Rescue Map (rows with RESCUED=N must be resolved)
- [ ] All API interfaces include RFC 7807 error response format
- [ ] Data models specify read schema and write schema separately where they differ

### Artifact & Approval

- [ ] Specification saved to `.copilot/specs/SPEC.md` for downstream agent access
- [ ] Holdout file created at `.copilot/holdout/HOLDOUT-<feature-name>.md`
- [ ] `spec_schema_version` declared in SPEC frontmatter and present in `tests/contracts/schema_versions.SUPPORTED_SCHEMA_VERSIONS`
- [ ] `holdout_schema_version` declared in HOLDOUT frontmatter
- [ ] Spec reviewed and accepted by implementer or stakeholder before implementation begins

## Constraints

- **NO implementation code.** Snippets for interfaces or data models only.
- **NO testing logic.**
- **NO deployment configs.**

## Common Pitfalls

- **Over-Engineering**: Designing for every possible future scenario. Start with the simplest design that solves today's problem; refactor when needs emerge.
- **God Modules**: Creating one massive module instead of breaking concerns. Single Responsibility is non-negotiable.
- **Circular Dependencies**: Not catching these during design leads to unmaintainable code. Always verify the dependency graph is acyclic.
- **Unclear Module Boundaries**: When developers can't explain what a module does in one sentence, the boundary is fuzzy. Refactor immediately.
- **Missing API Contracts**: Vague interfaces lead to integration errors downstream. Always document input/output types, validation rules, and error responses.
- **Ignoring Primitive Selection**: Choosing the wrong core data types cascades through the entire design. Validate primitives early.

## Integration Points

| Phase          | Input From                 | Output To                         | Context                                     |
| -------------- | -------------------------- | --------------------------------- | ------------------------------------------- |
| Discovery      | `brainstorming`, `thinker` | This spec                         | Understand requirements and constraints     |
| Specification  | Core business logic        | `implementer`, `data-engineering` | Implement according to spec                 |
| Validation     | N/A                        | `guardian`                        | Review for security and patterns            |
| Operations     | Deployment requirements    | `ops`                             | Infrastructure needs based on architecture  |
| Query/Analysis | Data model from spec       | `data-analyst`                    | Query database based on approved data model |

## References

Load these when generating specifications and API contracts:

### Reference Documents

- [SPEC.md](./references/SPEC.md) - System specification template. Load at the start of every architecture task to ensure all required sections (primitives, contracts, boundaries, data flows) are covered.
- [api-specification.md](./references/api-specification.md) - API contract template with OpenAPI-style schemas. Load when designing REST, gRPC, or event-driven interfaces.
- [sprint-contract-template.md](./references/sprint-contract-template.md) - Builder/Guardian sprint-contract negotiation template. Load when running `/sprint-contract` to surface ambiguity between the spec and the implementation plan before coding starts.
- [sprint-contract-template.md](./references/sprint-contract-template.md) - Builder/Guardian sprint-contract negotiation template. Load when running `/sprint-contract` to surface ambiguity between the spec and the implementation plan before coding starts.

### Scripts

- [scaffold_spec.py](./scripts/scaffold_spec.py) - Specification document scaffolder (programmatic). Run to generate a pre-structured `SPEC.md` with all required sections and `TODO` markers for a named module. Use when you want a richer programmatic template.
- [scaffold_artifacts.py](./scripts/scaffold_artifacts.py) - On-disk artifact scaffolder. Creates `.copilot/specs/SPEC.md` and `.copilot/holdout/HOLDOUT.md` as stubs. Run at the start of Phase 4 to guarantee both artifact files exist before being filled. Mirrors the brownfield/greenfield Bible scaffold pattern.
- [verify_spec.py](./scripts/verify_spec.py) - Verification gate. Run before handing off to implementation; exits 1 if `SPEC.md` or `HOLDOUT.md` is still a stub or missing.
