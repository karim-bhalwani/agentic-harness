---
name: "Markdown Standards"
description: "Markdown conventions for docs, skills, and agent files: ATX headings, fenced code, frontmatter discipline, link hygiene, and table formatting."
applyTo: "**/*.md"
version: "9.0"
updated: "01-July-2026"
---

# Markdown Standards

## Structure

- One `#` H1 per document, immediately at the top (after frontmatter if present).
- Use ATX-style headings (`##`, `###`) - never Setext underlines.
- Increment heading levels by one. Do not skip from `##` to `####`.
- Insert one blank line above and below every heading, list, code block, and table.

## Frontmatter

- Skill files (`SKILL.md`), agent files (`*.agent.md`), and instruction files use YAML frontmatter delimited by `---`.
- Required keys depend on file type (see `guide/SKILLS-GUIDE.md` and `guide/AGENT-GUIDE.md`).
- Always include `version` and `updated` (ISO `01-July-2026` format used in this repo).

## Code & Commands

- Fenced code blocks with language tags (` ```bash `, ` ```python `, ` ```powershell `, ` ```yaml `).
- Inline code with backticks for symbols, filenames, env vars: `Get-MMGovernanceLevel`, `SKIP_QUALITY_GATE`.
- Do NOT wrap file references in backticks when they should be links (see Links below).

## Links

- File references use relative markdown links: `[hooks/_lib.ps1](../hooks/_lib.ps1)` not `` `hooks/_lib.ps1` ``.
- Link text MUST match the target path when no line number is included.
- Use line anchors when pointing at code: `[_lib.ps1#L42](../hooks/_lib.ps1#L42)`.
- External links must be HTTPS and stable (no time-limited share links).

## Lists & Tables

- Hyphens (`-`) for unordered lists. Do not mix `*` and `-`.
- 2-space indent for nested list items.
- Tables: pipe-delimited, with leading and trailing pipes. Align the separator row with hyphens.
- Avoid trailing whitespace except for intentional `  ` line breaks.

## Voice

- Imperative for instructions ("Run X", "Add Y"). Avoid first person.
- No emojis unless explicitly requested by content domain.
- English only.
