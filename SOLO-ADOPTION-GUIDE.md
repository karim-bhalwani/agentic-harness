# Solo Adoption Guide

> Version: 8.0 | Updated: 2026-05-04

For solo developers using the Mega Minions pipeline. Skips team coordination overhead (file locks, wave parallelism, PR-title CI) while keeping all quality gates.

For setup see [USER-GUIDE.md](USER-GUIDE.md). For the full pipeline see [MEGA-MINIONS.md](MEGA-MINIONS.md).

---

## Config

Create `.copilot/config.yml` (this is the default if the file does not exist):

```yaml
v8_plan_phase_enabled: true
team_mode: solo
```

Solo mode **disables**: `STORIES.md` file lock, wave parallelism (`STORY_ID`), branch naming check, PR-title CI enforcement.

Solo mode **keeps**: plan-checker loop, Plan Preview gate, SPEC directive traceability, test infra audit (T-00), quality-gate hook.

---

## The Loop

1. **Architect** produces `SPEC.md`. Approve it.
2. Invoke **story-master** → review `STORIES.md` → approve at Gate 1.
3. Invoke **story-planner** (reads `.active-story` automatically) → confirm Plan Preview → approve at Gate 2.
4. Hand off to **Senior Developer / Data Engineer / AI Engineer** → walks `US-{id}-PLAN.md` task list.
5. **Guardian** reviews → **Release Manager** ships → clicks `[ Close Story ]`.
6. close-story stamps `STORIES.md`, advances `.active-story` to the next story. Repeat from step 3.

Human gate time per story: ~10–15 minutes.

---

## Plan Phase vs Build Direct

| Situation | Path |
|-----------|------|
| 3+ deliverables or shared dependencies | Plan Phase |
| 1–2 deliverables, no shared deps | Build Direct |
| Ad-hoc spike or exploratory work | Build Direct via `/feature-plan` |
| Story touches 3+ files and takes more than a day | Plan Phase |

---

## Sub-Day Stories

`Effort: S` stories go through the same loop  -  they just complete faster. Planning typically finishes clean on the first plan-checker iteration. You can complete a full story (plan → build → close) in a single session.
