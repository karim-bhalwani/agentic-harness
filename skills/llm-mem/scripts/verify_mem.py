"""
verify_mem.py
=============
Verify llmmem/ structure is intact and consistent. Run before query/lint.

Checks:
- llmmem/raw/ exists
- llmmem/mem/ exists
- llmmem/mem/index.md exists
- llmmem/mem/log.md exists
- For every llmmem/raw/<topic>/<file>.md, at least one llmmem/mem/<topic>/ article
  exists OR the index.md mentions the raw file (loose coupling check)

Usage (agent context):
    uv run skills/llm-mem/scripts/verify_mem.py
    uv run skills/llm-mem/scripts/verify_mem.py --root ./llmmem --strict

Exit codes:
    0 = Structure intact (warnings printed)
    1 = Structure broken (missing required files/dirs)
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

REQUIRED_PATHS = [
    "raw",
    "mem",
    "mem/index.md",
    "mem/log.md",
]


def main() -> None:
    parser = argparse.ArgumentParser(description="Verify llmmem/ structure")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("llmmem"),
        help="Mem root directory (default: llmmem)",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Fail on uncompiled raw files (raw without matching mem coverage)",
    )
    args = parser.parse_args()

    root = args.root
    print("Mem Structure Verification")
    print("=" * 60)
    print(f"Root: {root.resolve()}")

    if not root.exists():
        print("[x] FAILED: llmmem/ root does not exist.")
        print("   Run scaffold_mem.py first.")
        sys.exit(1)

    missing = [p for p in REQUIRED_PATHS if not (root / p).exists()]
    if missing:
        print(f"[x] FAILED: missing required paths: {missing}")
        print("   Run scaffold_mem.py to create them.")
        sys.exit(1)

    # Coverage check: every raw file referenced somewhere in mem/
    raw_files = list((root / "raw").rglob("*.md"))
    raw_files = [f for f in raw_files if f.name != ".gitkeep"]
    mem_text = ""
    for mem_md in (root / "mem").rglob("*.md"):
        mem_text += mem_md.read_text(encoding="utf-8", errors="ignore")

    uncovered: list[Path] = []
    for raw in raw_files:
        rel = raw.relative_to(root).as_posix()
        if rel not in mem_text and raw.stem not in mem_text:
            uncovered.append(raw)

    print(f"[+] Required structure present ({len(REQUIRED_PATHS)} paths).")
    print(f"    Raw files: {len(raw_files)}")
    print(f"    Mem articles: {len(list((root / 'mem').rglob('*.md')))}")

    if uncovered:
        print(f"[!] WARNING: {len(uncovered)} raw file(s) not referenced in mem/:")
        for f in uncovered[:10]:
            print(f"    - {f.relative_to(root)}")
        if args.strict:
            print("[x] FAILED (--strict): uncovered raw files detected.")
            sys.exit(1)

    print("PASSED.")
    sys.exit(0)


if __name__ == "__main__":
    main()
