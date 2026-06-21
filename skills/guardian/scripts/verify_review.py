"""
verify_review.py
================
Verify .copilot/artifacts/review-report.md exists and contains real review
content (not empty, not a stub). Run this gate from the Release Manager
BEFORE deciding on PASS/CONDITIONAL/BLOCKED.

Guardian itself cannot write files (no editFiles tool); the orchestrating agent
or user persists the report. This verifier is the safety net to ensure the
report actually landed before downstream gating runs.

Usage (release-manager / orchestrator context):
    uv run ~/.copilot/skills/guardian/scripts/verify_review.py

Exit codes:
    0 = Report present and non-empty
    1 = Report missing or stub-like
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

MIN_CONTENT_LENGTH = 400
REQUIRED_TOKENS = [
    # Any one of these section/keyword markers indicates a real review report.
    "Findings",
    "Verdict",
    "Severity",
    "Scope",
]


def main() -> None:
    parser = argparse.ArgumentParser(description="Verify Guardian review report")
    parser.add_argument(
        "--artifacts-dir",
        type=Path,
        default=Path(".copilot/artifacts"),
        help="Directory containing review-report.md (default: .copilot/artifacts)",
    )
    args = parser.parse_args()

    path = args.artifacts_dir / "review-report.md"
    print("Guardian Review Report Verification")
    print("=" * 60)
    print(f"Path: {path.resolve()}")

    if not path.exists():
        print("[x] FAILED: review-report.md does not exist.")
        print("   The orchestrating agent or user must persist Guardian's output.")
        sys.exit(1)

    content = path.read_text(encoding="utf-8")
    if len(content) < MIN_CONTENT_LENGTH:
        print(
            f"[o] FAILED: review-report.md is too short (<{MIN_CONTENT_LENGTH} bytes)."
        )
        print(
            "   Likely a stub or truncated paste. Re-run Guardian or persist the full report."
        )
        sys.exit(1)

    matched = [t for t in REQUIRED_TOKENS if t.lower() in content.lower()]
    if not matched:
        print("[o] FAILED: review-report.md does not contain expected tokens.")
        print(f"   Expected at least one of: {REQUIRED_TOKENS}")
        sys.exit(1)

    print(
        f"[+] PASSED: review report present ({len(content)} bytes, matched tokens: {matched})."
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
