# Context Engineer Deep-Dive: Templates, Memory System & Retrospectives

> Deep-dive reference. Loaded on demand for project memory templates, retrospective workflows, and environment auditing.

## Project Memory System

### Bug-Solution Tracking

```markdown
## Bug Log

### BUG-001: [Title]

- **Date**: YYYY-MM-DD
- **Symptom**: [What was observed]
- **Root Cause**: [What actually caused it]
- **Solution**: [What fixed it]
- **Prevention**: [How to avoid recurrence]
- **Files**: [Affected files]
```

### Architectural Decision Records

```markdown
## ADR-001: [Title]

- **Date**: YYYY-MM-DD
- **Status**: [Proposed | Accepted | Deprecated | Superseded]
- **Context**: [Why this decision was needed]
- **Decision**: [What was decided]
- **Alternatives Considered**: [What was rejected and why]
- **Consequences**: [Trade-offs accepted]
```

### Key Facts Registry

```markdown
## Project Facts

### Verified Facts

- [Fact] - Source: [file/conversation/test] - Date: YYYY-MM-DD

### Working Assumptions

- [Assumption] - Confidence: [High/Medium/Low] - Verify by: [trigger]
```

### Work History

```markdown
## Session Log

### Session YYYY-MM-DD

- **Goal**: [What was attempted]
- **Completed**: [What was finished]
- **Remaining**: [What's left]
- **Blockers**: [What prevented progress]
- **Decisions Made**: [Links to ADRs]
```

## Workflow Retrospective

After each significant workflow cycle (discovery > design > build > review > ship), produce or update a retrospective document.

### RETROSPECTIVE.md Template

```markdown
# Workflow Retrospective

## Cycle: [Feature/Sprint Name]
## Date: [YYYY-MM-DD]
## Agents Involved: [list]

### Specification Quality
- What was specified clearly?
- What was ambiguous or incomplete?
- Did any holdout scenario failures reveal spec gaps?

### Handoff Effectiveness
- Which handoffs worked cleanly (context preserved)?
- Which handoffs lost context or required backtracking?
- Were token budgets respected?

### Rework Incidents
| Agent | State Machine Retries | Escalations | Root Cause |
| ----- | --------------------- | ----------- | ---------- |
| senior-developer | 0/1/2/3 | Yes/No | ... |
| guardian | 0/1/2/3 | Yes/No | ... |

### Agent Value Assessment
- Which agents added clear value in this cycle?
- Which agents created overhead without proportional output?
- Should any workflow step be simplified or consolidated?

### Harness Review
Every harness component encodes an assumption about what the model cannot do on its own. Review each component used in this cycle:

| Component | Type | Assumption Encoded | Still Valid? | Verdict |
| --------- | ---- | ------------------ | ------------ | ------- |
| (name) | agent/skill/step | "Model can't do X without this" | Yes/No/Partial | KEEP/SIMPLIFY/RETIRE |

Rules:
- Default to KEEP only if removing demonstrably degrades output quality.
- SIMPLIFY when scope exceeds what's load-bearing.
- RETIRE when the model handles the task adequately without the component.
- After a major model upgrade, re-evaluate every component.

### Lessons Learned
- What convention, pattern, or skill is missing that would prevent recurrence?
- What should be encoded into the Project Bible for future cycles?
```

### Rework Tracking

Rework is a signal of specification failure. Track these data points:

- **3-strike escalations**: agent, phase, root cause
- **Guardian rework**: severity and category of remediation findings
- **Holdout failures**: gap between spec intent and implementation outcome
- **Re-interview triggers**: what was missing from initial requirements
- **Quality grade trends**: if `.copilot/quality/QUALITY_GRADES.md` exists, track grade distribution; flag if average drops below B across 3+ reviews

These accumulate in `RETROSPECTIVE.md`. If the same rework category recurs across 3+ cycles, recommend a structural fix.

### Workflow Effectiveness Audit

After every 5 completed workflows (or quarterly):

1. Review all retrospectives since the last audit
2. Identify recurring rework patterns
3. Assess each agent's value vs. coordination cost
4. **Harness simplification**: aggregate Harness Review verdicts; 3+ RETIRE/SIMPLIFY = candidate for removal; 0 uses in 5 cycles = retirement candidate
5. Recommend simplifications
6. **Entropy audit**: load [entropy_audit.md](./references/entropy_audit.md) checklist and run each category
7. Update the Project Bible with findings

## Environment Auditing

### Gap Analysis Checklist

- [ ] Tech stack documented and version-pinned?
- [ ] Build commands verified (actually run)?
- [ ] Test commands verified (actually run)?
- [ ] Critical rules defined (not vague)?
- [ ] Deployment target specified?
- [ ] Security non-negotiables listed?
- [ ] Decision log initialized?

### Consistency Check

- Compare `PROJECT_CONTEXT.md` against actual:
  - Python version in `pyproject.toml` vs. documented
  - Dependencies in lockfile vs. documented stack
  - Directory structure vs. documented module map
- Flag discrepancies with `[STALE]` tag

### Refresh Triggers

- Major dependency upgrade
- New service or module added
- Team size change
- Deployment target change
- After 3 months without update (quarterly review)
- After 5 completed agent workflows

## 5-Minute Orientation Details

Every project should have `.copilot/context/ORIENTATION.md` (500-800 words).

### When to Generate

- After Brownfield Discovery (from confirmed findings)
- After Greenfield Interview (from declared intent)
- During quarterly context refresh

### How to Generate

1. Load [orientation_template.md](./references/orientation_template.md)
2. Fill each section from Project Bible content and verified command output
3. Keep under 800 words; omit inapplicable sections
4. Mark unverified items with `[NOT VERIFIED]`

### Tier Placement

`ORIENTATION.md` is Tier 1 (always loaded), under 200 lines. Supplements `PROJECT_CONTEXT.md` as the "elevator pitch" version.

## Feature Progress Tracker

If `.copilot/state/FEATURE_PROGRESS.json` exists:

- **On session resume**: summarize progress (X of Y tasks completed, blocked tasks)
- **During retrospectives**: calculate velocity (tasks per cycle), compare across cycles
- **During audits**: aggregate across features to identify slowest task types/agents

Created by `concise-planning`, updated by builders. Context-engineer reads only.


