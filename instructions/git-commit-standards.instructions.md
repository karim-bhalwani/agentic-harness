---
name: "Git Commit Standards"
description: "Git commit message conventions: conventional commits, imperative mood, body wrapping, and subject discipline. Applies to all git commit operations."
applyTo: "**"
version: "9.0"
updated: "01-July-2026"
---

# Git Commit Standards

**Version:** 9.0 | **Updated:** 01-July-2026

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Type (Required)

| Type       | Purpose                                                 |
| ---------- | ------------------------------------------------------- |
| `feat`     | New feature or capability                               |
| `fix`      | Bug fix                                                 |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf`     | Performance improvement                                 |
| `test`     | Adding or correcting tests                              |
| `docs`     | Documentation-only changes                              |
| `chore`    | Build, tooling, or dependency changes                   |
| `ci`       | CI/CD configuration changes                             |
| `revert`   | Revert a previous commit                                |

## Scope (Optional)

The scope is the module, agent, skill, or layer affected. Use lowercase, hyphenated names.

- Agent name: `feat(guardian): add holdout scenario validation`
- Skill name: `fix(architect): correct spec template section count`
- Hook name: `perf(scan-secrets): reduce regex passes per line`
- Layer-wide: `chore(hooks): update shared library functions`

## Subject (Required)

- Use imperative mood: "add" not "added" or "adds"
- Do not capitalize the first letter
- No period at the end
- Maximum 72 characters
- Describe WHAT and WHY, not HOW

**Good:**

- `feat(close-story): add reciprocal handoff to release-manager`
- `fix(sprint-contract): correct SPEC.md file path reference`

**Bad:**

- `Added feature` (past tense, no scope, no type)
- `fix: some changes` (vague, no imperative)
- `feat: stuff` (not descriptive)

## Body (Optional but Recommended for Non-Trivial Changes)

- Wrap at 72 characters
- Explain the motivation for the change
- Contrast with previous behavior
- Reference issue or story IDs: `Closes US-03` or `Relates to SPEC.md §4.2`

## Footer (Optional)

- Breaking changes: `BREAKING CHANGE: <description>`
- Co-authors: `Co-authored-by: Name <email>`
- References: `Refs: #42`, `See: ARCHITECTURE.md`

## Commit Size Discipline

- One logical change per commit
- Do not bundle unrelated changes
- If the commit has "and" in the subject, consider splitting it
- Maximum 200 lines changed per commit (excluding generated files)

## What NOT to Do

- Do not commit secrets, credentials, or `.env` files
- Do not commit `__pycache__/`, `node_modules/`, or build artifacts
- Do not use `git commit -m` for multi-line messages (use an editor)
- Do not commit with `--no-verify` to bypass hooks
- Do not amend pushed commits (only amend local, unpushed commits)

## Pre-Commit Checklist

Before committing, verify:

- [ ] Tests pass (`pytest`, `npm test`, or equivalent)
- [ ] Linter passes (`ruff check`, `npm run lint`)
- [ ] No secrets in diff (`git diff --staged` review)
- [ ] Commit message follows conventional commit format
- [ ] One logical change per commit
