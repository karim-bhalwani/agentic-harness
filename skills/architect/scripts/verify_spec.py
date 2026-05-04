"""
verify_spec.py
==============
Verification gate: ensures architect's SPEC.md and HOLDOUT.md exist and contain
real content (not the scaffolded stub).

Run this BEFORE handing off to an implementation agent. If either file is still
a stub or missing, the agent MUST NOT proceed to handoff.

Usage (agent context):
    uv run skills/architect/scripts/verify_spec.py
    uv run skills/architect/scripts/verify_spec.py --specs-dir .copilot/specs --holdout-dir .copilot/holdout

Exit codes:
    0 = Both files present and filled
    1 = One or more files missing or still stubs
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

STUB_MARKER = "**Status:** STUB"
MIN_CONTENT_LENGTH = 800


def verify_one(filepath: Path) -> str:
    """Return one of: 'passed', 'stub', 'missing'."""
    if not filepath.exists():
        return "missing"
    content = filepath.read_text(encoding="utf-8")
    if STUB_MARKER in content:
        return "stub"
    if len(content) < MIN_CONTENT_LENGTH:
        return "stub"
    return "passed"


def main() -> None:
    parser = argparse.ArgumentParser(description="Verify architect spec artifacts")
    parser.add_argument(
        "--specs-dir",
        type=Path,
        default=Path(".copilot/specs"),
        help="Directory containing SPEC.md (default: .copilot/specs)",
    )
    parser.add_argument(
        "--holdout-dir",
        type=Path,
        default=Path(".copilot/holdout"),
        help="Directory containing HOLDOUT.md (default: .copilot/holdout)",
    )
    args = parser.parse_args()

    spec_path = args.specs_dir / "SPEC.md"
    holdout_path = args.holdout_dir / "HOLDOUT.md"

    results = {
        spec_path: verify_one(spec_path),
        holdout_path: verify_one(holdout_path),
    }

    print("Architect Spec Verification")
    print("=" * 60)
    for path, status in results.items():
        symbol = {"passed": "+", "stub": "o", "missing": "x"}[status]
        print(f"  [{symbol}] {path}: {status}")

    incomplete = [p for p, s in results.items() if s != "passed"]
    print("=" * 60)
    if not incomplete:
        print("PASSED: SPEC.md and HOLDOUT.md are complete.")
        sys.exit(0)
    else:
        print(f"FAILED: {len(incomplete)} of 2 files are incomplete or missing.")
        print(
            "   The architect MUST fill all files before handing off to implementation."
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
