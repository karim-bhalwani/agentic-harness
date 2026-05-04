"""
scaffold_bible.py
=================
Scaffold all 6 Project Bible files with stub content.

Run this at the START of the documentation phase to guarantee all files exist.
The agent then fills each file with real content. This prevents any file from
being silently skipped if the agent is interrupted or runs out of context.

Usage (agent context):
    uv run skills/context-engineer/scripts/scaffold_bible.py --output-dir .copilot/context

Usage (with mode):
    uv run skills/context-engineer/scripts/scaffold_bible.py --output-dir .copilot/context --mode greenfield
    uv run skills/context-engineer/scripts/scaffold_bible.py --output-dir .copilot/context --mode brownfield
"""

from __future__ import annotations

import argparse
from pathlib import Path

BIBLE_FILES: dict[str, str] = {
    "PROJECT_CONTEXT.md": """\
# Project Context

> **Status:** STUB - awaiting content from discovery/interview agent.
> This file must be filled before the Project Bible is considered complete.

<!-- Tier 1: Always loaded. Target < 200 lines. -->

## Identity

<!-- Project name, purpose, type -->

## Tech Stack

<!-- Languages, frameworks, versions -->

## Entry Points

<!-- How to run, CLI commands, main files -->

## Critical Rules

<!-- Non-negotiable constraints -->

## Repository Structure

<!-- Key directories and their purpose -->
""",
    "ARCHITECTURE.md": """\
# Architecture

> **Status:** STUB - awaiting content from discovery/interview agent.
> This file must be filled before the Project Bible is considered complete.

<!-- Tier 2: Loaded when designing or building. -->

## Module Responsibility Map

| Module | Responsibility | Depends On | Depended On By |
| ------ | -------------- | ---------- | -------------- |
| ...    | ...            | ...        | ...            |

## Data Flow

```mermaid
graph LR
    A[Input] --> B[Processing] --> C[Output]
```

## External Integrations

<!-- APIs, databases, cloud services -->

## Tech Debt

| Item | Location | Severity | Notes |
| ---- | -------- | -------- | ----- |
| ...  | ...      | ...      | ...   |
""",
    "CODEBASE_PATTERNS.md": """\
# Codebase Patterns

> **Status:** STUB - awaiting content from discovery/interview agent.
> This file must be filled before the Project Bible is considered complete.

<!-- Tier 2: Loaded when coding or reviewing. -->

## Coding Style

<!-- Naming conventions, formatting, imports -->

## Data Model Patterns

<!-- How data structures are defined -->

## Testing Patterns

<!-- Test structure, fixtures, conventions -->

## Anti-Patterns

<!-- Things NOT to replicate -->

## Configuration Patterns

<!-- How config is managed -->
""",
    "AGENT_GUIDE.md": """\
# Agent Guide

> **Status:** STUB - awaiting content from discovery/interview agent.
> This file must be filled before the Project Bible is considered complete.

<!-- Tier 2: Loaded before any agent starts work. -->

## Do-Not-Touch Zones

<!-- Files/modules that should not be modified without explicit approval -->

## Safe Extension Points

<!-- Where new code should be added -->

## Agent-Specific Instructions

### senior-developer

<!-- Instructions for general implementation -->

### data-engineer

<!-- Instructions for data pipeline work -->

### ai-engineer

<!-- Instructions for LLM/RAG work -->

### guardian

<!-- Instructions for code review -->
""",
    "DECISIONS.md": """\
# Decisions

> **Status:** STUB - awaiting content from discovery/interview agent.
> This file must be filled before the Project Bible is considered complete.

<!-- Tier 3: Loaded when confused about intent or history. -->

## Architectural Decisions

| Decision | Rationale | Date | Status |
| -------- | --------- | ---- | ------ |
| ...      | ...       | ...  | ...    |

## Open Questions

<!-- Unresolved items requiring human input -->

## Dependency Decisions

<!-- Why specific libraries/versions were chosen -->

## Known Gaps

<!-- Areas where documentation or implementation is incomplete -->
""",
    "ORIENTATION.md": """\
# 5-Minute Orientation

> **Status:** STUB - awaiting content from discovery/interview agent.
> This file must be filled before the Project Bible is considered complete.

<!-- Tier 1: Quick-start summary for new team members and agents. Target 500-800 words. -->

## What Is This?

<!-- One paragraph: project name, purpose, who uses it -->

## Tech Stack

<!-- Bullet list of key technologies -->

## How to Run

<!-- Step-by-step commands to get the project running locally -->

## Key Paths

<!-- Most important files/directories -->

## Domain Glossary

<!-- 5-10 domain terms and their meaning in this project -->

## Current State

<!-- What works, what doesn't, what's in progress -->
""",
}


def scaffold_bible(
    output_dir: Path, mode: str = "brownfield"
) -> tuple[list[str], list[str]]:
    """Create all 6 Project Bible stub files. Returns tuple of (created, skipped) files."""
    output_dir.mkdir(parents=True, exist_ok=True)
    created: list[str] = []
    skipped: list[str] = []

    for filename, content in BIBLE_FILES.items():
        filepath = output_dir / filename
        if filepath.exists():
            skipped.append(filename)
            continue

        # Add mode-specific header
        if mode == "greenfield":
            header = (
                "> **Founding Document**: Generated by Greenfield Interview.\n"
                "> All decisions are [DECLARED] (user intent), not [CONFIRMED] (code-verified).\n"
                "> Re-run Brownfield Discovery after first implementation to promote to [CONFIRMED].\n\n"
            )
        else:
            header = (
                "> **Discovery Document**: Generated by Brownfield Discovery.\n"
                "> All claims are evidence-backed: [CONFIRMED], [INFERRED], or flagged.\n\n"
            )

        # Insert header after the first heading line
        lines = content.split("\n", 1)
        final_content = lines[0] + "\n\n" + header + lines[1]

        filepath.write_text(final_content, encoding="utf-8")
        created.append(filename)

    return created, skipped


def main() -> None:
    parser = argparse.ArgumentParser(description="Scaffold Project Bible files")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(".copilot/context"),
        help="Directory to write Bible files (default: .copilot/context)",
    )
    parser.add_argument(
        "--mode",
        choices=["greenfield", "brownfield"],
        default="brownfield",
        help="Mode determines the header style (default: brownfield)",
    )
    args = parser.parse_args()

    created, skipped = scaffold_bible(args.output_dir, args.mode)

    print(f"Output directory: {args.output_dir.resolve()}")
    print(f"Created: {len(created)} files")
    for f in created:
        print(f"  ✓ {f}")
    if skipped:
        print(f"Skipped (already exist): {len(skipped)} files")
        for f in skipped:
            print(f"  ⊘ {f}")

    total_expected = len(BIBLE_FILES)
    total_present = len(skipped) + len(created)
    if total_present == total_expected:
        print(f"\n✅ All {total_expected} Project Bible files are present.")
    else:
        missing = total_expected - total_present
        print(f"\n❌ {missing} files could not be created.")


if __name__ == "__main__":
    main()
