"""
scaffold_artifacts.py
=====================
Scaffold the architect's two on-disk artifact files (SPEC.md + HOLDOUT.md)
with stub content. Mirrors the brownfield/greenfield Bible scaffold pattern.

Run this at the START of Phase 4 (Specification Draft) to guarantee both files
exist. The architect then fills each file with real content. This prevents
either file from being silently skipped if the agent is interrupted or runs
out of context.

Files created (when missing):
    .copilot/specs/SPEC.md
    .copilot/holdout/HOLDOUT.md

Note: This is a minimal-stub scaffold (the verification gate target).
For a richer programmatic SPEC template, see scaffold_spec.py in this folder.

Usage (agent context):
    uv run ~/.copilot/skills/architect/scripts/scaffold_artifacts.py
    uv run ~/.copilot/skills/architect/scripts/scaffold_artifacts.py --specs-dir .copilot/specs --holdout-dir .copilot/holdout
"""

from __future__ import annotations

import argparse
from pathlib import Path

SPEC_STUB = """\
---
spec_schema_version: 1
version: "0.1"
status: "Draft"
date: "YYYY-MM-DD"
owner: "<lead architect>"
holdout_reference: ".copilot/holdout/HOLDOUT.md"
scope_mode: "EXPANSION"
---

# [System Name] - Technical Specification

> **Status:** STUB - awaiting content from architect.
> This file must be filled before the spec is considered complete.

**Version:** 0.1 | **Status:** Draft | **Date:** YYYY-MM-DD

## 1. Problem Statement

<!-- 1-2 paragraphs: what problem, why now, what is out of scope -->

## 2. Architecture Overview

<!-- Mermaid diagram of modules and data flow -->

## 3. Module Responsibility Map

| Module | Responsibility | Interface | Depends On |
| ------ | -------------- | --------- | ---------- |

## 4. Data Model

<!-- Schema definitions, partitioning strategy, retention policy -->

## 5. API Contracts

<!-- Endpoint definitions with request/response schemas -->

## 6. Data Contracts

<!-- Schema contracts between pipeline stages -->

## 7. Error Handling Strategy

<!-- Error categories, retry policies, fallback paths, dead letter queues -->

### Error & Rescue Map

| Codepath / Method | What Can Go Wrong | Exception Class | Rescued? | Rescue Action | User Sees | Tested? |
| ----------------- | ----------------- | --------------- | -------- | ------------- | --------- | ------- |

## 8. Holdout Reference

See `.copilot/holdout/HOLDOUT.md` for behavioral acceptance scenarios.
"""

HOLDOUT_STUB = """\
---
holdout_schema_version: 1
feature: "<feature-name>"
owner: "<lead architect>"
scenarios: 3
---

# Holdout - Behavioral Acceptance Scenarios

> **Status:** STUB - awaiting content from architect.
> This file must be filled before the spec is considered complete.
> **Implementation agents MUST NOT read this file.**

## Scenarios

<!-- 3-10 scenarios per feature. Each scenario describes what must be true from
     the user's perspective, not what functions should return. -->

### Scenario 1: [name]

**Given:** [precondition]
**When:** [action]
**Then:** [observable outcome]

### Scenario 2: [name]

**Given:** [precondition]
**When:** [action]
**Then:** [observable outcome]
"""


def scaffold(specs_dir: Path, holdout_dir: Path) -> tuple[list[str], list[str]]:
    """Create SPEC.md and HOLDOUT.md stubs. Returns (created, skipped)."""
    created: list[str] = []
    skipped: list[str] = []

    targets = {
        specs_dir / "SPEC.md": SPEC_STUB,
        holdout_dir / "HOLDOUT.md": HOLDOUT_STUB,
    }

    for filepath, content in targets.items():
        filepath.parent.mkdir(parents=True, exist_ok=True)
        if filepath.exists():
            skipped.append(str(filepath))
            continue
        filepath.write_text(content, encoding="utf-8")
        created.append(str(filepath))

    return created, skipped


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scaffold architect on-disk artifacts (SPEC.md + HOLDOUT.md)"
    )
    parser.add_argument(
        "--specs-dir",
        type=Path,
        default=Path(".copilot/specs"),
        help="Directory for SPEC.md (default: .copilot/specs)",
    )
    parser.add_argument(
        "--holdout-dir",
        type=Path,
        default=Path(".copilot/holdout"),
        help="Directory for HOLDOUT.md (default: .copilot/holdout)",
    )
    args = parser.parse_args()

    created, skipped = scaffold(args.specs_dir, args.holdout_dir)

    print(f"Specs dir:   {args.specs_dir.resolve()}")
    print(f"Holdout dir: {args.holdout_dir.resolve()}")
    print(f"Created: {len(created)} files")
    for f in created:
        print(f"  + {f}")
    if skipped:
        print(f"Skipped (already exist): {len(skipped)} files")
        for f in skipped:
            print(f"  o {f}")

    total = 2
    present = len(created) + len(skipped)
    if present == total:
        print(f"\nAll {total} architect artifacts are present.")
    else:
        print(f"\n{total - present} files could not be created.")


if __name__ == "__main__":
    main()
