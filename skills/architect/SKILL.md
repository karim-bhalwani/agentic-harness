---
name: architect
description: "Produce the formal SPEC.md after brainstorming has aligned intent. Defines module boundaries, API contracts, data models, and replaceability constraints. Output is a specification artifact at .copilot/specs/SPEC.md. Triggers: new feature, major refactor, database schema or API contract definition, system risk isolation. Reached by: brainstorming (handoff), concise-planning (upstream dependency)."
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

> **Brainstorming gate**: If no brainstorming artifact or documented intent alignment is provided by the user, pause and respond: "This skill requires a completed brainstorming session. Please run the brainstorming skill first and share the output before proceeding." Do not begin scope determination or spec authoring.

## Dependencies

Load the following via `read_file` before using this skill. Skills marked ★ have `disable-model-invocation: true` and cannot self-invoke - they **must** be loaded explicitly.

- `~/.copilot/skills/thinker/SKILL.md` ★ - structured reasoning scaffold (UNDERSTAND → EXTRACT → HIGHLIGHT → APPLY)
- `~/.copilot/skills/brainstorming/SKILL.md` - requirement exploration and idea-to-design dialogue
- `~/.copilot/skills/holdout-validation/SKILL.md` - load when writing acceptance scenarios that will become holdout test criteria (ensures scenario format compatibility)

## Overview

The Architect skill focuses on the "What" and "Where" of a system, rather than the "How." It is used to design robust, scalable, and maintainable software architectures using black-box principles.

## Core Principles

1. **Black Box Interfaces**: Modules are defined by what they do, hiding how they do it.
2. **Replaceable Components**: Design modules so they can be rewritten from scratch using only their interface.
3. **Single Responsibility**: One module = one clear purpose.
4. **Primitive-First Design**: Identify core data types (primitives) and design the system around their flow.
5. **Human-Centric**: Optimize designs for cognitive load - one developer should be able to understand any single module.

## Workflow

0. **Scope Challenge**: Determine scope mode (REDUCTION / HOLD / EXPANSION) before any design work. If REDUCTION: stop here - no spec is produced; apply the fix, review, and conclude. If HOLD: produce sections 1, 3, 4, and 5 only (see per-mode checklist below). If EXPANSION: run the full workflow including Scope Expansion Exercises.
1. **Understand**: Analyze requirements and identify core business logic primitives.
2. **Define Boundaries**: Determine where modules start and end.
3. **Design Contracts**: Define API endpoints, data models, and interface protocols.
4. **Map Dependencies**: Ensure no circular dependencies exist (Dry-run Dependency Map).
5. **Output Specification**: Produce a `SPEC.md` that serves as the source of truth for implementation.
6. **Save Specification**: Save the completed `SPEC.md` to `.copilot/specs/SPEC.md` so downstream agents (Guardian, Developer) can locate it outside the conversation context.

### Scope Modes

| Mode          | When                                                | Design Depth                                                                                                                  |
| ------------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **REDUCTION** | Bug fix, config change, dead code removal           | No spec. Fix, review, done.                                                                                                   |
| **HOLD**      | Feature within existing architecture                | Sections 1, 3, 4, and 5 only. Omit sections 2, 6–13 unless the feature introduces a new module boundary or data model change. |
| **EXPANSION** | New module/service/data model, architectural change | Full spec with Scope Expansion Exercises                                                                                      |

### Per-Mode Checklists

**REDUCTION** - Bug fix, config change, dead code removal. No spec is produced.

- [ ] Identify the defect or change target
- [ ] Apply the fix (code, config, or removal)
- [ ] Review the change for correctness and side effects
- [ ] Done - do not advance to concise-planning or create a SPEC.md

**HOLD** - Feature within existing architecture. Partial spec only.

- [ ] Section 1: System Overview (goal, scope, out-of-scope)
- [ ] Section 3: API Contracts (only for interfaces that change)
- [ ] Section 4: Data Models (only for models that change)
- [ ] Section 5: Error Handling (updated rescue map for changed codepaths)
- [ ] Omit sections 2, 6–13 unless a new module boundary or data model is introduced
- [ ] Save spec to `.copilot/specs/SPEC.md` with `scope_mode: HOLD`
- [ ] Advance to concise-planning

**EXPANSION** - New module, service, data model, or architectural change. Full spec required.

- [ ] Complete all thirteen sections (see Mandatory Output below)
- [ ] Run Scope Expansion Exercises before module design
- [ ] Create holdout file at `.copilot/holdout/HOLDOUT-<feature-name>.md`
- [ ] Save spec to `.copilot/specs/SPEC.md` with `scope_mode: EXPANSION`
- [ ] Advance to concise-planning only after spec is reviewed and approved

### Scope Expansion Exercises (EXPANSION mode only)

Before module design, answer these product-lens questions to surface assumptions:

1. **10x Check**: If this needed 10x load/users/data, would we design it the same? What breaks?
2. **Platonic Ideal**: What does the perfect version look like? What compromises are we making and why?
3. **Do-Nothing Test**: What happens if we don't build this? What is the cost of inaction?
4. **Dream State Mapping**: Describe the ideal user experience. Work backwards to system design.

Document answers in the spec under a **Scope Analysis** section (before Module Boundaries).

## Mandatory Output: `SPEC.md` Template

Load the template that matches your scope mode (determined in Step 0):

- **REDUCTION**: no spec produced. Fix, review, done.
- **HOLD**: load [references/spec-hold-template.md](references/spec-hold-template.md) - frontmatter + sections 1, 3, 4, 5 only. Omit sections 2, 6–13 unless the feature introduces a new module boundary or data model change.
- **EXPANSION**: load [references/spec-template.md](references/spec-template.md) - frontmatter + all 13 sections, including the Error & Rescue Map. Run Scope Expansion Exercises first.

For a worked example spec, see [references/SPEC.md](references/SPEC.md).

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
- [ ] Spec reviewed and accepted by implementer or stakeholder before implementation begins (implementer reviews `SPEC.md` only; the holdout file referenced in Section 13 must not be opened or read by the implementer)

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

### Scripts

- [scaffold_spec.py](./scripts/scaffold_spec.py) - Specification document scaffolder (programmatic). Run to generate a pre-structured `SPEC.md` with all required sections and `TODO` markers for a named module. Use when you want a richer programmatic template.
- [scaffold_artifacts.py](./scripts/scaffold_artifacts.py) - On-disk artifact scaffolder. Creates `.copilot/specs/SPEC.md` and `.copilot/holdout/HOLDOUT.md` as stubs. Run at the start of Phase 4 to guarantee both artifact files exist before being filled. Mirrors the brownfield/greenfield Bible scaffold pattern.
- [verify_spec.py](./scripts/verify_spec.py) - Verification gate. Run before handing off to implementation; exits 1 if `SPEC.md` or `HOLDOUT.md` is still a stub or missing.
