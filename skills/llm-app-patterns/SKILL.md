---
name: llm-app-patterns
description: "Production LLM application patterns, architectures, and best practices. Covers RAG pipelines, agent architectures, prompt engineering, LLMOps, and production deployment patterns. DO NOT USE FOR: LLM security auditing (use genai-security), general data pipelines without LLM components (use data-engineering), prompt template libraries (use prompt-library), or wiki knowledge management (use llm-mem)."
argument-hint: "[LLM pattern to apply]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: ["architect", "data-engineering", "ops"]
---

# LLM Application Patterns

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani | Deps: architect, data-engineering, ops

## Dependencies

Load the following via `read_file` before using this skill:

- `skills/architect/SKILL.md` - module boundary and API contract patterns; LLM app components (retriever, generator, evaluator) are black-box modules
- `skills/data-engineering/SKILL.md` - ingestion and pipeline patterns for corpus preparation, embedding pipelines, and index refresh
- `skills/ops/SKILL.md` - CI/CD and deployment patterns for LLMOps pipelines, model versioning, and evaluation automation

Expert in production LLM application patterns and architectures.

## When to Use This Skill

Use when:

- Building production RAG (Retrieval-Augmented Generation) pipelines
- Implementing AI agents with tool use and multi-step reasoning
- Designing prompt engineering strategies and template systems
- Setting up LLMOps: monitoring, logging, tracing, and evaluation
- Deploying LLM applications with caching, rate limiting, and fallbacks
- Choosing between different agent architectures (ReAct, function calling, plan-execute, multi-agent)
- Optimizing retrieval: chunking strategies, vector databases, hybrid search
- Building production-ready systems: cost optimization, reliability, observability

---

## Core Capabilities

This skill provides production-proven patterns for:

1. **RAG Pipelines** - Document ingestion, chunking, embedding, retrieval, generation
2. **Agent Architectures** - ReAct, function calling, plan-execute, multi-agent collaboration
3. **Prompt Engineering** - Templates, versioning, A/B testing, chaining
4. **LLMOps & Monitoring** - Metrics, logging, tracing, evaluation frameworks
5. **Production Patterns** - Caching, rate limiting, retry logic, fallbacks

---

## Pattern References

For detailed implementation guidance, see:

### [RAG Pipelines](references/rag-pipelines.md)

**Use when:** Building search-augmented LLM applications

Covers:

- Document ingestion and preprocessing
- Chunking strategies (fixed, semantic, sliding window)
- Vector database selection and configuration
- Retrieval patterns (dense, sparse, hybrid, multi-vector)
- Generation with retrieved context

### [Agent Architectures](references/agent-architectures.md)

**Use when:** Building agents that use tools or multi-step reasoning

Covers:

- ReAct pattern (Reasoning + Acting)
- Function calling for structured tool use
- Plan-and-execute for complex tasks
- Multi-agent collaboration patterns
- Architecture decision matrix

### [Prompt Engineering](references/prompt-engineering.md)

**Use when:** Creating reusable prompt systems

Covers:

- Prompt templates with variables
- Versioning and A/B testing
- Prompt chaining for multi-step workflows
- Few-shot learning patterns
- Best practices for prompt structure

### [LLMOps & Observability](references/llmops-observability.md)

**Use when:** Setting up monitoring and evaluation

Covers:

- Key metrics to track (performance, quality, cost, reliability)
- Logging and distributed tracing
- Evaluation frameworks and benchmarking
- Caching strategies for cost reduction
- Rate limiting and retry patterns
- Fallback strategies for reliability

---

## Quick Decision Guide

| Goal                            | Reference                                                    |
| :------------------------------ | :----------------------------------------------------------- |
| Answer questions from your docs | [RAG Pipelines](references/rag-pipelines.md)                 |
| Build tool-using agent          | [Agent Architectures](references/agent-architectures.md)     |
| Create reusable prompts         | [Prompt Engineering](references/prompt-engineering.md)       |
| Monitor production system       | [LLMOps & Observability](references/llmops-observability.md) |

---

## Definition of Done

- [ ] Selected pattern has clear justification (RAG vs. agent vs. fine-tune decision documented)
- [ ] Observability configured: latency, token usage, and error rate metrics defined
- [ ] Fallback strategy exists for LLM provider failures
- [ ] Prompt templates are versioned and stored outside application code
- [ ] Cost estimate provided for expected query volume

## Constraints

- Does NOT implement patterns (provides architecture guidance and templates only)
- Does NOT evaluate model quality or fine-tuning strategies
- Does NOT manage infrastructure (consult ops skill)
- Does NOT handle non-LLM ML patterns (classical ML, computer vision, etc.)

## Common Pitfalls

- **Over-engineering RAG**: Start with naive RAG before adding reranking, hybrid search, or agentic retrieval
- **Ignoring cost**: LLM API costs scale with query volume; always estimate and set budgets
- **Missing fallbacks**: Every LLM call needs a fallback strategy (retry, cheaper model, cached response)
- **Prompt drift**: Unversioned prompts silently degrade; version-control all prompt templates
- **Evaluation gaps**: Deploy without eval framework = flying blind. Measure before and after every change

## Integration Points

- **architect**: Defines overall system architecture into which LLM patterns fit
- **data-engineering**: Manages data pipelines feeding RAG knowledge bases
- **genai-security**: Audits LLM applications for security vulnerabilities
- **ai-engineer**: Implements the patterns defined by this skill
- **ops**: Deploys and monitors LLM applications in production

## References

Load these to apply the correct pattern for the task at hand:

- [rag-pipelines.md](./references/rag-pipelines.md) - RAG architecture patterns (naive, advanced, agentic). Load when designing or reviewing any retrieval-augmented generation system.
- [agent-architectures.md](./references/agent-architectures.md) - LLM agent topology patterns (ReAct, Plan-and-Execute, multi-agent). Load when designing autonomous agent systems or tool-use workflows.
- [prompt-engineering.md](./references/prompt-engineering.md) - Prompt design patterns (few-shot, chain-of-thought, structured output). Load when writing or reviewing system prompts or task prompts.
- [llmops-observability.md](./references/llmops-observability.md) - LLMOps monitoring and evaluation patterns. Load when setting up eval frameworks, tracing, or production observability for LLM applications.
- [pattern_summary.md](./references/pattern_summary.md) - One-page pattern decision guide. Load first when unsure which pattern applies - use to select the right reference file before diving deeper.
