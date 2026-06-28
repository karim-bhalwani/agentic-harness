"""
scaffold_plan.py
================
Scaffold a .copilot/stories/US-{id}-PLAN.md skeleton matching the §3.2 schema.

Generates a fully-formed plan template with all required sections pre-marked
with TODO placeholders for the story-planner agent to fill in. Idempotent:
refuses to overwrite an existing file unless --force is passed.

Usage (CLI):
    python scaffold_plan.py --story-id US-01 --output-dir .copilot/stories

Usage (agent context):
    from skills.story_planner.scripts.scaffold_plan import scaffold_plan, PlanConfig
    config = PlanConfig(story_id="US-01")
    print(scaffold_plan(config))
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

_TODO = "<!-- TODO: fill in -->"


@dataclass
class PlanConfig:
    """Configuration for US-{id}-PLAN.md scaffold generation."""

    story_id: str
    generated_date: str = field(default_factory=lambda: str(date.today()))
    output_dir: str = ".copilot/stories"


def scaffold_plan(config: PlanConfig) -> str:
    """
    Generate a US-{id}-PLAN.md skeleton from a PlanConfig.

    Returns
    -------
    str
        Markdown document ready to write to US-{id}-PLAN.md.
    """
    sid = config.story_id
    sid_lower = sid.lower()
    return f"""# {sid} Plan: {_TODO}

**Story:** {sid}
**Date:** {config.generated_date}
**Author:** story-planner
**Builder:** {_TODO}
**Branch:** `story/{sid_lower}-{_TODO}`

> Story context is tracked in `.copilot/stories/.active-story` (or the `STORY_ID`
> environment variable when working multiple stories in parallel within a wave).
> The `hooks/session-context.ps1` hook warns if the active story has no plan.
> Do not duplicate story-detection logic in handoff prompts.

---

## Spec References

{_TODO}

---

## Acceptance Criteria (replaces sprint-contract for this story)

| # | Criterion | Verification |
|---|-----------|--------------|
| AC-1 | {_TODO} | {_TODO} |

---

## Out of Scope (this story)

{_TODO}

---

## Implementation Tasks

Each task has a **Validate** command - run it immediately after completing the task.
Do not move to the next task until validate passes.

- [ ] T-01 · {_TODO}
  - **Validate:** {_TODO}

---

## Patterns to Follow

> Populated by story-planner from the live codebase via the Explore subagent.
> Domain-specific scan based on story type (Feature/API: routers, service layer,
> error handling; Data pipeline: PySpark, Delta writes, DQ checks;
> AI/LLM: RAG pipeline, prompt templates, embeddings;
> Technical/refactor: test patterns + the module being refactored).
> If no analogous code exists yet (greenfield story), state that explicitly -
> do not invent file paths.

| Pattern | Source | Notes |
|---------|--------|-------|
| {_TODO} | {_TODO} | {_TODO} |

---

## Files to Create

{_TODO}

---

## Files to Modify

{_TODO}

---

## Effort Estimate

{_TODO}

---

## Notes for Builder

{_TODO}

---

## Deviations from Plan

> Builder fills this in during implementation. Document what differed from the plan
> and why. Leave blank if implementation matched the plan exactly.
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Scaffold a US-{id}-PLAN.md for the story-planner agent")
    parser.add_argument(
        "--story-id",
        required=True,
        help="Story identifier, e.g. US-01",
    )
    parser.add_argument(
        "--output-dir",
        default=".copilot/stories",
        help="Directory to write the plan file (default: .copilot/stories)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the plan file if it already exists",
    )
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_path = output_dir / f"{args.story_id}-PLAN.md"

    if output_path.exists() and not args.force:
        print(
            f"ERROR: {output_path} already exists. Pass --force to overwrite.",
            file=sys.stderr,
        )
        sys.exit(1)

    config = PlanConfig(story_id=args.story_id, output_dir=args.output_dir)
    content = scaffold_plan(config)

    output_dir.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding="utf-8")
    print(f"Scaffolded: {output_path}")


if __name__ == "__main__":
    main()
