---
name: prompt-library
description: "Curated collection of high-quality prompts for various tasks - role-based templates, analysis frameworks, code review prompts, and brainstorming structures. Use when building prompts for specific roles, needing analysis or brainstorming frameworks, creating code review prompts, or searching for proven prompt patterns and structures. DO NOT USE FOR: LLM application architecture (use llm-app-patterns), actual code review execution (use guardian), brainstorming features (use brainstorming), or prompt injection defense (use security-boundaries)."
argument-hint: "[prompt category or use case]"
license: MIT
compatibility: "VS Code, Claude Code"
metadata:
  version: "7.0"
  updated: "2026-04-12"
  dependencies: []
---

# Prompt Library

> Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani |

Curated collection of high-quality prompts for various use cases, organized by task type.

## When to Use This Reference

Use when:

- Needing a role-based prompt template
- Building analysis or brainstorming prompts
- Creating prompts for code review or testing
- Looking for prompt patterns and structures

---

## Role-Based Prompts

### Expert Developer

```text
Act as an expert software developer with 15+ years of experience. You specialize in clean code, SOLID principles, and pragmatic architecture. When reviewing code:

1. Identify bugs and potential issues
2. Suggest performance improvements
3. Recommend better patterns
4. Explain your reasoning clearly

Always prioritize readability and maintainability over cleverness.
```

### Code Reviewer

```text
Act as a senior code reviewer. Your role is to:

1. Check for bugs, edge cases, and error handling
2. Evaluate code structure and organization
3. Assess naming conventions and readability
4. Identify potential security issues
5. Suggest improvements with specific examples

Format your review as:
🔴 Critical Issues (must fix)
🟡 Suggestions (should consider)
🟢 Praise (what's done well)
```

### Technical Writer

```text
Act as a technical documentation expert. Transform complex technical concepts into clear, accessible documentation. Follow these principles:

- Use simple language, avoid jargon
- Include practical examples
- Structure with clear headings
- Add code snippets where helpful
- Consider the reader's experience level
```

### System Architect

```text
Act as a senior system architect designing for scale. Consider:

- Scalability (horizontal and vertical)
- Reliability (fault tolerance, redundancy)
- Maintainability (modularity, clear boundaries)
- Performance (latency, throughput)
- Cost efficiency

Provide architecture decisions with trade-off analysis.
```

## Task-Specific Prompts

### Debug This Code

```text
Debug the following code. Your analysis should include:

1. **Problem Identification**: What exactly is failing?
2. **Root Cause**: Why is it failing?
3. **Fix**: Provide corrected code
4. **Prevention**: How to prevent similar bugs

Show your debugging thought process step by step.
```

### Explain Like I'm 5 (ELI5)

```text
Explain [CONCEPT] as if I'm 5 years old. Use:

- Simple everyday analogies
- No technical jargon
- Short sentences
- Relatable examples from daily life
- A fun, engaging tone
```

### Code Refactoring

```text
Refactor this code following these priorities:

1. Readability first
2. Remove duplication (DRY)
3. Single responsibility per function
4. Meaningful names
5. Add comments only where necessary

Show before/after with explanation of changes.
```

### Write Tests

```text
Write comprehensive tests for this code:

1. Happy path scenarios
2. Edge cases
3. Error conditions
4. Boundary values

Use [FRAMEWORK] testing conventions. Include:

- Descriptive test names
- Arrange-Act-Assert pattern
- Mocking where appropriate
```

### API Documentation

```text
Generate API documentation for this endpoint including:

- Endpoint URL and method
- Request parameters (path, query, body)
- Request/response examples
- Error codes and meanings
- Authentication requirements
- Rate limits if applicable

Format as OpenAPI/Swagger or Markdown.
```

## Analysis Prompts

### Code Complexity Analysis

```text
Analyze the complexity of this codebase:

1. **Cyclomatic Complexity**: Identify complex functions
2. **Coupling**: Find tightly coupled components
3. **Cohesion**: Assess module cohesion
4. **Dependencies**: Map critical dependencies
5. **Technical Debt**: Highlight areas needing refactoring

Rate each area and provide actionable recommendations.
```

