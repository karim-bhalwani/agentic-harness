"""
verify_review.py
================
Verify .copilot/artifacts/review-report.md exists and contains real review
content (not empty, not a stub). Run this gate from the Release Manager
BEFORE deciding on PASS/CONDITIONAL/BLOCKED.

Guardian itself cannot write files (no editFiles tool); the orchestrating agent
or user persists the report. This verifier is the safety net to ensure the
report actually landed before downstream gating runs.

Strengthened from single-token
presence check to multi-section + Gate Status semantic validation so that
a token-rich placeholder or fabricated artifact cannot satisfy this gate.

Usage (release-manager / orchestrator context):
    uv run ~/.copilot/skills/guardian/scripts/verify_review.py

Exit codes:
    0 = Report present and non-empty
    1 = Report missing or stub-like
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

MIN_CONTENT_LENGTH = 600

# Real review reports must contain proper markdown headings (## or ###) for
# these section names. At least 3 of these must be present as actual headings.
REQUIRED_SECTION_PATTERNS: list[str] = [
    r"^#{2,3}\s+Findings",
    r"^#{2,3}\s+Summary",
    r"^#{2,3}\s+Strengths",
    r"^#{2,3}\s+Gate\s+Status",
]

# At least one severity token must appear anywhere in the report body.
SEVERITY_TOKENS: list[str] = ["Critical", "High", "Medium", "Low"]

# Gate Status line must declare one of these values (case-insensitive).
VALID_GATE_STATUSES: list[str] = ["pass", "needs work", "fail", "conditional", "blocked"]

# Pattern to locate the Gate Status line: "Gate Status: <value>" or a table cell.
# Uses [:\|] (not \s) to prevent the match from jumping across newlines to the
# next "Gate Status: <value>" occurrence.
_GATE_STATUS_LINE_RE = re.compile(
    r"gate\s+status\s*[:\|]\s*([^\n\|]+)",
    re.IGNORECASE | re.MULTILINE,
)


def _find_present_sections(content: str) -> list[str]:
    """Return the REQUIRED_SECTION_PATTERNS that match as real headings."""
    present: list[str] = []
    for pattern in REQUIRED_SECTION_PATTERNS:
        if re.search(pattern, content, re.IGNORECASE | re.MULTILINE):
            present.append(pattern)
    return present


def _find_gate_status(content: str) -> str | None:
    """Return the normalised gate status value, or None if absent/unparseable."""
    match = _GATE_STATUS_LINE_RE.search(content)
    if not match:
        return None
    return match.group(1).strip().rstrip("|").strip()


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

    failed = False

    if not path.exists():
        print("[x] FAILED: review-report.md does not exist.")
        print("   The orchestrating agent or user must persist Guardian's output.")
        sys.exit(1)

    content = path.read_text(encoding="utf-8")

    # --- M-03 check 1: minimum length ---
    if len(content) < MIN_CONTENT_LENGTH:
        print(f"[x] FAILED: review-report.md is too short (<{MIN_CONTENT_LENGTH} chars).")
        print("   Likely a stub or truncated paste. Re-run Guardian or persist the full report.")
        failed = True

    # --- M-03 check 2: require ≥3 real markdown section headings ---
    present_sections = _find_present_sections(content)
    if len(present_sections) < 3:  # noqa: PLR2004
        print(
            f"[x] FAILED: only {len(present_sections)} of the required section headings found "
            f"(need ≥3 of: Findings, Summary, Strengths, Gate Status)."
        )
        print(f"   Found: {present_sections or 'none'}")
        print("   Headings must be real ## or ### markdown headings, not bare words.")
        failed = True

    # --- M-03 check 3: at least one severity token ---
    matched_severities = [t for t in SEVERITY_TOKENS if t in content]
    if not matched_severities:
        print(f"[x] FAILED: no severity token found. Expected at least one of: {SEVERITY_TOKENS}")
        failed = True

    # --- M-03 check 4: Gate Status line with valid value ---
    gate_status_raw = _find_gate_status(content)
    if gate_status_raw is None:
        print("[x] FAILED: no 'Gate Status' line found in the report.")
        print(f"   Add a line like: Gate Status: {' | '.join(VALID_GATE_STATUSES)}")
        failed = True
    else:
        normalised = gate_status_raw.lower()
        if not any(normalised == v for v in VALID_GATE_STATUSES):
            print(f"[x] FAILED: Gate Status value '{gate_status_raw}' is not valid.")
            print(f"   Must be one of (case-insensitive): {VALID_GATE_STATUSES}")
            failed = True

    if failed:
        sys.exit(1)

    print(
        f"[+] PASSED: review report present ({len(content)} chars, "
        f"{len(present_sections)} sections, gate: {gate_status_raw})."
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
