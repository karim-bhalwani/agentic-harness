---
name: prompt-library
description: Curated collection of high-quality prompts for software development and analysis. Includes role-based prompts, task-specific templates, analysis frameworks, and prompt patterns. Use when needing prompt templates for code review, debugging, testing, refactoring, or generating technical documentation.
version: "9.0"
dependencies: []
tags:
  - prompts
  - ai
  - development
  - templates
  - analysis
---

# Prompt Library

Curated, battle-tested prompts for common software development and analysis tasks.

## When to Use This Skill

Use when:

- Creating role-based prompts ("Act as X")
- Needing task-specific prompt templates
- Building prompts for code analysis or refactoring
- Generating prompts for testing or documentation
- Looking for prompt patterns and structures
- Improving prompt effectiveness and results

---

## Core Capabilities

1. **Role-Based Prompts** - Expert developer, code reviewer, architect, technical writer
2. **Task-Specific Prompts** - Debug, refactor, test, document, analyze
3. **Analysis Frameworks** - Complexity, performance, security analysis
4. **Creative & Transformation** - Brainstorming, naming, code migration, format conversion
5. **Prompt Engineering** - Patterns and best practices for effective prompting
6. **Specialized Prompts** - Domain-specific prompts for different roles

---

## Quick Prompt Lookup

### By Role

- **Expert Developer** - Code review and mentoring
- **Code Reviewer** - Structured code feedback
- **Technical Writer** - Documentation clarity
- **System Architect** - Design and scalability

### By Task

- **Debug This Code** - Root cause analysis
- **Explain Like I'm 5** - Simplified explanations
- **Code Refactoring** - Improving code quality
- **Write Tests** - Comprehensive test creation
- **API Documentation** - Endpoint specification

### By Analysis Type

- **Code Complexity** - Cyclomatic complexity and coupling
- **Performance Analysis** - Algorithmic and I/O bottlenecks
- **Security Review** - Vulnerability assessment
- **Brainstorm Features** - Feature ideation and prioritization

---

## Reference Guide

### [Prompt Library](prompt-library.md)

**Use when:** Looking for specific prompt templates

Complete prompts organized by:

- Role-based prompts (11+ templates)
- Task-specific prompts (8+ templates)
- Analysis prompts (3+ templates)
- Creative and transformation prompts

---

## How to Use These Prompts

### Effective Prompt Usage

1. **Select** the appropriate prompt template
2. **Customize** with your specific code/context
3. **Add context** if needed (language, framework, constraints)
4. **Specify format** if output format matters
5. **Iterate** - refine based on results

### Prompt Customization

```text
Base Template:
"Act as a code reviewer. Review this [LANGUAGE] code..."

Customized:
"Act as a code reviewer. Review this Python code for:
- Bug safety (using pytest)
- Performance (big-O analysis)
- Style (PEP 8 compliance)
- Security (OWASP top 10)

Format as table with severity."
```

## Prompt Engineering Best Practices

- ✅ **Be specific**: Vague prompts → vague results
- ✅ **Show examples**: Include input/output examples
- ✅ **Use roles**: "Act as X" increases consistency
- ✅ **Set constraints**: Specify what matters most
- ✅ **Request reasoning**: Ask to explain thinking
- ✅ **Include context**: Provide relevant background
- ✅ **Iterate**: Refine prompts based on results
- ✅ **Format output**: Specify desired format (JSON, table, etc.)

## Common Prompt Mistakes

| Mistake             | Fix                                      |
| :------------------ | :--------------------------------------- |
| Too vague           | Add specific details and constraints     |
| No format specified | Show desired output format/structure     |
| Too long            | Break into steps or focus on one aspect  |
| No role defined     | Use "Act as [role]" for consistency      |
| Missing context     | Include relevant code, frameworks, goals |
| No examples         | Show input/output example                |

---

## Advanced Prompting Techniques

### Prompt Chaining

Chain multiple prompts for complex tasks:

1. Analyze problem (analysis prompt)
2. Generate solutions (creative prompt)
3. Implement solution (coding prompt)
4. Test solution (testing prompt)
5. Document solution (documentation prompt)

### Few-Shot Prompting

Include examples in your prompt:

```text
Code Review Format:
❌ Issue 1: [Problem]
   → [Solution]

✅ Good: [What works well]

Show this format for my code:
[Your code here]
```

### System Prompts

Define behavior at the system level:

```text
You are a world-class software engineer.
You prioritize:
1. Code clarity over cleverness
2. Maintainability over performance micro-optimizations
3. User safety over feature completeness
```

---

## Prompt Organization

Prompts are organized by:

- **Context**: Role-based vs task-based
- **Complexity**: Simple vs multi-step
- **Domain**: Code, analysis, creative, transformation
- **Output format**: Structured vs narrative

Each prompt can be:

- Used as-is for common scenarios
- Customized for specific needs
- Combined with other prompts
- Iterated based on results

---

## Success Metrics for Prompts

Good prompts should:

- ✅ Produce consistent results
- ✅ Follow specified format
- ✅ Include reasoning/explanation
- ✅ Address all requested aspects
- ✅ Be useful without modification

If a prompt isn't working:

- Add more specific constraints
- Include examples
- Break into smaller steps
- Provide more context
- Try a different role perspective

---

## Dependencies

None - can be used independently


