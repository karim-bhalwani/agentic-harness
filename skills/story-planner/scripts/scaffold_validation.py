"""
scaffold_validation.py
======================
Scaffold a .copilot/stories/US-{id}-VALIDATION.md skeleton matching the §3.4
schema.

Generates a validation map template with an empty Task Validation Matrix,
AC Coverage Map, Wave-0 Requirements section, and Plan-Checker History table.
All cells are left as TODO markers for story-planner to populate after the
task list is finalized. Idempotent: refuses to overwrite unless --force is
passed.

Usage (CLI):
    python scaffold_validation.py --story-id US-01 --output-dir .copilot/stories

Usage (agent context):
    from skills.story_planner.scripts.scaffold_validation import (
        scaffold_validation,
        ValidationConfig,
    )
    config = ValidationConfig(story_id="US-01")
    print(scaffold_validation(config))
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

_TODO = "<!-- TODO: fill in -->"


@dataclass
class ValidationConfig:
    """Configuration for US-{id}-VALIDATION.md scaffold generation."""

    story_id: str
    generated_date: str = field(default_factory=lambda: str(date.today()))
    output_dir: str = ".copilot/stories"


def scaffold_validation(config: ValidationConfig) -> str:
    """
    Generate a US-{id}-VALIDATION.md skeleton from a ValidationConfig.

    Returns
    -------
    str
        Markdown document ready to write to US-{id}-VALIDATION.md.
    """
    sid = config.story_id
    return f"""# Validation Map: {sid} - {_TODO}

**Story:** {sid}
**Generated:** {config.generated_date}
**Status:** PENDING

---

## Task Validation Matrix

| Task | Validate Command | Test File | Infrastructure | Status |
|------|-----------------|-----------|----------------|--------|
| {_TODO} | {_TODO} | {_TODO} | {_TODO} | - |

---

## AC Coverage Map

| AC | Covered By Task(s) | Validate Command |
|----|-------------------|-----------------|
| {_TODO} | {_TODO} | {_TODO} |

---

## Wave-0 Requirements

{_TODO}

---

## Plan-Checker History

| Iteration | (a) AC coverage | (b) SPEC directives | (c) Dependency boundary | (d) Atomicity | Rewrites Triggered |
|-----------|-----------------|---------------------|-------------------------|---------------|--------------------|
| {_TODO} | {_TODO} | {_TODO} | {_TODO} | {_TODO} | {_TODO} |

**Final:** {_TODO}
"""


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scaffold a US-{id}-VALIDATION.md for the story-planner agent"
    )
    parser.add_argument(
        "--story-id",
        required=True,
        help="Story identifier, e.g. US-01",
    )
    parser.add_argument(
        "--output-dir",
        default=".copilot/stories",
        help="Directory to write the validation file (default: .copilot/stories)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the validation file if it already exists",
    )
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_path = output_dir / f"{args.story_id}-VALIDATION.md"

    if output_path.exists() and not args.force:
        print(
            f"ERROR: {output_path} already exists. Pass --force to overwrite.",
            file=sys.stderr,
        )
        sys.exit(1)

    config = ValidationConfig(story_id=args.story_id, output_dir=args.output_dir)
    content = scaffold_validation(config)

    output_dir.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding="utf-8")
    print(f"Scaffolded: {output_path}")


if __name__ == "__main__":
    main()
