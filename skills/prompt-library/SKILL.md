---
name: prompt-library
description: "Curated collection of high-quality prompts for various tasks - role-based templates, analysis frameworks, code review prompts, and brainstorming structures. Use when building prompts for specific roles, needing analysis or brainstorming frameworks, creating code review prompts, or searching for proven prompt patterns and structures. DO NOT USE FOR: LLM application architecture (use llm-app-patterns), actual code review execution (use guardian), deciding what features to build or exploring requirements (use brainstorming), or prompt injection defense (use security-boundaries). NOTE: This library supplies brainstorming-style prompt templates (e.g., 'Brainstorm Features') for use within a brainstorming session; it does not conduct the brainstorming itself."
argument-hint: "[prompt category or use case]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: []
---

# Prompt Library

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Curated collection of high-quality prompts for various use cases, organized by task type.

## Router

Load [references/prompt-templates.md](./references/prompt-templates.md) automatically whenever a user requests a specific prompt template. If the file cannot be loaded, inform the user and list the categories below.

### Role-Based

- **Expert Developer** - Code review and mentoring
- **Code Reviewer** - Structured code feedback (Critical / Suggestions / Praise)
- **Technical Writer** - Documentation clarity
- **System Architect** - Design with trade-off analysis

### Task-Specific

- **Debug This Code** - Problem ID, root cause, fix, prevention
- **Explain Like I'm 5 (ELI5)** - Simplified explanation with analogies
- **Code Refactoring** - Readability-first refactoring with before/after
- **Write Tests** - Happy path, edge cases, errors, boundaries
- **API Documentation** - Endpoint specification (OpenAPI/Markdown)

### Analysis

- **Code Complexity Analysis** - Cyclomatic, coupling, cohesion, debt
- **Performance Analysis** - Big-O, I/O bottlenecks, quick wins
- **Security Review** - Input validation, auth, injection, dependencies (Critical/High/Med/Low)

### Creative & Transformation

- **Brainstorm Features** - 10 ideas + impact/effort ranking
- **Name Generator** - Descriptive / Evocative / Acronyms / Metaphorical
- **Migrate Code** - Cross-language/framework migration
- **Convert Format** - Format-to-format conversion

If the requested category is not listed above, suggest the closest alternative or recommend `prompt-builder` to create a new one.

## Constraints

- Does NOT execute prompts or validate outputs (provides templates only)
- Does NOT replace domain expertise (prompts need subject matter context)
- Does NOT guarantee model behavior (outputs vary by model, temperature, and context)
- Does NOT store sensitive data in prompt templates

## Integration Points

- **prompt-builder**: Uses templates from this library as starting points for new prompts
- **ai-engineer**: Consumes prompt patterns for RAG and agent system prompts
- **brainstorming**: Supplies brainstorming-style prompt templates for use inside a brainstorming session
- **guardian**: Reviews prompts for security (injection resistance) and quality

## References

Load these when building or reviewing prompts:

- [prompt-templates.md](./references/prompt-templates.md) - Copy-ready prompt bodies for every category listed in the Prompt Catalog above (role-based, task-specific, analysis, creative). Load when you need the actual prompt text.
- [prompt-library.md](./references/prompt-library.md) - Curated prompt meta-catalog with prompt engineering best practices, customization guidance, and chaining patterns. Load for prompt design technique, not template bodies.
- [sample_prompt.md](./references/sample_prompt.md) - Worked example of a well-structured prompt with all required elements. Load when the user needs a concrete reference for prompt format, section order, and quality criteria.