### Performance Analysis

```text
Analyze this code for performance issues:

1. **Time Complexity**: Big O analysis
2. **Space Complexity**: Memory usage patterns
3. **I/O Bottlenecks**: Database, network, disk
4. **Algorithmic Issues**: Inefficient patterns
5. **Quick Wins**: Easy optimizations

Prioritize findings by impact.
```

### Security Review

```text
Perform a security review of this code:

1. **Input Validation**: Check all inputs
2. **Authentication/Authorization**: Access control
3. **Data Protection**: Sensitive data handling
4. **Injection Vulnerabilities**: SQL, XSS, etc.
5. **Dependencies**: Known vulnerabilities

Classify issues by severity (Critical/High/Medium/Low).
```

## Creative & Transformation Prompts

### Brainstorm Features

```text
Brainstorm features for [PRODUCT]:

For each feature, provide:
- Name and one-line description
- User value proposition
- Implementation complexity (Low/Med/High)
- Dependencies on other features

Generate 10 ideas, then rank top 3 by impact/effort ratio.
```

### Name Generator

```text
Generate names for [PROJECT/FEATURE]:

Provide 10 options in these categories:
- Descriptive (what it does)
- Evocative (how it feels)
- Acronyms (memorable abbreviations)
- Metaphorical (analogies)

For each, explain the reasoning.
```

### Migrate Code

```text
Migrate this code from [SOURCE] to [TARGET]:

1. Identify equivalent constructs
2. Handle incompatible features
3. Preserve functionality exactly
4. Follow target language idioms
5. Add necessary dependencies

Show the migration step by step with explanations.
```

### Convert Format

```text
Convert [INPUT_FORMAT] to [OUTPUT_FORMAT]:

1. Parse source format
2. Map equivalent structures
3. Handle format-specific features
4. Validate output correctness
5. Add necessary formatting

Show conversion examples.
```

## Definition of Done

- [ ] Prompt uses a clear role assignment ("Act as...")
- [ ] Output format is specified with example structure
- [ ] Constraints and success criteria are explicit
- [ ] Prompt tested with at least one real input and output reviewed
- [ ] Prompt is reusable (uses variables/placeholders, not hardcoded values)

## Best Practices

- ✅ **Be specific**: More specific prompts = better results
- ✅ **Show format**: Include example output structure
- ✅ **Use roles**: "Act as X" improves consistency
- ✅ **Set constraints**: Specify what matters most
- ✅ **Request reasoning**: Ask to explain thinking
- ✅ **Include context**: Share relevant background
- ✅ **Iterate**: Refine prompts based on results

## Constraints

- Does NOT execute prompts or validate outputs (provides templates only)
- Does NOT replace domain expertise (prompts need subject matter context)
- Does NOT guarantee model behavior (outputs vary by model, temperature, and context)
- Does NOT store sensitive data in prompt templates

## Common Pitfalls

- **Cargo-cult prompting**: Copying prompt patterns without understanding why they work
- **Ignoring context window**: Long prompts waste tokens; be concise and specific
- **Missing success criteria**: Every prompt should define what "good output" looks like
- **Over-constraining**: Too many rules make prompts brittle and hard to maintain
- **No iteration**: First-draft prompts rarely work well; plan for refinement cycles

## Integration Points

- **prompt-builder**: Uses templates from this library as starting points for new prompts
- **ai-engineer**: Consumes prompt patterns for RAG and agent system prompts
- **brainstorming**: Provides brainstorming frameworks and ideation prompts
- **guardian**: Reviews prompts for security (injection resistance) and quality

## References

Load these when building or reviewing prompts:

- [prompt-library.md](./references/prompt-library.md) - Curated prompt catalog organized by category (role-based, analysis, code review, brainstorming, data). Load when searching for a proven prompt pattern or when the user needs a starting template for a specific task type.
- [sample_prompt.md](./references/sample_prompt.md) - Worked example of a well-structured prompt with all required elements. Load when the user needs a concrete reference for prompt format, section order, and quality criteria.
