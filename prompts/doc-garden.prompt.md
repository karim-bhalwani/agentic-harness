---
agent: guardian
description: Audit documentation for staleness, dead cross-references, version mismatches, and contradictory guidance. Produces a Doc Health Report with specific findings and fix recommendations. Use on a regular cadence or after significant changes to keep the knowledge base trustworthy for agents.
argument-hint: "[scope: 'all', 'skills', 'agents', 'guides', or specific file/folder]"
tools:
  - read
  - search
  - execute
version: "7.0"
updated: "2026-04-12"
---

Audit the documentation in this repository for freshness, accuracy, and internal consistency.

**Scope**: ${input:scope}

## Audit Checklist

Run **every** check below. Report findings per category.

### 1. Cross-Reference Integrity

- For every markdown link (`[text](path)`) in `README.md`, `CORE_PRINCIPLES.md`, `MEGA-MINIONS.md`, `USER-GUIDE.md`, and `guide/*.md`: verify the target file exists at that path
- For every agent name referenced in prose, verify a matching `.agent.md` exists in `prompts/`
- For every skill name referenced in prose, verify a matching `skills/<name>/SKILL.md` exists
- List every broken link with source file, line number, and dead target

### 2. Version & Count Consistency

- Count actual `.agent.md` files in `prompts/` and compare against any stated count in `README.md` or other docs
- Count actual skill directories in `skills/` and compare against any stated count
- Count actual `.prompt.md` files in `prompts/` and compare against any stated count
- Check `metadata.version` and `metadata.updated` fields across skill frontmatter for consistency with stated versions
- Flag any file claiming a version or date that contradicts the frontmatter of the file it describes

### 3. Naming & Path Alignment

- For each skill: verify `name` in YAML frontmatter matches the directory name
- For each agent: verify `name` in YAML frontmatter matches the filename (minus `.agent.md`)
- For each prompt: verify the `agent` field references a valid agent
- Flag any mismatches

### 4. Contradictory Guidance

- Search for rules that appear in multiple files (e.g., security rules in both `copilot-instruction.instructions.md` and agent files). Flag contradictions or drift
- Check if skill descriptions in `README.md` match the `description` field in the skill's `SKILL.md` frontmatter
- Check if agent descriptions in `README.md` match the `description` field in the agent's `.agent.md` frontmatter

### 5. Reference Freshness

- For each `skills/*/references/` directory: check if referenced patterns or examples still match current codebase conventions
- Flag any `references/` file that references tools, libraries, or patterns not mentioned elsewhere in the repo
- Flag any skill whose `references/` directory is empty when the skill body says "see references/"

### 6. Structural Completeness

- Every skill directory must contain `SKILL.md`
- Every skill `SKILL.md` must have valid YAML frontmatter with `name` and `description`
- Every agent must have an Intent Contract section
- Flag any agent missing handoffs, tool declarations, or argument-hint

## Output Format (Doc Health Report)

```markdown
# Doc Health Report - [date]

## Summary

- Files scanned: [N]
- Findings: [N] (Critical: [N], Warning: [N], Info: [N])

## Critical (blocks agent reliability)

1. [finding with file:line reference and fix recommendation]

## Warnings (should fix soon)

1. [finding with file:line reference and fix recommendation]

## Info (minor, fix when convenient)

1. [finding with file:line reference and fix recommendation]

## Verified Clean

- [list of checks that passed with zero findings]
```

**Severity guide:**

- **Critical**: Broken cross-reference, missing file, or contradictory rule that would cause agent confusion
- **Warning**: Stale count, outdated version, or drifted description
- **Info**: Style inconsistency, missing optional field, or minor naming mismatch

