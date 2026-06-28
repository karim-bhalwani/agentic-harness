---
agent: ai-engineer
description: Run health checks on the project's knowledge mem. Auto-fixes broken links and index gaps, reports contradictions, orphan pages, stale content, and missing concept pages. Use periodically or after major changes to keep the mem trustworthy.
argument-hint: "[scope: 'all', 'links', 'index', or specific topic directory]"
tools:
  - read
  - search
  - edit
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

## Intent Contract

When this prompt completes, these conditions must be true:

- All broken links, orphaned references, and stale entries are identified
- The lint report distinguishes between critical issues and nice-to-fixes
- The mem health score is updated and accurate

Lint the project mem. Scope: **${input:scope}** (valid values: `all`, `links`, `index`, or a specific topic directory path, e.g., `topics/AI/`). If the directory does not exist in the project, respond with: "Directory not found. Please provide a valid topic directory path."

**Pre-flight checks (run in order, stop on first failure):**

1. **Validate scope value** - if the value is not one of `all`, `links`, `index`, or a valid topic directory path, respond with: "Invalid scope provided. Please use one of the valid values: `all`, `links`, `index`, or a specific topic directory path."
2. **Load `~/.copilot/skills/llm-mem/SKILL.md`** via `read_file` - if not found, respond with: "Skill file not found. Ensure the file exists and is accessible." If the file loads but does not contain a recognizable lint workflow or report format section, respond with: "Skill file appears incomplete or malformed. Cannot proceed without a valid lint workflow definition."
3. **Confirm `llmmem/mem/index.md` exists** - if not found, respond with: "No mem found. Run `/mem-ingest` first."

**Workflow**: The skill file loaded in pre-flight check 2 is the single source of truth for the lint workflow (deterministic auto-fix checks, heuristic report-only checks, log-append rules) and for the Mem Health Report format. Follow it; do not paraphrase here and do not use any inline output format definition in place of the skill file's format.
