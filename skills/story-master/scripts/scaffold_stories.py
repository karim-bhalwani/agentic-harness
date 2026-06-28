"""
scaffold_stories.py
===================
Scaffold a .copilot/stories/STORIES.md skeleton matching the §3.1 schema.

Generates a fully-formed backlog template with the summary table header,
execution wave placeholder sections, coupled-pairs table, and user-stories
section. All rows are left as TODO markers for the story-master agent to fill
in. Idempotent: refuses to overwrite an existing file unless --force is passed.

Usage (CLI):
    python scaffold_stories.py --spec .copilot/specs/SPEC.md \\
        --output .copilot/stories/STORIES.md

Usage (agent context):
    from skills.story_master.scripts.scaffold_stories import scaffold_stories, StoriesConfig
    config = StoriesConfig(spec_path=".copilot/specs/SPEC.md")
    print(scaffold_stories(config))
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

_TODO = "<!-- TODO: fill in -->"


@dataclass
class StoriesConfig:
    """Configuration for STORIES.md scaffold generation."""

    spec_path: str = ".copilot/specs/SPEC.md"
    generated_date: str = field(default_factory=lambda: str(date.today()))


def scaffold_stories(config: StoriesConfig) -> str:
    """
    Generate a STORIES.md skeleton from a StoriesConfig.

    Returns
    -------
    str
        Markdown document string ready to write to STORIES.md.
    """
    return f"""# User Story Backlog

**Spec:** `{config.spec_path}`
**Generated:** {config.generated_date}
**Total stories:** {_TODO}

---

## Summary Table

| ID | Title | Type | Wave | Depends On | Priority | Effort | Security | Holdout | Risk | Status | Owner |
|----|-------|------|------|------------|----------|--------|----------|---------|------|--------|-------|

## Execution Waves

Stories in the same wave are parallel-safe to start.

### Wave 1 - Foundation

{_TODO}

### Wave 2 - Dependent on Wave 1

{_TODO}

### Wave 3 - Integration

{_TODO}

## Coupled Pairs (if any)

If two stories cannot be merged independently (e.g. schema migration + dependent service),
list them here with the mandated merge order. story-master must justify each pair.

| Pair | Reason | Merge Order |
|------|--------|-------------|
| -    | -      | -           |

## User Stories

{_TODO}
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Scaffold a STORIES.md skeleton for the story-master agent")
    parser.add_argument(
        "--spec",
        default=".copilot/specs/SPEC.md",
        help="Path to SPEC.md referenced in the backlog header (default: .copilot/specs/SPEC.md)",
    )
    parser.add_argument(
        "--output",
        default=".copilot/stories/STORIES.md",
        help="Destination file path (default: .copilot/stories/STORIES.md)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the output file if it already exists",
    )
    args = parser.parse_args()

    output_path = Path(args.output)
    if output_path.exists() and not args.force:
        print(
            f"ERROR: {output_path} already exists. Pass --force to overwrite.",
            file=sys.stderr,
        )
        sys.exit(1)

    config = StoriesConfig(spec_path=args.spec)
    content = scaffold_stories(config)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding="utf-8")
    print(f"Scaffolded: {output_path}")


if __name__ == "__main__":
    main()
