---
agent: debug-detective
description: Trigger a hypothesis-driven root cause investigation of any system failure - runtime error, test failure, pipeline crash, or unexpected behaviour. Uses the debug-detective agent with full FSM workflow. Produces a Root Cause Report with confirmed cause, evidence trail, and a fix recommendation. Use when you need a systematic diagnosis, not a guess.
argument-hint: "[error message, stack trace, or failure description]"
tools:
  - read
  - search
  - execute
  - agent
version: "7.0"
updated: "2026-04-12"
---

Use the `debug-detective` agent to investigate this failure: **${input:failure}**

**Evidence to collect before hypothesising** (gather all that exist):

- Full error message or stack trace
- Relevant log output around the time of failure
- Recent code changes (`git log --oneline -20`)
- Test output if a test is failing
- Environment details if behaviour differs across environments

**Investigation protocol** (do not skip steps):

1. **OBSERVE**: Reproduce or precisely describe the failure - exact error, exact conditions
2. **HYPOTHESISE**: List up to 3 candidate root causes ranked by probability
3. **TEST**: For each hypothesis, identify the specific evidence that would confirm or eliminate it
4. **CONFIRM**: Eliminate hypotheses until exactly one remains - cite the confirming evidence
5. **FIX**: Propose the minimal code change that addresses the confirmed root cause

**Output format** (Root Cause Report):

- **Failure summary**: one sentence
- **Root cause**: confirmed single cause with evidence citation (file:line or log line)
- **Why it was hidden**: what made the bug non-obvious
- **Proposed fix**: specific, minimal change with code snippet if applicable
- **Regression risk**: any adjacent areas that could be affected by the fix
- **Handoff**: suggest `senior-developer` for implementation or `architect` if systemic

Do NOT propose a fix until the root cause is confirmed by evidence. "I think it might be" is not confirmation.

