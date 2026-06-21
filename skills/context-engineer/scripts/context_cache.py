"""
context_cache.py
================
Manage the ## Context Cache section in SESSION_STATE.md.

Agents check this cache before reading a file to avoid redundant reads
across agent handoffs in the same session. After reading a file, add an
entry to share context with downstream agents.

Operations:
    add   --path PATH --summary TEXT [--lines START-END]
    query --path PATH [--lines START-END]
    list
    clear

Usage (agent context):
    uv run ~/.copilot/skills/context-engineer/scripts/context_cache.py add \\
        --path src/handler.py --lines 1-80 --summary "Auth validation logic"
    uv run ~/.copilot/skills/context-engineer/scripts/context_cache.py query \\
        --path src/handler.py --lines 1-80
    uv run ~/.copilot/skills/context-engineer/scripts/context_cache.py list

Exit codes:
    add:   0 = entry added or updated, 1 = error
    query: 0 = cache hit (summary printed to stdout), 1 = cache miss
    list:  0 = always
    clear: 0 = always

Reference: skills/context-engineer/references/session_state_schema.md
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path

SECTION_HEADER = "## Context Cache"
ENTRY_RE = re.compile(r"^- \[([0-9a-f]{8})\]: (.+?) \| L(\d+)-(\d+) \| (.+)$")
DEFAULT_STATE_PATH = Path(".copilot/state/SESSION_STATE.md")

_SECTION_PREAMBLE = """\
## Context Cache

> Agents: check here before reading a file. Add an entry after reading.
> Prevents redundant reads across agent handoffs in the same session.
> Format: `- [HASH]: path | L{start}-{end} | one-line summary`"""


def _hash_key(path: str, line_start: int, line_end: int) -> str:
    raw = f"{path}:{line_start}-{line_end}"
    return hashlib.sha256(raw.encode()).hexdigest()[:8]


def _parse_lines_arg(lines: str | None) -> tuple[int, int]:
    if lines is None:
        return 1, 999999
    if "-" in lines:
        parts = lines.split("-", 1)
        return int(parts[0]), int(parts[1])
    n = int(lines)
    return n, n


def _load_state(state_path: Path) -> str:
    if not state_path.exists():
        print(
            f"[x] SESSION_STATE.md not found at {state_path}. "
            "Run scaffold_session_state.py first.",
            file=sys.stderr,
        )
        sys.exit(1)
    return state_path.read_text(encoding="utf-8")


def _extract_section(content: str) -> tuple[str, str, str]:
    """Split content into (before, section_body, after) for the cache section.

    section_body includes the SECTION_HEADER line itself.
    after starts at the next ## heading (if any).
    """
    if SECTION_HEADER not in content:
        return content, "", ""

    idx = content.index(SECTION_HEADER)
    before = content[:idx]
    rest = content[idx + len(SECTION_HEADER) :]

    nxt = re.search(r"\n## ", rest)
    if nxt:
        section_body = rest[: nxt.start()]
        after = rest[nxt.start() + 1 :]  # drop leading newline; _rebuild re-adds it
    else:
        section_body = rest
        after = ""

    return before, section_body, after


def _parse_entries(section_body: str) -> list[dict]:
    entries: list[dict] = []
    for line in section_body.splitlines():
        m = ENTRY_RE.match(line.strip())
        if m:
            entries.append(
                {
                    "hash": m.group(1),
                    "path": m.group(2),
                    "line_start": int(m.group(3)),
                    "line_end": int(m.group(4)),
                    "summary": m.group(5),
                }
            )
    return entries


def _render_section(entries: list[dict]) -> str:
    lines = [_SECTION_PREAMBLE]
    for e in entries:
        lines.append(
            f"- [{e['hash']}]: {e['path']} | L{e['line_start']}-{e['line_end']} | {e['summary']}"
        )
    return "\n".join(lines) + "\n"


def _rebuild(before: str, section: str, after: str) -> str:
    if after:
        return before + section + "\n" + after.lstrip("\n")
    return before + section


def cmd_add(args: argparse.Namespace, state_path: Path) -> None:
    content = _load_state(state_path)
    line_start, line_end = _parse_lines_arg(args.lines)
    key = _hash_key(args.path, line_start, line_end)

    before, section_body, after = _extract_section(content)
    entries = _parse_entries(section_body)

    existing = next((e for e in entries if e["hash"] == key), None)
    if existing:
        existing["summary"] = args.summary
        print(f"[~] Updated [{key}]: {args.path} | L{line_start}-{line_end}")
    else:
        entries.append(
            {
                "hash": key,
                "path": args.path,
                "line_start": line_start,
                "line_end": line_end,
                "summary": args.summary,
            }
        )
        print(f"[+] Cached [{key}]: {args.path} | L{line_start}-{line_end}")

    new_section = _render_section(entries)
    state_path.write_text(_rebuild(before, new_section, after), encoding="utf-8")


def cmd_query(args: argparse.Namespace, state_path: Path) -> None:
    content = _load_state(state_path)
    line_start, line_end = _parse_lines_arg(args.lines)
    key = _hash_key(args.path, line_start, line_end)

    _, section_body, _ = _extract_section(content)
    entries = _parse_entries(section_body)

    match = next((e for e in entries if e["hash"] == key), None)
    if match:
        print(f"HIT [{key}]: {match['summary']}")
        sys.exit(0)
    else:
        print(f"MISS: {args.path} | L{line_start}-{line_end} not in cache")
        sys.exit(1)


def cmd_list(state_path: Path) -> None:
    content = _load_state(state_path)
    _, section_body, _ = _extract_section(content)
    entries = _parse_entries(section_body)

    if not entries:
        print("Context cache is empty.")
        return

    label = "entry" if len(entries) == 1 else "entries"
    print(f"Context Cache ({len(entries)} {label}):")
    for e in entries:
        print(
            f"  [{e['hash']}] {e['path']} L{e['line_start']}-{e['line_end']}: {e['summary']}"
        )


def cmd_clear(state_path: Path) -> None:
    content = _load_state(state_path)
    before, section_body, after = _extract_section(content)
    if not section_body and SECTION_HEADER not in content:
        print("Cache already empty (no section found).")
        return
    new_section = _render_section([])
    state_path.write_text(_rebuild(before, new_section, after), encoding="utf-8")
    print("[x] Context cache cleared.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Manage the ## Context Cache section in SESSION_STATE.md"
    )
    parser.add_argument(
        "--state-path",
        type=Path,
        default=DEFAULT_STATE_PATH,
        help="Path to SESSION_STATE.md (default: .copilot/state/SESSION_STATE.md)",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    add_p = sub.add_parser("add", help="Add or update a cache entry")
    add_p.add_argument(
        "--path", required=True, help="File path (relative to project root)"
    )
    add_p.add_argument(
        "--lines", help="Line range, e.g. 1-80. Omit to cache whole file."
    )
    add_p.add_argument(
        "--summary", required=True, help="One-line summary of the content"
    )

    q_p = sub.add_parser("query", help="Check if cached; exit 0=hit, 1=miss")
    q_p.add_argument("--path", required=True, help="File path to look up")
    q_p.add_argument("--lines", help="Line range (must match the add call exactly)")

    sub.add_parser("list", help="List all cached entries")
    sub.add_parser("clear", help="Remove all cache entries")

    args = parser.parse_args()

    if args.command == "add":
        cmd_add(args, args.state_path)
    elif args.command == "query":
        cmd_query(args, args.state_path)
    elif args.command == "list":
        cmd_list(args.state_path)
    elif args.command == "clear":
        cmd_clear(args.state_path)


if __name__ == "__main__":
    main()
