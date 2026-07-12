"""
verify_session_state.py
=======================
Verify .copilot/state/SESSION_STATE.md exists and contains all required
schema sections per skills/context-engineer/references/session_state_schema.md.

Strengthened with Context Pointers
non-emptiness check, explicit Status validity enforcement, and Active Task
description consistency check to reject stub / fabricated session states.

Usage (agent context):
    uv run ~/.copilot/skills/context-engineer/scripts/verify_session_state.py

Exit codes:
    0 = File present and schema-conformant
    1 = File missing or non-conformant
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Allow running as a standalone script: ensure the repo root (which owns the
# `tests` package) is importable regardless of the current working directory.
_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tests.contracts.schema_versions import (  # noqa: E402
    CURRENT_SCHEMA_VERSIONS,
    SUPPORTED_SCHEMA_VERSIONS,
)

_FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)

REQUIRED_SECTIONS = [
    "## Pipeline Position",
    "## Active Task",
    "## Completed Steps",
    "## Pending Steps",
    "## Blockers",
    "## Context Pointers",
    "## Context Cache",
    "## Decisions Made This Session",
    "## Notes for Next Session",
    "## Pipeline Loop",
]

REQUIRED_HEADERS = [
    "**Last Updated:**",
    "**Last Agent:**",
    "**Status:**",
]

VALID_STATUSES: list[str] = ["active", "paused", "completed", "blocked"]

# Matches a non-empty bullet line inside a section: "- <non-whitespace content>"
_BULLET_LINE_RE = re.compile(r"^\s*-\s+\S", re.MULTILINE)

# Matches the Active Task Description line: "**Description:** <value>"
_DESCRIPTION_RE = re.compile(r"\*\*Description:\*\*\s*(.*)", re.IGNORECASE)


def _extract_section_body(content: str, heading: str) -> str:
    """Return the text body between *heading* and the next ## heading (or EOF)."""
    start = content.find(heading)
    if start == -1:
        return ""
    after = content[start + len(heading) :]
    next_heading = re.search(r"^##", after, re.MULTILINE)
    if next_heading:
        return after[: next_heading.start()]
    return after


def main() -> None:
    parser = argparse.ArgumentParser(description="Verify SESSION_STATE.md")
    parser.add_argument(
        "--state-dir",
        type=Path,
        default=Path(".copilot/state"),
        help="Directory containing SESSION_STATE.md (default: .copilot/state)",
    )
    args = parser.parse_args()

    path = args.state_dir / "SESSION_STATE.md"
    print("Session State Verification")
    print("=" * 60)
    print(f"Path: {path.resolve()}")

    if not path.exists():
        print("[x] FAILED: SESSION_STATE.md does not exist.")
        print("   Run scaffold_session_state.py to create it.")
        sys.exit(1)

    content = path.read_text(encoding="utf-8")
    failed = False

    # --- Frontmatter contract (canonical machine contract) ---
    fm_match = _FRONTMATTER_RE.match(content)
    if not fm_match:
        print(
            "[x] FAILED: SESSION_STATE.md has no YAML frontmatter block."
            "\n   fix: prepend a '---\n<key>: <value>\n---' block with at least"
            " session_state_schema_version, status, and agent."
        )
        failed = True
    else:
        fm_text = fm_match.group(1)
        version_match = re.search(r"^\s*session_state_schema_version\s*:\s*(\d+)", fm_text, re.MULTILINE)
        if not version_match:
            print(
                "[x] FAILED: frontmatter is missing 'session_state_schema_version'."
                "\n   fix: add 'session_state_schema_version: "
                f"{CURRENT_SCHEMA_VERSIONS['SESSION_STATE.md']}' to the frontmatter."
            )
            failed = True
        else:
            version = int(version_match.group(1))
            if version not in SUPPORTED_SCHEMA_VERSIONS["SESSION_STATE.md"]:
                print(
                    f"[x] FAILED: session_state_schema_version {version} is not supported."
                    f"\n   fix: set it to one of {sorted(SUPPORTED_SCHEMA_VERSIONS['SESSION_STATE.md'])}."
                )
                failed = True

    # --- Existing checks: required sections and headers ---
    missing_sections = [s for s in REQUIRED_SECTIONS if s not in content]
    missing_headers = [h for h in REQUIRED_HEADERS if h not in content]

    if missing_sections:
        print(f"[x] FAILED: missing sections: {missing_sections}")
        failed = True
    if missing_headers:
        print(f"[x] FAILED: missing headers: {missing_headers}")
        failed = True

    # --- M-03 check 1: Status value must be valid and non-empty ---
    status_value: str | None = None
    for candidate in VALID_STATUSES:
        if f"**Status:** {candidate}" in content:
            status_value = candidate
            break
    if status_value is None:
        print("[x] FAILED: **Status:** header is missing, empty, or has an invalid value.")
        print(f"   Must be one of: {' | '.join(VALID_STATUSES)}")
        failed = True

    # --- M-03 check 2: Context Pointers section must contain at least one bullet ---
    context_body = _extract_section_body(content, "## Context Pointers")
    if context_body and not _BULLET_LINE_RE.search(context_body):
        print("[x] FAILED: ## Context Pointers section exists but contains no pointer lines.")
        print("   Add at least one '- <file or path>' entry.")
        failed = True

    # --- M-03 check 3: Active Task must have a non-empty Description line ---
    task_body = _extract_section_body(content, "## Active Task")
    if task_body:
        desc_match = _DESCRIPTION_RE.search(task_body)
        if desc_match is None:
            print("[x] FAILED: ## Active Task section has no **Description:** line.")
            print("   Add: **Description:** <what the task is>")
            failed = True
        elif not desc_match.group(1).strip():
            print("[x] FAILED: **Description:** in ## Active Task is empty.")
            print("   Provide a non-empty task description.")
            failed = True

    if failed:
        sys.exit(1)

    print(f"[+] PASSED: All required sections and headers present (status: {status_value}).")
    sys.exit(0)


if __name__ == "__main__":
    main()
