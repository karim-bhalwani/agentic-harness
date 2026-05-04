"""
verify_bible.py
===============
Verification gate: ensures all 6 Project Bible files exist and contain real content.

Run this BEFORE declaring the Project Bible complete. If any file is still a stub
or missing, the agent MUST NOT proceed to the Commit phase.

Usage (agent context):
    uv run skills/context-engineer/scripts/verify_bible.py --output-dir .copilot/context

Exit codes:
    0 = All files present and filled
    1 = One or more files missing or still stubs
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REQUIRED_FILES = [
    "PROJECT_CONTEXT.md",
    "ARCHITECTURE.md",
    "CODEBASE_PATTERNS.md",
    "AGENT_GUIDE.md",
    "DECISIONS.md",
    "ORIENTATION.md",
]

# If a file contains this marker, it's still a stub
STUB_MARKER = "**Status:** STUB"

# Minimum content length (bytes) to consider a file "filled" beyond the stub template
MIN_CONTENT_LENGTH = 500


def verify_bible(output_dir: Path) -> tuple[list[str], list[str], list[str]]:
    """
    Verify all Project Bible files exist and contain real content.

    Returns:
        (passed, stubs, missing) - lists of filenames in each category
    """
    passed: list[str] = []
    stubs: list[str] = []
    missing: list[str] = []

    for filename in REQUIRED_FILES:
        filepath = output_dir / filename
        if not filepath.exists():
            missing.append(filename)
            continue

        content = filepath.read_text(encoding="utf-8")

        if STUB_MARKER in content:
            stubs.append(filename)
        elif len(content) < MIN_CONTENT_LENGTH:
            stubs.append(filename)
        else:
            passed.append(filename)

    return passed, stubs, missing


def main() -> None:
    parser = argparse.ArgumentParser(description="Verify Project Bible completeness")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(".copilot/context"),
        help="Directory containing Bible files (default: .copilot/context)",
    )
    args = parser.parse_args()

    if not args.output_dir.exists():
        print(f"❌ Output directory does not exist: {args.output_dir.resolve()}")
        print("   Run scaffold_bible.py first to create the directory and stub files.")
        sys.exit(1)

    passed, stubs, missing = verify_bible(args.output_dir)

    print(f"Project Bible Verification: {args.output_dir.resolve()}")
    print(f"{'=' * 60}")

    if passed:
        print(f"\n✅ Complete ({len(passed)}/{len(REQUIRED_FILES)}):")
        for f in passed:
            print(f"   ✓ {f}")

    if stubs:
        print(f"\n⚠️  Still stubs ({len(stubs)}/{len(REQUIRED_FILES)}):")
        for f in stubs:
            print(
                f"   ⊘ {f} - contains stub marker or insufficient content (<{MIN_CONTENT_LENGTH} bytes)"
            )

    if missing:
        print(f"\n❌ Missing ({len(missing)}/{len(REQUIRED_FILES)}):")
        for f in missing:
            print(f"   ✗ {f}")

    print(f"\n{'=' * 60}")
    total = len(REQUIRED_FILES)
    if len(passed) == total:
        print(f"✅ PASSED: All {total} Project Bible files are complete.")
        sys.exit(0)
    else:
        incomplete = len(stubs) + len(missing)
        print(f"❌ FAILED: {incomplete} of {total} files are incomplete or missing.")
        print(
            "   The agent MUST fill all files before declaring the Project Bible complete."
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
