# GenAI Security Deep-Dive: OWASP LLM Top 10 & Threat Modeling

> Deep-dive reference. Loaded on demand for detailed LLM risk assessment and threat modeling.

## OWASP Top 10 for LLMs & GenAI (2025) - Full Details

### LLM01: Prompt Injection

**Risk:** User prompts alter LLM behavior in unintended ways (direct or indirect).

#### Detection Checklist

- [ ] System prompts are exposed to or modifiable by user input
- [ ] External content (web pages, documents, emails) is fed to the LLM without sanitization
- [ ] No input/output filtering pipeline exists
- [ ] Model has unrestricted access to tools or APIs
- [ ] No distinction between trusted instructions and untrusted user input

#### Mitigations

- Constrain model behavior with explicit role/capability boundaries in system prompts
- Implement input validation and output filtering (semantic filters, pattern matching)
- Enforce privilege control and least-privilege access for LLM tool calls
- Segregate and clearly denote untrusted external content
- Require human approval for high-risk actions
- Conduct regular adversarial testing (prompt injection red teaming)

**MITRE ATLAS:** AML.T0051.000 (Direct), AML.T0051.001 (Indirect), AML.T0054 (Jailbreak)

### LLM02: Sensitive Information Disclosure

**Risk:** LLM outputs expose PII, proprietary data, credentials, or training data.

#### Detection Checklist

- [ ] Training data includes PII or confidential business data
- [ ] No output filtering for sensitive data patterns (SSN, API keys, emails)
- [ ] System prompt contains credentials or internal architecture details
- [ ] No access controls on what data the LLM can retrieve

#### Mitigations

- Sanitize training data to remove PII before fine-tuning
- Implement output scanning for sensitive data patterns (regex + NER-based)
- Enforce strict access controls on data sources (least privilege)
- Conceal system prompt internals from user-facing outputs
- Apply differential privacy techniques where feasible

**MITRE ATLAS:** AML.T0024.000, AML.T0024.001, AML.T0024.002

### LLM03: Supply Chain

**Risk:** Compromised models, adapters, datasets, or dependencies introduce vulnerabilities.

#### Detection Checklist

- [ ] Models downloaded from unverified sources without integrity checks
- [ ] No SBOM or AI BOM for model components
- [ ] Third-party LoRA adapters used without security evaluation
- [ ] Dependencies not pinned or scanned for CVEs

#### Mitigations

- Verify model integrity with cryptographic hashes and signatures
- Maintain AI BOM using OWASP CycloneDX
- Scan dependencies with `pip-audit`, `safety`, `npm audit` in CI
- Monitor collaborative model platforms for tampered models

### LLM04: Data and Model Poisoning

**Risk:** Manipulated training/fine-tuning/embedding data introduces backdoors or biases.

#### Detection Checklist

- [ ] Training data sourced from unverified or public sources
- [ ] No data provenance tracking or versioning
- [ ] No anomaly detection on training data or model outputs
- [ ] Embedding pipeline ingests user-supplied content without filtering

#### Mitigations

- Track data origins with OWASP CycloneDX or ML-BOM
- Use data version control (DVC) to detect unauthorized modifications
- Implement strict sandboxing to limit model exposure to unverified data
- Run anomaly detection on training loss and model behavior

**MITRE ATLAS:** AML.T0018 (Backdoor ML Model)

### LLM05: Improper Output Handling

**Risk:** LLM output passed to downstream systems without validation enables XSS, SSRF, code execution.

#### Mitigations

- Treat all LLM output as untrusted input
- Apply context-aware output encoding (HTML, URL, JS, SQL)
- Validate structured outputs against strict JSON schemas
- Sandbox code execution environments for LLM-generated code

### LLM06: Excessive Agency

**Risk:** LLM granted too many permissions, functions, or autonomy without oversight.

#### Mitigations

- Apply least-privilege: grant only minimum tools and permissions needed
- Define explicit authorization scopes for each tool
- Require human approval for high-risk operations
- Set hard loop limits on agent iterations (default: 10 max)
- Log all tool invocations with full input/output for audit

### LLM07: System Prompt Leakage

**Risk:** System prompts or internal instructions are exposed to users or attackers.

#### Mitigations

- Never place secrets, API keys, or sensitive config in system prompts
- Add explicit anti-leakage instructions
- Implement output monitoring to detect prompt leakage patterns
- Test with adversarial prompt leakage attacks during red teaming

### LLM08: Vector and Embedding Weaknesses

**Risk:** Vulnerabilities in RAG retrieval allow data poisoning, access bypass, or information leakage.

#### Mitigations

- Implement document-level access controls in vector database queries
- Filter retrieved results by user authorization context
- Validate retrieval relevance scores with minimum thresholds
- Sanitize documents before embedding (strip hidden instructions)
- Use encryption at rest for vector stores containing sensitive data

### LLM09: Misinformation

**Risk:** LLM generates false, misleading, or fabricated content presented as fact.

#### Mitigations

- Implement RAG with source citations to ground responses
- Add factual validation layers
- Require human review for high-stakes or externally published content
- Include confidence indicators and disclaimers

### LLM10: Unbounded Consumption

**Risk:** Uncontrolled token usage, API calls, or resource consumption.

#### Mitigations

- Set per-request and per-user token budgets
- Implement rate limiting and request throttling
- Add timeouts on all LLM API calls (default: 30s)
- Set hard iteration limits on agent loops
- Implement circuit breakers for external LLM API dependencies

## GenAI Threat Modeling

Extends traditional STRIDE with AI-specific threat categories:

| STRIDE Category            | Traditional Threat        | GenAI Extension                                    |
| -------------------------- | ------------------------- | -------------------------------------------------- |
| **Spoofing**               | Impersonating a user      | Prompt injection impersonating system instructions |
| **Tampering**              | Modifying data in transit | Poisoning training data or embedding content       |
| **Repudiation**            | Denying actions           | Agent actions without audit trail                  |
| **Info Disclosure**        | Leaking sensitive data    | LLM memorization, system prompt leakage            |
| **Denial of Service**      | Overwhelming resources    | Unbounded token consumption, recursive agents      |
| **Elevation of Privilege** | Gaining admin access      | Excessive agency, tool permission bypass           |

### Additional GenAI Threat Categories

- **Model Inversion:** Extracting training data from model through targeted queries
- **Adversarial Inputs:** Crafted inputs that cause model misclassification or unsafe behavior
- **Supply Chain Compromise:** Backdoored models, poisoned adapters, malicious dependencies
- **Cross-Modal Attacks:** Hidden instructions in images, audio, or documents processed by multimodal models


