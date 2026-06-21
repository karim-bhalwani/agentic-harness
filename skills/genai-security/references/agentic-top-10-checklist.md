# OWASP Top 10 for Agentic Applications (2026) - Detailed Checklist

**Source:** [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications/)
**Version:** 9.0 (December 2025)

Use this reference for detecting, mitigating, and testing risks specific to autonomous AI agent systems.

---

## ASI01: Agent Goal Hijack

### Description

Attackers manipulate an agent's objectives, task selection, or decision pathways through prompt-based manipulation, deceptive tool outputs, malicious artefacts, forged agent-to-agent messages, or poisoned external data. Unlike LLM01 (single model response), ASI01 captures multi-step behavioral redirection.

### Detection Checklist

- [ ] Test indirect prompt injection via hidden payloads in documents, web pages, emails
- [ ] Test direct prompt injection to override agent instructions
- [ ] Verify agent goal integrity after consuming external data sources
- [ ] Test cross-channel injection (email, calendar, messaging hijack)
- [ ] Validate that agent cannot be redirected to exfiltrate data via tool misuse
- [ ] Test multi-step goal drift across conversation turns

### Key Mitigations

1. Enforce strict instruction hierarchy with clear priority between system, user, and external input
2. Validate agent actions against declared goals before execution
3. Implement behavioral monitoring comparing actions to expected patterns
4. Use input sanitization on all external data before agent consumption
5. Require human approval for goal-changing or high-impact actions

### LLM Top 10 Mapping

- LLM01:2025 Prompt Injection
- LLM06:2025 Excessive Agency

### Threat & Mitigation Mapping

- T6 Goal Manipulation
- T7 Misaligned & Deceptive Behaviors

---

## ASI02: Tool Misuse & Exploitation

### Description

Agents misuse available tools in unintended or unsafe ways, or attackers exploit tool integrations to escalate actions beyond intended scope. Includes function call injection, tool parameter manipulation, and chaining tools for unauthorized operations.

### Detection Checklist

- [ ] Audit all tools available to the agent; verify each is necessary (least-tool principle)
- [ ] Test tool parameter injection / manipulation
- [ ] Test multi-tool chaining to achieve unintended outcomes
- [ ] Verify tool output validation before downstream consumption
- [ ] Test for tool feedback loop exploitation
- [ ] Verify rate limits and resource bounds on tool invocations
- [ ] Ensure destructive tool calls require explicit human approval

### Key Mitigations

1. Apply least-tool principle: grant only necessary tools per task
2. Validate all tool call parameters against schema before execution
3. Implement tool output sanitization before returning to agent
4. Use allowlists for permitted tool call patterns
5. Log all tool invocations with full input/output for audit

### LLM Top 10 Mapping

- LLM06:2025 Excessive Agency

### Threat & Mitigation Mapping

- T2 Tool Misuse
- T4 Resource Overload
- T16 Insecure Inter-Agent Protocol Abuse

---

## ASI03: Identity & Privilege Abuse

### Description

Agents lack distinct, governed identities, creating attribution gaps. Agent-to-agent trust or inherited credentials enable privilege escalation, session hijacking, or unauthorized actions. Agentic evolution of LLM06 Excessive Agency.

### Detection Checklist

- [ ] Verify agents have distinct, auditable identities (not shared user credentials)
- [ ] Test for unscoped privilege inheritance during delegation
- [ ] Test memory-based credential reuse across sessions
- [ ] Test cross-agent confused deputy attacks
- [ ] Verify TOCTOU (time-of-check to time-of-use) protection in workflows
- [ ] Test synthetic identity injection (fake agent personas)

### Key Mitigations

1. Assign per-agent identities with scoped, short-lived credentials (mTLS, scoped tokens)
2. Enforce task-scoped, time-bound permissions for each delegation
3. Isolate agent contexts with sandboxed memory per session
4. Mandate per-action re-authorization for privileged operations
5. Require human-in-the-loop for privilege escalation
6. Evaluate agentic identity management platforms (Entra, Bedrock Agents, etc.)

### LLM Top 10 Mapping

- LLM01:2025 Prompt Injection
- LLM06:2025 Excessive Agency
- LLM02:2025 Sensitive Information Disclosure

### Threat & Mitigation Mapping

- T3 Privilege Compromise

---

## ASI04: Agentic Supply Chain Vulnerabilities

### Description

Agents, tools, and artefacts from third parties may be malicious, compromised, or tampered. Unlike traditional supply chain (LLM03), agentic ecosystems compose capabilities at runtime (dynamic tool loading, MCP servers, agent registries), creating a live, opaque supply chain.

### Detection Checklist

- [ ] Verify provenance and cryptographic signatures for all models, tools, and plugins
- [ ] Maintain AI BOM (OWASP CycloneDX) inventory of all components
- [ ] Scan for typosquatting in package managers (PyPI, npm, etc.)
- [ ] Test for poisoned prompt templates from external sources
- [ ] Test for tool-descriptor injection in MCP/A2A server metadata
- [ ] Verify MCP/agent registry security (authentication, integrity checks)
- [ ] Test for compromised third-party agents in multi-agent workflows

