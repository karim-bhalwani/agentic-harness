"""
verify_validation.py
====================
Validate a US-{id}-VALIDATION.md file against the §3.4 schema.

Checks header story ID, Task Validation Matrix column set, AC Coverage Map
presence, Plan-Checker History column set, and enum values for Status and
Infrastructure cells. Prints problems in "problem / fix" format. Exits 0 on
pass, 1 on failure.

Usage (CLI):
    python verify_validation.py --file .copilot/stories/US-01-VALIDATION.md

Usage (agent context):
    from skills.story_planner.scripts.verify_validation import (
        verify_validation,
        Problem,
    )
    problems = verify_validation(Path(".copilot/stories/US-01-VALIDATION.md"))
    # Empty list means PASS.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

TASK_MATRIX_COLUMNS: list[str] = [
    "Task",
    "Validate Command",
    "Test File",
    "Infrastructure",
    "Status",
]

PLAN_CHECKER_COLUMNS: list[str] = [
    "Iteration",
    "(a) AC coverage",
    "(b) SPEC directives",
    "(c) Dependency boundary",
    "(d) Atomicity",
    "Rewrites Triggered",
]

VALID_STATUSES: frozenset[str] = frozenset({"-", "PASS", "FAIL"})
VALID_INFRASTRUCTURE: frozenset[str] = frozenset({"EXISTS", "NEEDS-T-00"})

_STORY_HEADER_RE = re.compile(r"\*\*Story:\*\*\s+US-\d+")
_VALIDATION_TITLE_RE = re.compile(r"^#\s+Validation Map:")


@dataclass
class Problem:
    """A single validation failure with a suggested fix."""

    problem: str
    fix: str


def _find_table_header(lines: list[str], column_name: str) -> int | None:
    """
    Return the line index of the first table header row that contains
    column_name surrounded by pipe separators, or None if not found.
    """
    pattern = re.compile(r"\|\s*" + re.escape(column_name) + r"\s*\|")
    for i, line in enumerate(lines):
        if pattern.search(line):
            return i
    return None


def _parse_header_cells(line: str) -> list[str]:
    """Extract trimmed cell values from a markdown table header line."""
    return [c.strip() for c in line.strip("|").split("|")]


def _parse_data_rows(lines: list[str], header_idx: int) -> list[list[str]]:
    """
    Return data rows starting two lines after header_idx (skipping separator).
    Stops at the first line that does not start with '|'.
    """
    rows: list[list[str]] = []
    for line in lines[header_idx + 2 :]:
        if not line.strip().startswith("|"):
            break
        rows.append([c.strip() for c in line.strip("|").split("|")])
    return rows


def verify_validation(path: Path) -> list[Problem]:
    """
    Validate a US-{id}-VALIDATION.md file against the §3.4 schema.

    Parameters
    ----------
    path:
        Path to the validation map file to validate.

    Returns
    -------
    list[Problem]
        Empty list means all checks passed; each item describes a failure.
    """
    problems: list[Problem] = []

    # --- Check 1: File exists and is readable ---
    if not path.exists():
        problems.append(
            Problem(
                problem=f"File not found: {path}",
                fix=(
                    "Run scaffold_validation.py --story-id <ID> to generate "
                    "a validation skeleton."
                ),
            )
        )
        return problems

    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        problems.append(
            Problem(
                problem=f"Cannot read {path}: {exc}",
                fix="Check file permissions.",
            )
        )
        return problems

    lines = text.splitlines()

    # --- Check 2: Header contains story ID ---
    has_story_header = any(
        _STORY_HEADER_RE.search(line) or _VALIDATION_TITLE_RE.match(line.strip())
        for line in lines
    )
    if not has_story_header:
        problems.append(
            Problem(
                problem=(
                    "File header does not contain a story ID. "
                    "Expected '**Story:** US-NN' or '# Validation Map:' title."
                ),
                fix="Add '**Story:** US-XX' to the file header.",
            )
        )

    # --- Check 3: Task Validation Matrix has all 5 expected columns ---
    matrix_idx = _find_table_header(lines, "Validate Command")
    if matrix_idx is None:
        problems.append(
            Problem(
                problem="Task Validation Matrix table not found.",
                fix=(
                    "Add a '## Task Validation Matrix' section with the "
                    "5-column table (Task, Validate Command, Test File, "
                    "Infrastructure, Status)."
                ),
            )
        )
    else:
        header_cells = _parse_header_cells(lines[matrix_idx])
        for col in TASK_MATRIX_COLUMNS:
            if col not in header_cells:
                problems.append(
                    Problem(
                        problem=(f"Task Validation Matrix is missing column: '{col}'."),
                        fix=f"Add '{col}' to the Task Validation Matrix header row.",
                    )
                )

        # Check Status and Infrastructure enum values in data rows
        data_rows = _parse_data_rows(lines, matrix_idx)
        col_map = {col: i for i, col in enumerate(header_cells)}
        status_idx = col_map.get("Status", -1)
        infra_idx = col_map.get("Infrastructure", -1)

        for row in data_rows:
            if not any(cell.strip() for cell in row):
                continue

            if status_idx >= 0 and status_idx < len(row):
                val = row[status_idx].strip()
                if val and val not in VALID_STATUSES and "TODO" not in val:
                    problems.append(
                        Problem(
                            problem=(
                                f"Task Validation Matrix has invalid Status "
                                f"value: '{val}'."
                            ),
                            fix=(
                                f"Set Status to one of: "
                                f"{', '.join(sorted(VALID_STATUSES))}."
                            ),
                        )
                    )

            if infra_idx >= 0 and infra_idx < len(row):
                val = row[infra_idx].strip()
                if val and val not in VALID_INFRASTRUCTURE and "TODO" not in val:
                    problems.append(
                        Problem(
                            problem=(
                                f"Task Validation Matrix has invalid "
                                f"Infrastructure value: '{val}'."
                            ),
                            fix=(
                                f"Set Infrastructure to one of: "
                                f"{', '.join(sorted(VALID_INFRASTRUCTURE))}."
                            ),
                        )
                    )

    # --- Check 4: AC Coverage Map section is present ---
    has_ac_map = any("AC Coverage Map" in line for line in lines)
    if not has_ac_map:
        problems.append(
            Problem(
                problem="AC Coverage Map section not found.",
                fix=(
                    "Add a '## AC Coverage Map' section with columns: "
                    "AC, Covered By Task(s), Validate Command."
                ),
            )
        )

    # --- Check 5: Plan-Checker History table has all 6 expected columns ---
    checker_idx = _find_table_header(lines, "Iteration")
    if checker_idx is None:
        problems.append(
            Problem(
                problem="Plan-Checker History table not found.",
                fix=(
                    "Add a '## Plan-Checker History' section with the "
                    "6-column table (Iteration, (a) AC coverage, "
                    "(b) SPEC directives, (c) Dependency boundary, "
                    "(d) Atomicity, Rewrites Triggered)."
                ),
            )
        )
    else:
        header_cells = _parse_header_cells(lines[checker_idx])
        for col in PLAN_CHECKER_COLUMNS:
            if col not in header_cells:
                problems.append(
                    Problem(
                        problem=(
                            f"Plan-Checker History table is missing column: '{col}'."
                        ),
                        fix=f"Add '{col}' to the Plan-Checker History header row.",
                    )
                )

    return problems


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate a US-{id}-VALIDATION.md file against the §3.4 schema"
    )
    parser.add_argument(
        "--file",
        required=True,
        help="Path to the validation map file to validate",
    )
    args = parser.parse_args()

    problems = verify_validation(Path(args.file))

    if not problems:
        print(f"PASS: {args.file} conforms to the §3.4 VALIDATION schema.")
        sys.exit(0)

    print(f"FAIL: {len(problems)} problem(s) found in {args.file}:\n")
    for i, p in enumerate(problems, start=1):
        print(f"  [{i}] problem: {p.problem}")
        print(f"       fix:     {p.fix}")
        print()
    sys.exit(1)


if __name__ == "__main__":
    main()
