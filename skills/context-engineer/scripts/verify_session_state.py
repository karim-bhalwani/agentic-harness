"""
verify_session_state.py
=======================
Verify .copilot/state/SESSION_STATE.md exists and contains all required
schema sections per skills/context-engineer/references/session_state_schema.md.

Usage (agent context):
    uv run ~/.copilot/skills/context-engineer/scripts/verify_session_state.py

Exit codes:
    0 = File present and schema-conformant
    1 = File missing or non-conformant
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REQUIRED_SECTIONS = [
    "## Pipeline Position",
    "## Active Task",
    "## Completed Steps",
    "## Pending Steps",
    "## Blockers",
    "## Context Pointers",
]

REQUIRED_HEADERS = [
    "**Last Updated:**",
    "**Last Agent:**",
    "**Status:**",
]


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
    missing_sections = [s for s in REQUIRED_SECTIONS if s not in content]
    missing_headers = [h for h in REQUIRED_HEADERS if h not in content]

    if not missing_sections and not missing_headers:
        # Check status is set to a valid value
        ok = any(f"**Status:** {s}" in content for s in ("active", "paused", "completed", "blocked"))
        if not ok:
            print("[o] FAILED: Status header is unset or invalid.")
            print("   Set Status to: active | paused | completed | blocked.")
            sys.exit(1)
        print("[+] PASSED: All required sections and headers present.")
        sys.exit(0)

    if missing_headers:
        print(f"[o] FAILED: missing headers: {missing_headers}")
    if missing_sections:
        print(f"[o] FAILED: missing sections: {missing_sections}")
    sys.exit(1)


if __name__ == "__main__":
    main()
