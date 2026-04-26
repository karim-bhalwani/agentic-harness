---
name: genai-security
description: "Security auditing for GenAI/LLM applications. Covers OWASP Top 10 for LLMs (2025), OWASP Top 10 for Agentic Applications (2026), MITRE ATLAS mapping, GenAI threat modeling, prompt injection defense, and AI red teaming. Use when reviewing LLM-powered applications, RAG pipelines, AI agents, prompt templates, or any system integrating generative AI. DO NOT USE FOR: general code security review without LLM components (use guardian), building LLM apps (use llm-app-patterns), runtime prompt injection rules (use security-boundaries), or infrastructure security."
argument-hint: "[LLM application to audit]"
license: MIT
compatibility: "VS Code, Claude Code"
metadata:
  version: "7.0"
  updated: "2026-04-12"
  dependencies: ["guardian", "llm-app-patterns"]
---

# GenAI Security Skill

> Version: 7.0 | Updated: 2026-04-12 | Architect: Karim Bhalwani | Tiered: core (~140 lines) + on-demand references

Specialized security reference for GenAI applications. Extends Guardian with AI-specific threat models sourced from [OWASP GenAI Security Project](https://genai.owasp.org/).

## Dependencies

- `skills/guardian/SKILL.md` - baseline code review and OWASP Top 10
- `skills/llm-app-patterns/SKILL.md` - production LLM architecture patterns

## When to Load

- Reviewing code that calls LLM APIs (Azure OpenAI, OpenAI, Anthropic, etc.)
- Auditing RAG pipelines, embedding workflows, or vector databases
- Reviewing AI agent implementations with tool use or autonomous actions
- Evaluating prompt templates and system prompts
- Conducting AI red teaming or adversarial testing

## OWASP Top 10 for LLMs (2025) - Quick Reference

| ID    | Risk                      | Key Mitigation                                         |
| ----- | ------------------------- | ------------------------------------------------------ |
| LLM01 | Prompt Injection          | Input/output filtering, privilege control, HITL        |
| LLM02 | Sensitive Info Disclosure | Output scanning, data sanitization, access controls    |
| LLM03 | Supply Chain              | Hash verification, AI BOM, dependency scanning         |
| LLM04 | Data/Model Poisoning      | Data provenance, DVC, anomaly detection                |
| LLM05 | Improper Output Handling  | Treat output as untrusted, schema validation           |
| LLM06 | Excessive Agency          | Least privilege tools, loop limits, HITL               |
| LLM07 | System Prompt Leakage     | No secrets in prompts, output monitoring               |
| LLM08 | Vector/Embedding Weakness | Document-level ACL, relevance thresholds               |
| LLM09 | Misinformation            | RAG with citations, human review for high-stakes       |
| LLM10 | Unbounded Consumption     | Token budgets, rate limits, timeouts, circuit breakers |

For full detection checklists, mitigations, and MITRE ATLAS mappings, load [owasp-llm-deep-dive.md](./references/owasp-llm-deep-dive.md).

## OWASP Top 10 for Agentic Applications (2026)

1. Excessive Agency & Privilege Escalation
2. Inadequate Tool Validation
3. Uncontrolled Agent Chaining
4. Insufficient Memory & Context Integrity
5. Broken Agent Authentication
6. Lack of Human Oversight
7. Unsafe Code Generation & Execution
8. Knowledge Poisoning
9. Agent Communication Manipulation
10. Unmonitored Agent Behavior

For full checklist, load [agentic-top-10-checklist.md](./references/agentic-top-10-checklist.md).

## Mandatory GenAI Security Review Checklist

### Prompt & I/O Security

- [ ] System prompts contain no secrets, keys, or sensitive architecture details
- [ ] Input validation pipeline exists (sanitization, length limits, content filtering)
- [ ] Output validation pipeline exists (encoding, schema validation, safety filtering)
- [ ] Anti-prompt-injection defenses tested with adversarial examples

### Data & Model Security

- [ ] Training/fine-tuning data has documented provenance
- [ ] Model integrity verified (hashes, signatures, trusted sources only)
- [ ] PII removed from training data and RAG corpus
- [ ] Vector database has document-level access controls

### Agent & Tool Security

- [ ] Tools have explicit authorization scopes and input validation
- [ ] Agent loop limits enforced (hard cap on iterations)
- [ ] Human-in-the-loop required for destructive or irreversible actions
- [ ] All tool invocations logged with full audit trail
- [ ] Memory files treated as **untrusted input** — stored memory is read back into context and is a prompt injection vector (memory poisoning); never trust stored content as instructions
- [ ] Memory content sanitized before storage: filter injected directives, strip executable patterns, enforce max file size
- [ ] Memory scoped per-user and per-project to prevent cross-contamination between tenants or tasks
- [ ] Memory operations audited: all reads/writes logged with timestamps and source tracing

### Operational Security

- [ ] Token budgets and rate limits enforced per-request and per-user
- [ ] LLM API calls have timeouts and circuit breakers
- [ ] Cost monitoring with anomaly alerting in place
- [ ] Structured logging with trace IDs for all LLM interactions

## GenAI Security Report Structure

```markdown
## GenAI Security Review Report

### Summary

[Overall GenAI risk assessment]

### OWASP LLM Top 10 Compliance

| Risk ID | Risk | Status | Notes |

### Agentic Security (if applicable)

| Risk ID | Risk | Status | Notes |

### Findings

| # | Severity | OWASP Risk | Component | Finding | Remediation |

### Red Teaming Results (if performed)

### Gate Status: [PASS | FAIL | NEEDS WORK]
```

## Definition of Done

- [ ] GenAI Security Review Report produced following structure above
- [ ] All 10 LLM risks assessed (Pass/Fail/N/A with evidence)
- [ ] Agentic risks assessed if agents or tools are present
- [ ] Critical findings have specific remediation steps
- [ ] Gate status explicitly stated

## Constraints

- Does NOT fix code or implement remediations (produces findings only)
- Does NOT design system architecture (consult architect)
- Does NOT replace formal penetration testing or compliance audits

## References

Load on demand for specific sub-tasks:

- [owasp-llm-deep-dive.md](./references/owasp-llm-deep-dive.md) - Full OWASP LLM Top 10 detection checklists, mitigations, MITRE ATLAS mappings, and GenAI threat modeling STRIDE table. **Load for comprehensive audits.**
- [llm-top-10-checklist.md](./references/llm-top-10-checklist.md) - Structured per-risk checklist.
- [agentic-top-10-checklist.md](./references/agentic-top-10-checklist.md) - Agent-specific security controls.
- [prompt-injection-patterns.md](./references/prompt-injection-patterns.md) - Attack and defense patterns.
- [red-teaming-guide.md](./references/red-teaming-guide.md) - AI adversarial testing methodology.
