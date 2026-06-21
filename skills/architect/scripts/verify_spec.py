"""
verify_spec.py
==============
Verification gate: ensures architect's SPEC.md and HOLDOUT.md exist and contain
real content (not the scaffolded stub).

In v9.0 this also enforces the artifact schema version contract: every spec
MUST declare ``spec_schema_version: <int>`` in its YAML frontmatter or as a
top-level ``**Spec Schema Version:** <int>`` field. Downstream consumers
(Guardian, Senior Developer, Data Engineer, AI Engineer) compare against
``SUPPORTED_SPEC_SCHEMA_VERSIONS`` and refuse to operate on unknown versions.

Run this BEFORE handing off to an implementation agent. If either file is still
a stub or missing, the agent MUST NOT proceed to handoff.

Usage (agent context):
    uv run ~/.copilot/skills/architect/scripts/verify_spec.py
    uv run ~/.copilot/skills/architect/scripts/verify_spec.py --specs-dir .copilot/specs --holdout-dir .copilot/holdout

Exit codes:
    0 = Both files present, filled, and at a supported schema version
    1 = One or more files missing, still stubs, or at an unsupported schema version
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

STUB_MARKER = "**Status:** STUB"
MIN_CONTENT_LENGTH = 800

# Artifact schema versions this verifier accepts. Bump when SPEC.md gains/loses
# a mandatory section. Downstream agents read the same constant via
# ``tests/contracts/schema_versions.py`` to keep producer and consumer in sync.
SUPPORTED_SPEC_SCHEMA_VERSIONS: set[int] = {1}
SUPPORTED_HOLDOUT_SCHEMA_VERSIONS: set[int] = {1}

_FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
_FM_SCHEMA_RE = re.compile(
    r"^\s*(?P<field>spec_schema_version|holdout_schema_version)\s*:\s*[\"']?(?P<val>\d+)[\"']?\s*$",
    re.MULTILINE,
)
_BODY_SCHEMA_RE = re.compile(
    r"\*\*(?P<label>Spec Schema Version|Holdout Schema Version)\*\*\s*:\s*(?P<val>\d+)",
    re.IGNORECASE,
)


def _extract_schema_version(content: str) -> int | None:
    """Return the declared schema version, preferring frontmatter, else body."""
    fm = _FRONTMATTER_RE.match(content)
    if fm:
        m = _FM_SCHEMA_RE.search(fm.group(1))
        if m:
            return int(m.group("val"))
    m = _BODY_SCHEMA_RE.search(content)
    if m:
        return int(m.group("val"))
    return None


def verify_one(filepath: Path, supported: set[int]) -> tuple[str, str]:
    """Return (status, detail)."""
    if not filepath.exists():
        return "missing", "file not found"
    content = filepath.read_text(encoding="utf-8")
    if STUB_MARKER in content:
        return "stub", "still contains scaffolded stub marker"
    if len(content) < MIN_CONTENT_LENGTH:
        return "stub", f"content shorter than {MIN_CONTENT_LENGTH} chars"
    version = _extract_schema_version(content)
    if version is None:
        return (
            "schema-missing",
            "no spec_schema_version / holdout_schema_version declared",
        )
    if version not in supported:
        return (
            "schema-unsupported",
            f"declared schema version {version}, supported: {sorted(supported)}",
        )
    return "passed", f"schema v{version}"


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
        spec_path: verify_one(spec_path, SUPPORTED_SPEC_SCHEMA_VERSIONS),
        holdout_path: verify_one(holdout_path, SUPPORTED_HOLDOUT_SCHEMA_VERSIONS),
    }

    print("Architect Spec Verification")
    print("=" * 60)
    for path, (status, detail) in results.items():
        symbol = {
            "passed": "+",
            "stub": "o",
            "missing": "x",
            "schema-missing": "x",
            "schema-unsupported": "x",
        }[status]
        print(f"  [{symbol}] {path}: {status} ({detail})")

    incomplete = [p for p, (s, _) in results.items() if s != "passed"]
    print("=" * 60)
    if not incomplete:
        print(
            "PASSED: SPEC.md and HOLDOUT.md are complete and at a supported schema version."
        )
        sys.exit(0)
    else:
        print(
            f"FAILED: {len(incomplete)} of 2 files are incomplete, missing, or at an unsupported schema version."
        )
        print(
            "   The architect MUST fill all files (including spec_schema_version)"
            " before handing off to implementation."
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
