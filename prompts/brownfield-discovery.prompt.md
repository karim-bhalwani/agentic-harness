---
agent: brownfield-discovery
description: Map an undocumented brownfield codebase into a tiered Project Bible. Uses the brownfield-discovery agent to produce confirmed, inferred, and unknown findings across architecture, dependencies, data flows, and conventions. Use when inheriting a new codebase, onboarding to an existing project, or before making any significant changes to unfamiliar code.
argument-hint: "[path, repo name, or area of codebase to map]"
tools:
  - read
  - search
  - agent
version: "7.0"
updated: "2026-04-12"
---

Use the `brownfield-discovery` agent to map this codebase: **${input:target}**

**Discovery scope** (cover all that apply):

- Entry points: main files, routers, CLI commands, event handlers
- Architecture: layers, module structure, design patterns in use
- Data flows: how data enters, transforms, and exits the system
- External dependencies: APIs, databases, queues, third-party services
- Configuration: environment variables, config files, feature flags
- Conventions: naming, error handling, logging, testing patterns
- Tech debt: workarounds, TODOs, deprecated patterns, inconsistencies

**Evidence tiers** (tag every finding):

- `[CONFIRMED]` - directly observed in code with file+line citation
- `[INFERRED]` - consistent pattern observed in 3+ places, cited
- `[UNKNOWN]` - gap that could not be determined from code alone

**Output format** (Project Bible):

1. **Project overview**: purpose, tech stack, entry points (2-3 sentences)
2. **Architecture map**: component diagram in Mermaid or structured list
3. **Data flows**: how the main workflows move through the system
4. **Conventions discovered**: naming, patterns, non-obvious rules `[CONFIRMED]`
5. **External dependencies**: each with purpose and integration point
6. **Tech debt inventory**: numbered list of issues with severity (High/Med/Low)
7. **Unknowns**: gaps that need human clarification before safe modification
8. **Recommended next steps**: what agents can now safely work on

Save the output to `.copilot/context/PROJECT_CONTEXT.md`. Hand off to `architect` for system design.

