"""
format_checklist.py
===================
Convert a plain list of tasks into a structured, atomic implementation checklist
following the concise-planning skill's output format.

Applies planning hygiene rules:
- Each item starts with a verb (Create, Update, Add, Remove, Refactor, Test, Verify)
- Items too broad are flagged for splitting
- Items that lack a file/module reference are flagged
- Output includes step count and estimated effort bucket

Usage (agent context):
    from skills.concise_planning.scripts.format_checklist import format_checklist, ChecklistItem
    items = [
        ChecklistItem("Create UserService class in src/services/user.py"),
        ChecklistItem("Add validate_email() to UserService"),
        ChecklistItem("Write unit tests for validate_email()"),
    ]
    print(format_checklist("Add email validation", items))

Usage (CLI — plain text list from stdin):
    echo "Create UserService\\nAdd validate_email\\nWrite tests" | python format_checklist.py --goal "Add email validation"

Usage (CLI — from file):
    python format_checklist.py --goal "Add email validation" --input tasks.txt
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from datetime import date
from typing import Optional

# Regex to strip markdown list prefixes and checkbox tokens before task text
_LIST_PREFIX = re.compile(r"^[-*]\s*(?:\[[ xX]\]\s*)?")


# Verbs that indicate well-formed atomic tasks
_ACTION_VERBS = {
    "create",
    "add",
    "update",
    "remove",
    "delete",
    "refactor",
    "extract",
    "rename",
    "move",
    "test",
    "write",
    "verify",
    "validate",
    "configure",
    "install",
    "implement",
    "fix",
    "replace",
    "migrate",
    "register",
    "wire",
}

# Broad scope words that indicate a task needs splitting
_BROAD_SIGNALS = {
    "everything",
    "all",
    "entire",
    "complete",
    "full",
    "overhaul",
    "redesign",
    "rework",
    "revamp",
    "restructure",
    "refactor everything",
}

# Effort buckets by step count
_EFFORT_BUCKETS = [
    (5, "~30 min"),
    (10, "~1 h"),
    (20, "~2-3 h"),
    (40, "~half day"),
    (float("inf"), "~1+ day — consider splitting"),
]


@dataclass
class ChecklistItem:
    text: str
    file_ref: Optional[str] = None  # e.g. "src/auth/service.py"
    notes: Optional[str] = None

    def starts_with_verb(self) -> bool:
        first_word = self.text.strip().split()[0].lower().rstrip(":")
        return first_word in _ACTION_VERBS

    def is_too_broad(self) -> bool:
        lower = self.text.lower()
        return any(signal in lower for signal in _BROAD_SIGNALS)

    def rendered(self, index: int) -> tuple[str, list[str]]:
        """Return (checklist line, list of warnings)."""
        warnings: list[str] = []
        text = self.text.strip()

        if not self.starts_with_verb():
            first_word = text.split()[0]
            warnings.append(
                f"Item {index}: '{first_word}' is not an action verb. "
                f"Rewrite to start with: Create, Add, Update, Test, Verify, etc."
            )

        if self.is_too_broad():
            warnings.append(
                f"Item {index}: task appears too broad. Split into smaller atomic steps."
            )

        ref = f" `{self.file_ref}`" if self.file_ref else ""
        notes_str = f"\n   _{self.notes}_" if self.notes else ""
        line = f"- [ ] {text}{ref}{notes_str}"
        return line, warnings


def _effort_estimate(step_count: int) -> str:
    for threshold, label in _EFFORT_BUCKETS:
        if step_count <= threshold:
            return label
    return "unknown"


def format_checklist(
    goal: str,
    items: list[ChecklistItem],
    assumptions: Optional[list[str]] = None,
    risks: Optional[list[str]] = None,
) -> str:
    """
    Format a list of ChecklistItems into a structured planning checklist.

    Parameters
    ----------
    goal : str
        One-sentence description of what done looks like from the user's perspective.
    items : list[ChecklistItem]
        Ordered, atomic task items.
    assumptions : list[str], optional
        Inferred decisions made during planning.
    risks : list[str], optional
        Up to 3 risks that could derail execution.

    Returns
    -------
    str
        Formatted Markdown checklist.
    """
    lines: list[str] = []
    all_warnings: list[str] = []

    lines.append("# Implementation Plan\n")
    lines.append(f"**Goal**: {goal}\n")
    lines.append(
        f"**Date**: {date.today()} | **Steps**: {len(items)} | **Estimate**: {_effort_estimate(len(items))}\n"
    )
    lines.append("---\n")

    if assumptions:
        lines.append("## Assumptions\n")
        for i, a in enumerate(assumptions, 1):
            lines.append(f"{i}. {a}")
        lines.append("")

    lines.append("## Plan\n")
    for i, item in enumerate(items, 1):
        rendered, warnings = item.rendered(i)
        lines.append(rendered)
        all_warnings.extend(warnings)
    lines.append("")

    if risks:
        lines.append("## Risks\n")
        for risk in risks[:3]:
            lines.append(f"- ⚠️ {risk}")
        lines.append("")

    if all_warnings:
        lines.append("## Planning Warnings\n")
        lines.append(
            "> The following items need attention before this plan is ready:\n"
        )
        for w in all_warnings:
            lines.append(f"- {w}")
        lines.append("")

    lines.append("---")
    lines.append(
        "_Generated by `concise-planning/scripts/format_checklist.py`. "
        "Review and approve before handing off to `implementer`._"
    )

    return "\n".join(lines)


def _parse_plain_text(text: str) -> list[ChecklistItem]:
    """Parse newline-separated plain text into ChecklistItems."""
    return [
        ChecklistItem(_LIST_PREFIX.sub("", line.strip()).strip())
        for line in text.splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]


def main() -> None:
    import argparse
    from pathlib import Path

    parser = argparse.ArgumentParser(
        description="Format a task list into a structured checklist"
    )
    parser.add_argument("--goal", required=True, help="One-sentence goal statement")
    parser.add_argument(
        "--input", type=Path, default=None, help="Text file with one task per line"
    )
    parser.add_argument(
        "--output", type=Path, default=None, help="Write to file (default: stdout)"
    )
    args = parser.parse_args()

    if args.input:
        raw = args.input.read_text(encoding="utf-8")
    else:
        raw = sys.stdin.read()

    items = _parse_plain_text(raw)
    if not items:
        print(
            "❌ No tasks found. Provide tasks via --input file or stdin.",
            file=sys.stderr,
        )
        sys.exit(1)

    output = format_checklist(goal=args.goal, items=items)

    if args.output:
        args.output.write_text(output, encoding="utf-8")
        print(f"✅ Checklist written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
