"""
scaffold_session_state.py
=========================
Scaffold .copilot/state/SESSION_STATE.md with the schema-conformant template.

Run this when an agent reaches a natural breakpoint and needs to write state
but is starting from scratch (no prior file). Idempotent: skips if file exists.

Usage (agent context):
    uv run skills/context-engineer/scripts/scaffold_session_state.py
    uv run skills/context-engineer/scripts/scaffold_session_state.py --agent architect --status active

Reference: skills/context-engineer/references/session_state_schema.md
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from pathlib import Path

TEMPLATE = """\
# Session State

> **Last Updated:** {timestamp}
> **Last Agent:** {agent}
> **Status:** {status}

## Pipeline Position

- **Current Phase:** [Discovery | Design | Build | Review | Ship]
- **Current Agent:** {agent}
- **Pending Handoff:** none

## Active Task

- **Description:** [one-line summary]
- **Spec Reference:** [.copilot/specs/SPEC.md or "none"]
- **Branch:** [git branch name]

## Completed Steps

1.

## Pending Steps

1.

## Blockers

None

## Context Pointers

-

## Decisions Made This Session

-

## Notes for Next Session

## Pipeline Loop

- **Iteration Count:** 1
- **Loop Agents:**
- **Recurring Failures:** none
"""


def scaffold(state_dir: Path, agent: str, status: str) -> tuple[bool, Path]:
    """Create SESSION_STATE.md if missing. Returns (created, path)."""
    state_dir.mkdir(parents=True, exist_ok=True)
    path = state_dir / "SESSION_STATE.md"
    if path.exists():
        return False, path
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    path.write_text(
        TEMPLATE.format(timestamp=timestamp, agent=agent, status=status),
        encoding="utf-8",
    )
    return True, path


def main() -> None:
    parser = argparse.ArgumentParser(description="Scaffold SESSION_STATE.md")
    parser.add_argument(
        "--state-dir",
        type=Path,
        default=Path(".copilot/state"),
        help="Directory for SESSION_STATE.md (default: .copilot/state)",
    )
    parser.add_argument(
        "--agent",
        default="unknown",
        help="Agent name writing the state (default: unknown)",
    )
    parser.add_argument(
        "--status",
        choices=["active", "paused", "completed", "blocked"],
        default="active",
        help="Initial status (default: active)",
    )
    args = parser.parse_args()

    created, path = scaffold(args.state_dir, args.agent, args.status)
    if created:
        print(f"Created: {path.resolve()}")
        print("Agents must update Pipeline Position, Active Task, and Pending Steps.")
    else:
        print(f"Already exists: {path.resolve()}")
        print("Agents should overwrite (do not append) per the schema.")


if __name__ == "__main__":
    main()
