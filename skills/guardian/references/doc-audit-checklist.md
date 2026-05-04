# Documentation Audit Checklist

> **Used by:** `prompts/doc-garden.prompt.md` (`/doc-garden`)
> **Owner:** `guardian` agent
> **Purpose:** Single source of truth for the documentation freshness, accuracy, and internal consistency audit. Anyone (human or agent) running `/doc-garden` walks this checklist top to bottom and produces the report defined in §7.

---

## Scope Modes

The `/doc-garden` prompt accepts one of:

- `all` - run every check below across the whole repo.
- `spec` - limit to `.copilot/specs/**` and any docs that reference specs.
- `context` - limit to `.copilot/context/**` (Project Bible, decisions, glossary).
- `state` - limit to `.copilot/state/**` (session state, in-flight work).
- `<path>` - limit to a specific file or folder.

If scope is missing or ambiguous, ask the user before running.

## Severity Definitions

- **Critical** - broken cross-reference, missing file, or contradictory rule that would cause an agent or developer to act on false information.
- **Warning** - stale count, outdated version, or drifted description. Not currently breaking but will mislead within one cycle.
- **Info** - style inconsistency, missing optional field, or minor naming mismatch. Fix when convenient.

---

## Checks

Run **every** check that falls inside the requested scope. Skip a category only if scope explicitly excludes it.

### 1. Cross-Reference Integrity

- For every markdown link `[text](path)` in `README.md`, `CORE_PRINCIPLES.md`, `MEGA-MINIONS.md`, `USER-GUIDE.md`, and `guide/*.md`: verify the target file exists at that path.
- For every agent name referenced in prose, verify a matching `*.agent.md` exists in `prompts/`.
- For every skill name referenced in prose, verify a matching `skills/<name>/SKILL.md` exists.
- List every broken link with source file, line number, and dead target.

### 2. Version & Count Consistency

- Count actual `*.agent.md` files in `prompts/` and compare against any stated count in docs.
- Count actual skill directories in `skills/` and compare against any stated count.
- Count actual `*.prompt.md` files in `prompts/` and compare against any stated count.
- Check `metadata.version` and `metadata.updated` fields across skill frontmatter for consistency with stated versions.
- Flag any file claiming a version or date that contradicts the frontmatter of the file it describes.

### 3. Naming & Path Alignment

- For each skill: verify `name` in YAML frontmatter matches the directory name.
- For each agent: verify `name` in YAML frontmatter matches the filename (minus `.agent.md`).
- For each prompt: verify the `agent` field references a valid agent (file exists in `prompts/`).
- Flag any mismatches.

### 4. Contradictory Guidance

- Search for rules that appear in multiple files (e.g. security rules in both instruction files and agent files). Flag contradictions or drift.
- Check if skill descriptions in `README.md` match the `description` field in the skill's `SKILL.md` frontmatter.
- Check if agent descriptions in `README.md` match the `description` field in the agent's `*.agent.md` frontmatter.

### 5. Reference Freshness

- For each `skills/*/references/` directory: check if referenced patterns or examples still match current codebase conventions.
- Flag any `references/` file that references tools, libraries, or patterns not mentioned elsewhere in the repo.
- Flag any skill whose `references/` directory is empty when the skill body says "see references/".

### 6. Structural Completeness

- Every skill directory must contain `SKILL.md`.
- Every skill `SKILL.md` must have valid YAML frontmatter with `name` and `description`.
- Every agent must have an Intent Contract section (or equivalent declared outcome).
- Flag any agent missing handoffs, tool declarations, or argument-hint.

### 7. Programmatic Cross-Check

If `audit.py` exists at repo root, run `uv run python audit.py --lint` and incorporate its findings. Treat audit-script findings as authoritative for structural validation; this checklist focuses on semantic and freshness issues that the script cannot detect.

---

## Output: Doc Health Report

Write to `.copilot/artifacts/doc-health-report.md` (overwrite if it exists). Use this exact structure:

```markdown
# Doc Health Report - YYYY-MM-DD

## Summary

- Scope: [all / spec / context / state / <path>]
- Files scanned: N
- Findings: N (Critical: N, Warning: N, Info: N)

## Critical (blocks agent reliability)

1. [finding with file:line reference and fix recommendation]

## Warnings (should fix soon)

1. [finding with file:line reference and fix recommendation]

## Info (minor, fix when convenient)

1. [finding with file:line reference and fix recommendation]

## Verified Clean

- [list of checks that passed with zero findings]
```

If a category has no findings, write `_None._` under that heading rather than omitting it. The report's shape must be stable so `release-manager` can verify it programmatically.
