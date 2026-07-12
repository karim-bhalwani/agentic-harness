# SPEC.md Template - HOLD Mode (Feature Within Existing Architecture)

> Lightweight template for the Architect skill's HOLD mode output. Loaded by reference from `~/.copilot/skills/architect/SKILL.md` when scope_mode is HOLD.
>
> For EXPANSION mode (new module/service/data model), use [spec-template.md](./spec-template.md) instead.

This template populates only the sections that change when adding a feature within an existing architecture. Sections 2, 6–13 are omitted unless the feature introduces a new module boundary or data model change.

## Mandatory Frontmatter

Every `SPEC.md` **MUST** begin with a YAML frontmatter block:

```yaml
---
spec_schema_version: 1 # see tests/contracts/schema_versions.py
version: "0.1"
status: "Draft" # Draft | In Review | Approved | Blocked | Deprecated
date: "<YYYY-MM-DD>"
owner: "<lead architect>"
scope_mode: "HOLD" # REDUCTION | HOLD | EXPANSION
---
```

## Sections to Populate (HOLD Mode)

### 1. System Overview

- **Goal**: What this feature accomplishes and why.
- **Scope**: What is in scope for this change.
- **Out of Scope**: What is explicitly not changing (architecture, other modules, deployment topology).
- **Business Primitives**: Core data types or entities affected (if any).

### 3. API Contracts (only for interfaces that change)

- Method, path, payload, and response for every modified interface (RFC 7807 for errors).
- Only document interfaces that are new or changing. Reference existing specs for unchanged interfaces.

### 4. Data Models (only for models that change)

- New or modified table/object schemas with field types, nullability, validation rules, and index strategy.
- If no data models change, state "No data model changes" and omit this section.

### 5. Error Handling

- New error modes introduced by this feature.
- Updated rescue map for changed codepaths only.
- Reference the existing Error & Rescue Map for unchanged error paths.

## Sections to Omit (HOLD Mode)

The following sections are **not required** for HOLD mode unless the feature introduces a new module boundary or data model change:

- ~~2. Module Boundaries~~ (unchanged architecture)
- ~~6. Security Considerations~~ (unless new auth boundaries)
- ~~7. Performance Requirements~~ (unless new bottlenecks)
- ~~8. Testing Strategy~~ (unless new test infrastructure)
- ~~9. Deployment Considerations~~ (unless new deployment topology)
- ~~10. Open Questions~~ (only if unresolved decisions exist)
- ~~11. Risks~~ (only if new risks are introduced)
- ~~12. Deferred Decisions~~ (only if decisions are postponed)
- ~~13. Acceptance Scenarios~~ (only if holdout scenarios are needed)

If any of the above become relevant, populate them using the full [spec-template.md](./spec-template.md) as a reference.
