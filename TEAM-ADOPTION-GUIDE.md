# Team Adoption Guide

> Version: 8.0 | Updated: 2026-05-04

For 3–5 person teams working parallel stories. Adds wave coordination, branch/PR conventions, concurrency safety, and CI enforcement on top of the solo flow.

For setup see [USER-GUIDE.md](USER-GUIDE.md). For solo mode see [SOLO-ADOPTION-GUIDE.md](SOLO-ADOPTION-GUIDE.md). For the full pipeline see [MEGA-MINIONS.md](MEGA-MINIONS.md).

---

## Config

```yaml
v8_plan_phase_enabled: true
team_mode: team
```

Team mode **enables**: `STORIES.md` file lock (concurrency safety), `STORY_ID` env var per shell, branch naming check, PR-title CI enforcement.

---

## Wave Parallelism

Stories in the same wave have no shared file dependencies. Each developer sets `STORY_ID` in their shell before starting:

```powershell
$env:STORY_ID = "US-01"   # Developer A
$env:STORY_ID = "US-03"   # Developer B (different shell)
```

`STORY_ID` takes precedence over `.active-story`. Do not start Wave 2 stories until all Wave 1 blockers are stamped `done` in `STORIES.md`.

---

## Branch and PR Conventions

| Thing | Format |
|-------|--------|
| Branch | `story/US-{id}-{kebab-slug}` |
| PR title | `US-{id}: {story title}` |
| PR body | `Closes US-{id}`, link to `reports/US-{id}-report.md`, deviation summary |

The CI script (`ci/check-story-completeness.py`) parses the PR title to extract the story ID and enforces task completion, report presence, and validation status.

---

## STORIES.md Concurrency

close-story uses a file lock (`.copilot/stories/.STORIES.md.lock`) to prevent concurrent writes. The lock is auto-cleared on stale PIDs. If a lock is stuck, delete it manually:

```powershell
Remove-Item .copilot/stories/.STORIES.md.lock
```

Never commit the lock file  -  it is in `.gitignore`.

---

## Onboarding a New Member

1. Read [MEGA-MINIONS.md](MEGA-MINIONS.md)  -  15-minute pipeline overview.
2. Follow [USER-GUIDE.md](USER-GUIDE.md)  -  install prompts, skills, hooks.
3. Confirm `.copilot/config.yml` has `team_mode: team`.
4. Run `/start-here`  -  tells you exactly which agent to invoke next.
5. Get your story assignment from the tech lead and set `$env:STORY_ID`.

---

## Anti-Patterns

- **Committing `.STORIES.md.lock`**  -  blocks every developer until manually deleted from remote.
- **Starting Wave 2 before Wave 1 blockers are `done`**  -  story-planner enforces this; do not bypass it with `/feature-plan`.
- **Merging Coupled Pairs out of order**  -  CI does not enforce merge sequence; treat the Coupled Pairs table in `STORIES.md` as binding.
- **Forgetting `STORY_ID` in a new shell**  -  inherits parent shell value; both sessions check the same story. Always set explicitly.
- **Running close-story before Guardian and Release Manager**  -  causes "report missing" block. Required sequence: BUILD → Guardian → Release Manager → `[ Close Story ]`.
