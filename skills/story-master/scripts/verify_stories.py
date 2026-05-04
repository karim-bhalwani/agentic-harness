"""
verify_stories.py
=================
Validate a STORIES.md file against the §3.1 schema.

Checks column completeness, enum values, dependency integrity, H3 detail
section existence, and wave grouping consistency. Prints problems in
"problem / fix" format. Exits 0 on pass, 1 on failure.

Usage (CLI):
    python verify_stories.py --file .copilot/stories/STORIES.md

Usage (agent context):
    from skills.story_master.scripts.verify_stories import verify_stories, Problem
    problems = verify_stories(Path(".copilot/stories/STORIES.md"))
    # Empty list means PASS; each Problem has .problem and .fix attributes.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

EXPECTED_COLUMNS: list[str] = [
    "ID",
    "Title",
    "Type",
    "Wave",
    "Depends On",
    "Priority",
    "Effort",
    "Security",
    "Holdout",
    "Risk",
    "Status",
    "Owner",
]

VALID_STATUSES: frozenset[str] = frozenset(
    {"not-started", "in-progress", "in-review", "done", "blocked"}
)
VALID_TYPES: frozenset[str] = frozenset(
    {"Feature", "Enhancement", "Technical", "Spike"}
)
VALID_PRIORITIES: frozenset[str] = frozenset({"High", "Medium", "Low"})
VALID_EFFORTS: frozenset[str] = frozenset({"S", "M", "L"})
VALID_RISKS: frozenset[str] = frozenset({"Low", "Medium", "High", "Spike"})
VALID_BOOL: frozenset[str] = frozenset({"Yes", "No"})

_STORY_ID_RE = re.compile(r"^US-\d+$")
_H3_STORY_RE = re.compile(r"^###\s+(US-\d+)")
_WAVE_HEADING_RE = re.compile(r"^###\s+Wave\s+(\d+)")
_H2_RE = re.compile(r"^##\s+")
_STORY_REF_RE = re.compile(r"US-\d+")


@dataclass
class Problem:
    """A single validation failure with a suggested fix."""

    problem: str
    fix: str


def _parse_summary_table(
    lines: list[str],
) -> tuple[list[str], list[list[str]]]:
    """
    Locate the summary table by its '| ID |' header and return
    (header_cells, data_rows).

    Returns empty lists if the table is not found.
    """
    header_idx: int | None = None
    for i, line in enumerate(lines):
        if "| ID |" in line:
            header_idx = i
            break
    if header_idx is None:
        return [], []

    header_cells = [c.strip() for c in lines[header_idx].strip("|").split("|")]
    data_rows: list[list[str]] = []
    for line in lines[header_idx + 2 :]:
        stripped = line.strip()
        if not stripped.startswith("|"):
            break
        data_rows.append([c.strip() for c in stripped.strip("|").split("|")])
    return header_cells, data_rows


def verify_stories(path: Path) -> list[Problem]:
    """
    Validate a STORIES.md file against the §3.1 schema.

    Parameters
    ----------
    path:
        Path to the STORIES.md file to validate.

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
                fix="Run scaffold_stories.py to generate a STORIES.md skeleton.",
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

    # --- Check 2: Summary table has all 12 expected columns ---
    header_cells, data_rows = _parse_summary_table(lines)
    if not header_cells:
        problems.append(
            Problem(
                problem="Summary table header not found. Expected a row containing '| ID |'.",
                fix="Add the Summary Table section with the full 12-column header per §3.1.",
            )
        )
    else:
        for col in EXPECTED_COLUMNS:
            if col not in header_cells:
                problems.append(
                    Problem(
                        problem=f"Summary table is missing column: '{col}'.",
                        fix=f"Add '{col}' to the summary table header row.",
                    )
                )

    # Build column index map for later checks
    col_index: dict[str, int] = {col: i for i, col in enumerate(EXPECTED_COLUMNS)}

    # --- Checks 3-9: Validate enum fields per data row ---
    all_ids: set[str] = set()
    story_deps: dict[str, list[str]] = {}

    for row in data_rows:
        if len(row) < len(EXPECTED_COLUMNS):
            continue
        story_id = row[col_index["ID"]]
        if not story_id or story_id == "-" or not _STORY_ID_RE.match(story_id):
            continue
        all_ids.add(story_id)

        def _check_enum(
            field_name: str,
            valid_set: frozenset[str],
            sid: str = story_id,
        ) -> None:
            idx = col_index.get(field_name, -1)
            if idx < 0 or idx >= len(row):
                return
            val = row[idx]
            if val and val not in valid_set:
                problems.append(
                    Problem(
                        problem=f"Story {sid}: '{field_name}' has invalid value '{val}'.",
                        fix=(
                            f"Set '{field_name}' to one of: "
                            f"{', '.join(sorted(valid_set))}."
                        ),
                    )
                )

        _check_enum("Status", VALID_STATUSES)
        _check_enum("Type", VALID_TYPES)
        _check_enum("Priority", VALID_PRIORITIES)
        _check_enum("Effort", VALID_EFFORTS)
        _check_enum("Risk", VALID_RISKS)
        _check_enum("Security", VALID_BOOL)
        _check_enum("Holdout", VALID_BOOL)

        # Collect dependency references
        dep_idx = col_index.get("Depends On", -1)
        if dep_idx >= 0 and dep_idx < len(row):
            dep_cell = row[dep_idx].strip()
            if dep_cell and dep_cell != "-":
                deps = [d.strip() for d in dep_cell.split(",") if d.strip()]
                if deps:
                    story_deps[story_id] = deps

    # --- Check 10: All Depends On IDs exist in the table ---
    for story_id, deps in story_deps.items():
        for dep in deps:
            if dep not in all_ids:
                problems.append(
                    Problem(
                        problem=(
                            f"Story {story_id}: Depends On references '{dep}' "
                            "which does not exist in the Summary Table."
                        ),
                        fix=(
                            f"Add a '{dep}' row to the Summary Table, "
                            "or correct the dependency value."
                        ),
                    )
                )

    # --- Check 11: Every story ID has a corresponding H3 detail section ---
    h3_story_ids: set[str] = set()
    for line in lines:
        m = _H3_STORY_RE.match(line.strip())
        if m:
            h3_story_ids.add(m.group(1))

    for story_id in all_ids:
        if story_id not in h3_story_ids:
            problems.append(
                Problem(
                    problem=(
                        f"Story {story_id}: No H3 detail section found "
                        f"(expected '### {story_id}')."
                    ),
                    fix=(
                        f"Add a '### {story_id} · <title> · Wave N' section "
                        "under '## User Stories'."
                    ),
                )
            )

    # --- Check 12: Wave grouping consistency ---
    # Build expected wave per story from summary table
    wave_idx = col_index.get("Wave", -1)
    story_wave_expected: dict[str, str] = {}
    for row in data_rows:
        if len(row) < len(EXPECTED_COLUMNS):
            continue
        story_id = row[col_index["ID"]]
        if not story_id or not _STORY_ID_RE.match(story_id):
            continue
        if wave_idx >= 0 and wave_idx < len(row):
            story_wave_expected[story_id] = row[wave_idx].strip()

    # Map story IDs to the wave heading they appear under
    current_wave: str | None = None
    story_wave_listed: dict[str, str] = {}
    for line in lines:
        wave_m = _WAVE_HEADING_RE.match(line.strip())
        if wave_m:
            current_wave = wave_m.group(1)
            continue
        if _H2_RE.match(line.strip()):
            current_wave = None
            continue
        if current_wave is not None:
            for sid_m in _STORY_REF_RE.finditer(line):
                sid = sid_m.group(0)
                if sid in all_ids and sid not in story_wave_listed:
                    story_wave_listed[sid] = current_wave

    for story_id, expected_wave in story_wave_expected.items():
        if not expected_wave or expected_wave == _TODO_marker():
            continue
        listed_wave = story_wave_listed.get(story_id)
        if listed_wave is None:
            problems.append(
                Problem(
                    problem=(
                        f"Story {story_id}: Table says Wave {expected_wave} "
                        "but the story is not listed under any Wave heading "
                        "in 'Execution Waves'."
                    ),
                    fix=(
                        f"Add '{story_id}' to the '### Wave {expected_wave}' "
                        "section under '## Execution Waves'."
                    ),
                )
            )
        elif listed_wave != expected_wave:
            problems.append(
                Problem(
                    problem=(
                        f"Story {story_id}: Table says Wave {expected_wave} "
                        f"but it is listed under Wave {listed_wave} in "
                        "'Execution Waves'."
                    ),
                    fix=(
                        f"Move '{story_id}' from '### Wave {listed_wave}' to "
                        f"'### Wave {expected_wave}', or update the table."
                    ),
                )
            )

    return problems


def _TODO_marker() -> str:
    """Return the TODO placeholder string (avoids false self-matches)."""
    return "TODO"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate a STORIES.md file against the §3.1 schema"
    )
    parser.add_argument(
        "--file",
        default=".copilot/stories/STORIES.md",
        help="Path to STORIES.md to validate (default: .copilot/stories/STORIES.md)",
    )
    args = parser.parse_args()

    problems = verify_stories(Path(args.file))

    if not problems:
        print(f"PASS: {args.file} conforms to the §3.1 STORIES.md schema.")
        sys.exit(0)

    print(f"FAIL: {len(problems)} problem(s) found in {args.file}:\n")
    for i, p in enumerate(problems, start=1):
        print(f"  [{i}] problem: {p.problem}")
        print(f"       fix:     {p.fix}")
        print()
    sys.exit(1)


if __name__ == "__main__":
    main()
