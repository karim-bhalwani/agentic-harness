"""
scaffold_mem.py
===============
Initialize the llmmem/ directory layout per the llm-mem skill spec.

Idempotent: creates only what is missing, never overwrites existing files.
Run this on the FIRST ingest, or any time the structure may have drifted.

Files/directories created (when missing):
    llmmem/
    llmmem/raw/.gitkeep
    llmmem/mem/.gitkeep
    llmmem/mem/index.md
    llmmem/mem/log.md

Usage (agent context):
    uv run skills/llm-mem/scripts/scaffold_mem.py
    uv run skills/llm-mem/scripts/scaffold_mem.py --root ./llmmem
"""

from __future__ import annotations

import argparse
from pathlib import Path

INDEX_STUB = """\
# Knowledge Base Index

<!-- Catalog of all mem articles. Updated by the LLM after every ingest. -->
"""

LOG_STUB = """\
# mem Log

<!-- Append-only operation log. Each ingest, query, and lint run is recorded. -->
"""


def scaffold(root: Path) -> tuple[list[str], list[str]]:
    """Create the llmmem/ structure. Returns (created, skipped)."""
    created: list[str] = []
    skipped: list[str] = []

    targets: dict[Path, str | None] = {
        root: None,
        root / "raw": None,
        root / "mem": None,
        root / "raw" / ".gitkeep": "",
        root / "mem" / ".gitkeep": "",
        root / "mem" / "index.md": INDEX_STUB,
        root / "mem" / "log.md": LOG_STUB,
    }

    for path, content in targets.items():
        if content is None:
            # Directory
            if path.exists():
                skipped.append(f"{path}/")
            else:
                path.mkdir(parents=True, exist_ok=True)
                created.append(f"{path}/")
        else:
            # File
            if path.exists():
                skipped.append(str(path))
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")
                created.append(str(path))

    return created, skipped


def main() -> None:
    parser = argparse.ArgumentParser(description="Initialize llmmem/ structure")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("llmmem"),
        help="Mem root directory (default: llmmem)",
    )
    args = parser.parse_args()

    created, skipped = scaffold(args.root)

    print(f"Mem root: {args.root.resolve()}")
    print(f"Created: {len(created)}")
    for f in created:
        print(f"  + {f}")
    if skipped:
        print(f"Skipped (already exist): {len(skipped)}")
        for f in skipped:
            print(f"  o {f}")

    print("\nMem structure ready. Proceed with Ingest.")


if __name__ == "__main__":
    main()
