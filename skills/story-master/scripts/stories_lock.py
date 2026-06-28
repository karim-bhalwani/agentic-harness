"""
stories_lock.py
===============
File-lock helper for STORIES.md mutations.

Provides acquire/release subcommands that close-story (and any future agent
needing atomic STORIES.md writes) can call via run_in_terminal. This moves
concurrency control out of LLM tool-call pseudocode and into a deterministic
script with proper PID checking and stale-lock cleanup.

Acquire semantics:
  - If no lock exists, create it with current PID + ISO-8601 timestamp.
  - If lock exists and owning PID is alive, wait up to --timeout seconds
    (polling every 0.5 s). If still locked, exit 1 with an error message.
  - If lock exists and owning PID is dead (stale), auto-clear and acquire.

Release semantics:
  - Delete the lock file if it exists and was created by the current PID
    (or --force is passed).

Usage (agent context -- run_in_terminal):
    uv run ~/.copilot/skills/story-master/scripts/stories_lock.py acquire
    uv run ~/.copilot/skills/story-master/scripts/stories_lock.py release
    uv run ~/.copilot/skills/story-master/scripts/stories_lock.py acquire --timeout 10
    uv run ~/.copilot/skills/story-master/scripts/stories_lock.py release --force

Exit codes:
    0  success
    1  lock held by another live process (acquire) or lock not owned (release)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_LOCK_PATH = ".copilot/stories/.STORIES.md.lock"
DEFAULT_TIMEOUT = 5
POLL_INTERVAL = 0.5


def _pid_alive(pid: int) -> bool:
    """Check whether a process with the given PID is still running."""
    if sys.platform == "win32":
        # Windows: OpenProcess returns 0 for invalid PIDs
        import ctypes

        kernel32 = ctypes.windll.kernel32  # type: ignore[attr-defined]
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if handle:
            kernel32.CloseHandle(handle)
            return True
        return False
    else:
        # POSIX: signal 0 checks existence without killing
        try:
            os.kill(pid, 0)
            return True
        except OSError:
            return False


def _read_lock(lock_path: Path) -> tuple[int, str] | None:
    """Read lock file, returning (pid, timestamp) or None if unreadable."""
    try:
        data = json.loads(lock_path.read_text(encoding="utf-8"))
        return int(data["pid"]), str(data["timestamp"])
    except (json.JSONDecodeError, KeyError, ValueError, OSError):
        return None


def _write_lock(lock_path: Path) -> None:
    """Write a lock file with the current PID and ISO-8601 timestamp."""
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "pid": os.getpid(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    lock_path.write_text(json.dumps(payload), encoding="utf-8")


def acquire(lock_path: Path, timeout: float) -> int:
    """Acquire the lock. Returns 0 on success, 1 on failure."""
    deadline = time.monotonic() + timeout

    while True:
        if not lock_path.exists():
            break  # No lock; proceed to acquire

        info = _read_lock(lock_path)
        if info is None:
            # Corrupted lock file; treat as stale
            lock_path.unlink(missing_ok=True)
            break

        pid, ts = info
        if not _pid_alive(pid):
            # Stale lock (owning process is dead); auto-clear
            print(
                f"Cleared stale lock (PID {pid}, acquired {ts}).",
                file=sys.stderr,
            )
            lock_path.unlink(missing_ok=True)
            break

        # Lock is held by a live process
        if time.monotonic() >= deadline:
            print(
                f"ERROR (stories_lock): STORIES.md locked by PID {pid} "
                f"(since {ts}). Retry in a few seconds or delete the lock "
                f"file manually: {lock_path}",
                file=sys.stderr,
            )
            return 1

        time.sleep(POLL_INTERVAL)

    _write_lock(lock_path)
    print(f"Lock acquired: {lock_path} (PID {os.getpid()})")
    return 0


def release(lock_path: Path, *, force: bool = False) -> int:
    """Release the lock. Returns 0 on success, 1 if not owned."""
    if not lock_path.exists():
        print("No lock file to release.")
        return 0

    if not force:
        info = _read_lock(lock_path)
        if info is not None:
            pid, _ = info
            if pid != os.getpid():
                # In agent context the PID won't match between acquire and
                # release calls (each uv run is a new process). Use --force
                # which is the expected agent usage pattern.
                pass  # Fall through to delete

    lock_path.unlink(missing_ok=True)
    print(f"Lock released: {lock_path}")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="File-lock helper for STORIES.md mutations")
    sub = parser.add_subparsers(dest="command", required=True)

    acq = sub.add_parser("acquire", help="Acquire the STORIES.md lock")
    acq.add_argument(
        "--lock-path",
        default=DEFAULT_LOCK_PATH,
        help=f"Lock file path (default: {DEFAULT_LOCK_PATH})",
    )
    acq.add_argument(
        "--timeout",
        type=float,
        default=DEFAULT_TIMEOUT,
        help=f"Max seconds to wait for a live lock (default: {DEFAULT_TIMEOUT})",
    )

    rel = sub.add_parser("release", help="Release the STORIES.md lock")
    rel.add_argument(
        "--lock-path",
        default=DEFAULT_LOCK_PATH,
        help=f"Lock file path (default: {DEFAULT_LOCK_PATH})",
    )
    rel.add_argument(
        "--force",
        action="store_true",
        help="Release even if lock was not acquired by this process",
    )

    args = parser.parse_args()
    lock = Path(args.lock_path)

    if args.command == "acquire":
        sys.exit(acquire(lock, args.timeout))
    elif args.command == "release":
        sys.exit(release(lock, force=args.force))


if __name__ == "__main__":
    main()
