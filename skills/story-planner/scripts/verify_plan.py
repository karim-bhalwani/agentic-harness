"""
verify_plan.py
==============
Validate a US-{id}-PLAN.md file against the §3.2 schema.

Checks required H2 sections, acceptance criteria table, implementation task
format, validate command presence, and pattern reference style. Prints
problems in "problem / fix" format. Exits 0 on pass, 1 on failure.

Usage (CLI):
    python verify_plan.py --file .copilot/stories/US-01-PLAN.md

Usage (agent context):
    from skills.story_planner.scripts.verify_plan import verify_plan, Problem
    problems = verify_plan(Path(".copilot/stories/US-01-PLAN.md"))
    # Empty list means PASS.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REQUIRED_H2_SECTIONS: list[str] = [
    "Spec References",
    "Acceptance Criteria",
    "Out of Scope",
    "Implementation Tasks",
    "Patterns to Follow",
    "Files to Create",
    "Files to Modify",
    "Effort Estimate",
    "Notes for Builder",
    "Deviations from Plan",
]

_TASK_LINE_RE = re.compile(r"^- \[[ x]\]\s+T-\d+")
_VALIDATE_RE = re.compile(r"\*\*Validate:\*\*")
_H2_RE = re.compile(r"^##\s+(.+)$")
_H3_RE = re.compile(r"^###\s+")
_FILE_LINE_REF_RE = re.compile(r"\w[\w./\-]+\.py:\d+")
_GREENFIELD_RE = re.compile(r"no analogous code exists", re.IGNORECASE)
_PATTERNS_H2_RE = re.compile(r"^##\s+Patterns to Follow")
_NEXT_H2_RE = re.compile(r"^##\s+")


@dataclass
class Problem:
    """A single validation failure with a suggested fix."""

    problem: str
    fix: str


def verify_plan(path: Path) -> list[Problem]:
    """
    Validate a US-{id}-PLAN.md file against the §3.2 schema.

    Parameters
    ----------
    path:
        Path to the plan file to validate.

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
                fix="Run scaffold_plan.py --story-id <ID> to generate a plan skeleton.",
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

    # --- Check 2: All required H2 sections are present ---
    h2_headings: set[str] = set()
    for line in lines:
        m = _H2_RE.match(line.strip())
        if m:
            h2_headings.add(m.group(1).strip())

    for section in REQUIRED_H2_SECTIONS:
        # Partial match: "Acceptance Criteria" matches "Acceptance Criteria (replaces...)"
        if not any(section in heading for heading in h2_headings):
            problems.append(
                Problem(
                    problem=f"Required H2 section '{section}' not found.",
                    fix=f"Add a '## {section}' heading to the plan file.",
                )
            )

    # --- Check 3: Acceptance Criteria table has at least one AC-1 row ---
    if not any("AC-1" in line for line in lines):
        problems.append(
            Problem(
                problem="Acceptance Criteria table has no AC-1 row.",
                fix=("Add at least one '| AC-1 | GIVEN ... WHEN ... THEN ... |' row to the Acceptance Criteria table."),
            )
        )

    # --- Check 4: Implementation Tasks has at least one task line ---
    task_line_indices: list[int] = [i for i, line in enumerate(lines) if _TASK_LINE_RE.match(line.strip())]
    if not task_line_indices:
        problems.append(
            Problem(
                problem=("Implementation Tasks section has no task lines matching '- [ ] T-NN' or '- [x] T-NN'."),
                fix=("Add at least one task using the format: '- [ ] T-01 · <description>'."),
            )
        )

    # --- Check 5: Each task has a **Validate:** line nested below it ---
    for task_idx in task_line_indices:
        has_validate = False
        # Scan up to 6 lines ahead; stop early on a new task or heading
        for j in range(task_idx + 1, min(task_idx + 7, len(lines))):
            if _VALIDATE_RE.search(lines[j]):
                has_validate = True
                break
            if _TASK_LINE_RE.match(lines[j].strip()):
                break
            if _H3_RE.match(lines[j].strip()) or _H2_RE.match(lines[j].strip()):
                break
        if not has_validate:
            snippet = lines[task_idx].strip()[:60]
            problems.append(
                Problem(
                    problem=f"Task has no '**Validate:**' sub-item: '{snippet}'.",
                    fix=("Add '  - **Validate:** <command>' immediately below the task line."),
                )
            )

    # --- Check 6: Patterns to Follow has file:line refs or greenfield notice ---
    in_patterns = False
    patterns_content: list[str] = []
    for line in lines:
        if _PATTERNS_H2_RE.match(line.strip()):
            in_patterns = True
            continue
        if in_patterns:
            if _NEXT_H2_RE.match(line.strip()):
                in_patterns = False
                continue
            patterns_content.append(line)

    if patterns_content:
        patterns_text = "\n".join(patterns_content)
        has_file_refs = bool(_FILE_LINE_REF_RE.search(patterns_text))
        has_greenfield = bool(_GREENFIELD_RE.search(patterns_text))
        # Identify populated rows: table rows that are not header, separator, or TODO
        populated_rows = [
            line
            for line in patterns_content
            if "|" in line
            and "Pattern" not in line
            and "---" not in line
            and "TODO" not in line
            and line.strip() not in ("", "|")
        ]
        if populated_rows and not has_file_refs and not has_greenfield:
            problems.append(
                Problem(
                    problem=(
                        "Patterns to Follow table has rows but no 'file.py:N' "
                        "style references and no greenfield notice."
                    ),
                    fix=(
                        "Add 'src/module.py:N' references in the Source column, "
                        "or add the note: 'no analogous code exists yet "
                        "(greenfield story)'."
                    ),
                )
            )

    return problems


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate a US-{id}-PLAN.md file against the §3.2 schema")
    parser.add_argument(
        "--file",
        required=True,
        help="Path to the plan file to validate",
    )
    args = parser.parse_args()

    problems = verify_plan(Path(args.file))

    if not problems:
        print(f"PASS: {args.file} conforms to the §3.2 PLAN schema.")
        sys.exit(0)

    print(f"FAIL: {len(problems)} problem(s) found in {args.file}:\n")
    for i, p in enumerate(problems, start=1):
        print(f"  [{i}] problem: {p.problem}")
        print(f"       fix:     {p.fix}")
        print()
    sys.exit(1)


if __name__ == "__main__":
    main()