### Key Mitigations

1. Sign and attest manifests, prompts, and tool definitions; require SBOMs/AIBOMs
2. Allowlist and pin dependencies; auto-reject unsigned or unverified components
3. Run sensitive agents in sandboxed containers with strict network/syscall limits
4. Put prompts and memory schemas under version control with peer review
5. Enforce mutual auth and attestation via PKI and mTLS for inter-agent communication
6. Implement supply chain kill switch for emergency revocation

### Real-World Incidents

- Amazon Q: Poisoned prompt shipped in extension v1.84.0
- Malicious MCP server impersonating Postmark on npm (BCC'd emails to attacker)
- MCP Tool Descriptor Poisoning via GitHub metadata (private repo data exfiltration)

### Threat & Mitigation Mapping

- T17 Supply Chain Compromise
- T2 Tool Misuse
- T11 Unexpected RCE
- T12 Agent Communication Poisoning
- T13 Rogue Agent

---

## ASI05: Unexpected Code Execution (RCE)

### Description

Agents generate and execute code in real-time, bypassing traditional security controls. Prompt injection, tool misuse, or unsafe serialization convert text into unintended executable behavior, including shell commands, deserialized objects, template engines, and eval() exploits.

### Detection Checklist

- [ ] Test for prompt injection leading to code execution
- [ ] Test for code hallucination generating malicious constructs
- [ ] Verify shell command invocation is blocked from reflected prompts
- [ ] Test for unsafe function calls, deserialization, or eval() exposure
- [ ] Verify sandboxing of all LLM-generated code execution
- [ ] Test for dependency lockfile poisoning in ephemeral sandboxes
- [ ] Test multi-tool chain exploitation paths to RCE

### Key Mitigations

1. Separate code generation from execution with mandatory validation gates
2. Execute all LLM-generated code in isolated sandboxes (containers, WASM)
3. Restrict filesystem access to dedicated working directories
4. Require human approval for elevated code execution
5. Run static analysis scans before any generated code execution
6. Maintain allowlists for auto-execution under version control

### Real-World Incidents

- Replit: Agent deleted production DB during "vibe coding" self-repair
- GitHub Copilot: RCE via prompt injection
- Cursor: Config overwrite via case mismatch enabling persistent RCE

### Threat & Mitigation Mapping

- T11 Unexpected RCE & Code Attacks

---

## ASI06: Memory & Context Poisoning

### Description

Adversaries corrupt stored context, long-term memory, RAG stores, or embeddings with malicious or misleading data, causing future reasoning, planning, or tool use to become biased, unsafe, or aid exfiltration. Distinct from ASI01 (direct goal manipulation) in that corruption is persistent.

### Detection Checklist

- [ ] Test for RAG/embedding poisoning via malicious documents
- [ ] Test shared user context contamination across sessions
- [ ] Test context-window manipulation (injected content persists via summarization)
- [ ] Monitor for long-term memory drift from incrementally tainted data
- [ ] Test for cross-agent memory propagation of corrupted context
- [ ] Verify per-tenant namespace isolation in shared vector stores

### Key Mitigations

1. Baseline and monitor memory/context integrity with drift detection
2. Require provenance tracking for all stored context entries
3. Implement trust scores for memory entries with TTL/decay for unverified data
4. Use per-tenant namespaces in shared vector/memory stores
5. Prevent auto-re-ingestion of agent's own outputs ("bootstrap poisoning")
6. Support rollback/quarantine for suspected poisoning events
7. Require human review for high-risk actions influenced by retrieved context

### Real-World Incidents

- Gemini: Prompt injection corrupted long-term memory
- AgentPoison: Poisoning memory/knowledge bases to control agent behavior
- AgentFlayer: Persistent 0-click exploit on ChatGPT via memory manipulation

### Threat & Mitigation Mapping

- T1 Memory Poisoning
- T4 Memory Overload
- T6 Broken Goals
- T12 Shared Memory Poisoning

---

## ASI07: Insecure Inter-Agent Communication

### Description

Multi-agent systems depend on continuous communication via APIs, message buses, and shared memory. Weak authentication, integrity, or semantic validation enables interception, spoofing, replay, or manipulation of agent messages.

### Detection Checklist

- [ ] Test for unencrypted agent-to-agent channels
- [ ] Test message tampering and semantic manipulation via MITM
- [ ] Test replay attacks on trust chains and delegation messages
- [ ] Test protocol downgrade attacks (force legacy unencrypted mode)
- [ ] Test MCP descriptor poisoning and A2A registration spoofing
- [ ] Test for metadata-based behavioral profiling (timing, patterns)
- [ ] Test for semantics split-brain (divergent intent parsing across agents)

### Key Mitigations

1. Use end-to-end encryption with per-agent credentials and mutual authentication
2. Digitally sign messages with payload + context hashing
3. Enforce versioned, typed message schemas with per-message audiences
4. Disable weak/legacy communication modes; enforce protocol pinning
5. Authenticate all discovery/coordination messages with cryptographic identity
6. Use registries with digital attestation of agent identity and provenance

### Threat & Mitigation Mapping

- T12 Agent Communication Poisoning
- T16 Insecure Inter-Agent Protocol Abuse

---

## ASI08: Cascading Failures

### Description

A single fault (hallucination, malicious input, corrupted tool, poisoned memory) propagates across autonomous agents, compounding into system-wide harm. Agents' autonomous planning, persistence, and delegation amplify errors beyond stepwise human checks.

### Detection Checklist

- [ ] Test for rapid fan-out (one faulty decision triggers many downstream agents)
- [ ] Test for cross-domain/tenant spread beyond original context
- [ ] Monitor for oscillating retries or feedback loops between agents
- [ ] Test planner-executor coupling (hallucinating planner triggers unsafe execution)
- [ ] Test cascade from corrupted persistent memory to new plans
- [ ] Test auto-deployment cascade from tainted updates
- [ ] Monitor for governance drift (bulk approvals weakening oversight)

### Key Mitigations

1. Design zero-trust architecture assuming LLM/agent component failure
2. Sandbox agents with least privilege, network segmentation, scoped APIs
3. Issue JIT, one-time, task-scoped credentials with policy-as-code validation
4. Separate planning and execution with independent policy engine
5. Implement checkpoints (governance agents or human review) before propagation
6. Rate limit and throttle cross-agent command propagation
7. Deploy circuit breakers between planner and executor stages

### Threat & Mitigation Mapping

- T5 Cascading Hallucination Attacks
- T8 Repudiation & Untraceability

---

## ASI09: Human-Agent Trust Exploitation

### Description

Agents exploit human trust through natural language fluency, emotional intelligence, and perceived expertise. Adversaries or misaligned designs leverage authority bias, anthropomorphism, and persuasive explainability to bypass oversight.

### Detection Checklist

- [ ] Test for insufficient explainability (opaque reasoning forcing blind trust)
- [ ] Test for missing confirmation on sensitive/irreversible actions
- [ ] Test for emotional manipulation through anthropomorphic language
- [ ] Test for fake explainability (fabricated rationales hiding malicious logic)
- [ ] Test consent laundering via "read-only" previews that trigger side effects
- [ ] Monitor for over-reliance patterns (human approval without independent validation)

### Key Mitigations

1. Separate AI-generated reasoning from verified explanations
2. Require independent human validation for high-impact recommendations
3. Monitor for sensitive data exposure in conversations and connections
4. Allow users to flag suspicious agent behavior (triggering automated review)
5. Implement adaptive trust calibration based on contextual risk scoring
6. Attach verifiable provenance metadata to all recommendations
7. Use visual UI safeguards (red borders, banners) for high-risk actions

### Threat & Mitigation Mapping

- T7 Misaligned & Deceptive Behaviors
- T8 Repudiation & Untraceability
- T10 Overwhelming Human in the Loop

---

## ASI10: Rogue Agents

### Description

Malicious or compromised agents deviate from intended function, acting harmfully, deceptively, or parasitically. Actions may individually appear legitimate but emergent behavior becomes harmful. Includes goal drift, scheming, workflow hijacking, collusion, and self-replication.

### Detection Checklist

- [ ] Monitor for goal drift (agent appears compliant but pursues hidden goals)
- [ ] Test for workflow hijacking (agent redirects trusted workflows)
- [ ] Monitor for cross-agent collusion patterns and coordinated false signals
- [ ] Test for self-replication via provisioning APIs
- [ ] Test reward hacking scenarios (agent finds harmful shortcuts to optimize metrics)
- [ ] Verify immutable, signed audit logs for all agent actions and communications

### Key Mitigations

1. Maintain comprehensive, immutable, signed audit logs of all agent actions
2. Assign trust zones with strict inter-zone communication rules
3. Deploy watchdog agents to validate peer behavior and outputs
4. Implement kill switches and credential revocation for rapid containment
5. Establish trusted baselines for restoring quarantined agents
6. Require fresh attestation and human approval before reintegration

### Threat & Mitigation Mapping

- T13 Rogue Agents in Multi-Agent Systems

---

## Cross-Reference: ASI to LLM Top 10 Mapping

| ASI | Primary LLM Top 10 | Threat Codes |
|-----|-------------------|--------------|
| ASI01 Goal Hijack | LLM01, LLM06 | T6, T7 |
| ASI02 Tool Misuse | LLM06 | T2, T4, T16 |
| ASI03 Identity Abuse | LLM01, LLM02, LLM06 | T3 |
| ASI04 Supply Chain | LLM03 | T17, T2, T11, T12, T13, T16 |
| ASI05 RCE | LLM01, LLM05 | T11 |
| ASI06 Memory Poisoning | LLM01, LLM04, LLM08 | T1, T4, T6, T12 |
| ASI07 Inter-Agent Comm | LLM02, LLM06 | T12, T16 |
| ASI08 Cascading Failures | LLM01, LLM04, LLM06 | T5, T8 |
| ASI09 Human Trust | LLM01, LLM05, LLM06, LLM09 | T7, T8, T10 |
| ASI10 Rogue Agents | LLM02, LLM09 | T13 |


