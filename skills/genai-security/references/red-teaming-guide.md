# GenAI Red Teaming Guide - Condensed Reference

**Source:** [OWASP GenAI Red Teaming Guide v1.0.2](https://genai.owasp.org/resource/genai-red-teaming-guide/) (January 2025, 77 pages)
**Purpose:** Distilled operational reference for planning and executing GenAI red team exercises.

---

## What is GenAI Red Teaming?

Structured methodology combining human expertise with automation and AI tools to uncover safety, security, trust, and performance gaps in systems incorporating Generative AI. It extends traditional red teaming with AI-specific concerns: prompt injection, model extraction, output manipulation, toxicity, bias, hallucinations, and agentic vulnerabilities.

---

## Four-Phase Blueprint

### Phase 1: Model Evaluation

Test the model's inherent weaknesses in isolation.

| Category | Key Tasks |
|----------|-----------|
| Inference Attacks | Model parameter inference, architecture probing, training data inference, backend fingerprinting |
| Extraction Attacks | Knowledge base extraction, training data recovery, weight/parameter extraction, system prompt recovery |
| Instruction Tuning | Instruction retention manipulation, fine-tuning boundary probing, instruction override, priority manipulation |
| Socio-Technical Harm | Demographic bias patterns, hate speech generation, toxicity, stereotype propagation, extremist content |
| Data Risk | PII/sensitive data recovery, training data reconstruction, copyright violations, data access patterns |
| Alignment Testing | Jailbreak effectiveness, prompt injection methods, safety layer bypasses, ethical boundary conditions |
| Adversarial Robustness | Novel attack patterns, edge case behaviors, failure modes, attack chain combinations |
| Technical Harm Vectors | Code generation boundaries, exploit generation potential, attack script creation, vulnerability discovery |

### Phase 2: Implementation Evaluation

Test bypassing guardrails, poisoning RAG data, and testing control effectiveness.

| Category | Key Tasks |
|----------|-----------|
| Prompt Safety Controls | Direct jailbreak techniques, context manipulation, multi-message attack chains, role-play bypasses |
| Knowledge Retrieval Security | Vector database poisoning, embedding manipulation, semantic search pollution, cache poisoning |
| Architecture Controls | Model isolation boundary bypasses, proxy/firewall evasion, token limit bypasses, rate limiting evaluation |
| Content Filtering Bypass | Content policy enforcement, filter evasion, multi-language filter consistency, filter chain manipulation |
| Access Control | Authentication boundaries, authorization level bypasses, session management, privilege escalation |
| Agent/Tool/Plugin Security | Tool access control boundaries, plugin sandbox evaluation, agent behavior control, multi-tool chains |

### Phase 3: System Evaluation

Evaluate infrastructure, integration security, and supply chain.

| Category | Key Tasks |
|----------|-----------|
| Remote Code Execution | Model output code execution, command injection, serialization, template injection, sandbox escape |
| Supply Chain | Dependency integrity, package repository security, update mechanisms, model source validation |
| Risk Propagation | Error cascade patterns, failure propagation paths, cross-service impact, state persistence |
| System Integrity | Output validation chains, input sanitization, data pipeline integrity, configuration consistency |
| Resource Control | Rate limiting bypasses, resource exhaustion (denial-of-wallet), quota management, DoS resilience |
| Security Measures | Authentication, authorization, encryption, monitoring, incident response procedures |

### Phase 4: Runtime / Human & Agentic Evaluation

Test real-world interactions, multi-agent behavior, and business process impact.

| Category | Key Tasks |
|----------|-----------|
| Business Process | Workflow hand-off disruption, race conditions in AI-human processing, privilege escalation chains |
| Multi-Component AI | Conflicting outputs between models, information leakage between components, cascade failures |
| Over-Reliance | Human operator over-trust, automation bias, critical paths lacking human oversight, fallback failures |
| Social Engineering | Prompt injection through human operators, AI-human trust exploitation, authority impersonation |
| Downstream Impact | Poisoned output propagation, hallucinated content impact on dependent systems |
| Agentic Testing | Authorization/control hijacking, goal manipulation, hallucination exploitation, blast radius, memory manipulation |

---

## Essential Techniques

### Adversarial Prompt Engineering

- **Static datasets**: Fixed prompts for consistent baseline comparison
- **Dynamic datasets**: Generated and perturbed prompts for evolving threat scenarios
- **One-shot attacks**: Single prompts targeting specific vulnerabilities
- **Multi-turn attacks**: Conversational flows revealing sequential weaknesses with tracking IDs

### Dataset Management

- Include edge cases, ambiguous queries, and harmful instructions
- Track success/failure rates to iteratively improve dataset
- Multiple attempts per prompt (stochastic output variability)
- Threshold determination: flag as vulnerable if succeeds after N attempts (recommended: 15)

### Testing Modalities

- Test all supported input types (text, images, code, audio)
- Cross-modality consistency checks
- Coverage from all input paths (direct chat, RAG, rewritten prompts)

### Output Analysis

- Automated factual accuracy checks (compare RAG source vs. output)
- Manual review for nuanced bias or inappropriate content
- HTML/markdown rendering verification for injection vectors
- Structured output schema validation

---

## Reporting Framework

### Severity Levels

| Severity | Definition | Response |
|----------|-----------|----------|
| **Critical** | Immediate safety or security risk | Immediate attention |
| **High** | Significant ethical or operational impact | Rapid response |
| **Medium** | Notable concerns requiring planned action | Planned remediation |
| **Low** | Minor issues for tracking | Future consideration |

### Metrics to Track

| Metric | Description |
|--------|-------------|
| Vulnerability discovery rate | Unique vulnerabilities found per testing cycle |
| Time to detection | Average time to identify a vulnerability class |
| Coverage metrics | Percentage of risk categories tested |
| False positive rate | Invalid findings vs. total findings |
| Remediation effectiveness | Vulnerabilities resolved vs. reported |
| Model drift detection | Behavioral changes between testing cycles |

### Report Structure

```markdown
## GenAI Red Team Report

### Engagement Summary
- Target system, model version, scope
- Testing dates, team composition
- Methodology and tools used

### Executive Summary
- Overall risk posture
- Critical findings count
- Key recommendations

### Findings (by severity)
| # | Phase | Category | Finding | Severity | Reproduction Steps | Remediation |
|---|-------|----------|---------|----------|--------------------|-------------|
| 1 | Model | Alignment | [desc] | Critical | [steps] | [fix] |

### Risk Assessment
- Residual risks after current mitigations
- Comparison with previous assessments
- Recommended testing cadence

### Appendix
- Full test case inventory
- Tool configurations
- Raw data references
```

---

## Best Practices Checklist

### Planning

- [ ] Define objectives aligned with organizational risk appetite
- [ ] Scope: models, systems, and risk categories to test
- [ ] Assemble cross-functional team (AI/ML, security, ethics, domain experts)
- [ ] Conduct threat modeling before testing
- [ ] Prepare test environments mirroring production

### Execution

- [ ] Start with model-level evaluation before system-level
- [ ] Balance automated tooling with manual expert analysis
- [ ] Test across all input modalities
- [ ] Document every test case, payload, and result
- [ ] Use multiple attempts per test (handle stochastic output)

### Post-Engagement

- [ ] Produce structured report with actionable remediation
- [ ] Conduct debrief with development and security teams
- [ ] Prioritize findings by business risk impact
- [ ] Schedule retesting after remediation
- [ ] Feed findings back into test dataset for regression

### Continuous Integration

- [ ] Integrate automated LLM testing in CI/CD pipelines
- [ ] Generate ML-BOM (CycloneDX) for custom models
- [ ] Monitor for model drift between testing cycles
- [ ] Update test suites for emerging threats
- [ ] Maintain red team knowledge base for institutional learning

---

## Agentic AI Red Teaming Tasks

Specific tasks for testing agentic systems (from Appendix D):

1. **Agent Authorization and Control Hijacking** - Test agent access control boundaries
2. **Checker-Out-of-the-Loop Vulnerability** - Test for missing human oversight
3. **Agent Critical System Interaction** - Test privileged system access
4. **Goal and Instruction Manipulation** - Test goal integrity under adversarial input
5. **Agent Hallucination Exploitation** - Test impact of hallucinated tool calls/actions
6. **Agent Impact Chain and Blast Radius** - Assess cascading failure potential
7. **Agent Knowledge Base Poisoning** - Test RAG/memory corruption vectors
8. **Agent Memory and Context Manipulation** - Test persistent memory attacks
9. **Multi-Agent Exploitation** - Test cross-agent trust and communication
10. **Resource and Service Exhaustion** - Test for unbounded consumption
11. **Supply Chain and Dependency Attacks** - Test tool/plugin/model provenance
12. **Agent Untraceability** - Test audit trail completeness and immutability

---

## Tools & Resources

| Tool | Type | Use Case |
|------|------|----------|
| Microsoft PyRIT | Python framework | Comprehensive automated red teaming |
| Garak | Python scanner | LLM vulnerability scanning |
| Promptfoo | Node.js | CI/CD LLM testing integration |
| OWASP LLM Top 10 | Framework | Risk categorization |
| MITRE ATLAS | Framework | Attack technique mapping |
| NIST AI RMF | Framework | Risk management alignment |
| CycloneDX ML-BOM | Standard | Model supply chain inventory |

---

## References

- [OWASP GenAI Red Teaming Guide v1.0.2 (Full PDF)](https://genai.owasp.org/resource/genai-red-teaming-guide/)
- [OWASP Top 10 for LLM Applications 2025](https://genai.owasp.org/llm-top-10/)
- [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications/)
- [MITRE ATLAS](https://atlas.mitre.org/)
- [NIST AI 600-1](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf)
- [Microsoft PyRIT](https://github.com/Azure/PyRIT)


