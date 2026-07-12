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
- Warn on missing SHA-256/Trust in raw files;
  under --strict, fail on quarantine cross-contamination or unresolvable SHA-256s.

Usage (agent context):
    uv run ~/.copilot/skills/llm-mem/scripts/verify_mem.py
    uv run ~/.copilot/skills/llm-mem/scripts/verify_mem.py --root ./llmmem --strict

Exit codes:
    0 = Structure intact (warnings printed)
    1 = Structure broken (missing required files/dirs)
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path

REQUIRED_PATHS = [
    "raw",
    "mem",
    "mem/index.md",
    "mem/log.md",
]

# Regex patterns that match trust metadata fields in raw/article files.
_RE_SHA256 = re.compile(r"^>\s*SHA-256\s*:", re.MULTILINE | re.IGNORECASE)
_RE_TRUST = re.compile(r"^>\s*Trust\s*:\s*(\S+)", re.MULTILINE | re.IGNORECASE)
_RE_SOURCES_SHA = re.compile(r"^>\s*Sources \(SHA-256\)\s*:(.*)", re.MULTILINE | re.IGNORECASE)


def _extract_trust(text: str) -> str | None:
    """Return the Trust value from a file's metadata block, or None."""
    m = _RE_TRUST.search(text)
    return m.group(1).lower() if m else None


def _extract_source_sha256s(article_text: str) -> list[str]:
    """Return all SHA-256 tokens listed in a Sources (SHA-256): line."""
    m = _RE_SOURCES_SHA.search(article_text)
    if not m:
        return []
    raw_value = m.group(1)
    # Tokens are separated by semicolons and may contain spaces.
    tokens = [t.strip() for t in raw_value.split(";") if t.strip()]
    # Keep only 64-char hex strings (valid SHA-256).
    return [t for t in tokens if re.fullmatch(r"[0-9a-fA-F]{64}", t)]


def _file_sha256(path: Path) -> str:
    """Return the SHA-256 hex digest of a file's UTF-8 content."""
    content = path.read_text(encoding="utf-8", errors="ignore")
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def _check_trust_lifecycle(
    root: Path,
    strict: bool,
) -> tuple[list[str], list[str]]:
    """
    Run H-07 trust lifecycle checks.

    Returns:
        warnings: list of warning message strings
        failures: list of strict-failure message strings (only populated when
                  strict=True)
    """
    warnings: list[str] = []
    failures: list[str] = []

    raw_dir = root / "raw"
    mem_dir = root / "mem"

    raw_files = [f for f in raw_dir.rglob("*.md") if f.name != ".gitkeep"]

    # --- Collect quarantined raw file names/stems for cross-ref check --------
    quarantined_stems: set[str] = set()
    quarantined_shas: set[str] = set()

    for raw in raw_files:
        text = raw.read_text(encoding="utf-8", errors="ignore")
        rel = raw.relative_to(root).as_posix()

        has_sha = bool(_RE_SHA256.search(text))
        trust_val = _extract_trust(text)

        if not has_sha:
            warnings.append(f"[!] WARN  raw/{rel}: missing SHA-256 metadata field (treat as unverified).")
        if trust_val is None:
            warnings.append(f"[!] WARN  raw/{rel}: missing Trust metadata field (treat as unverified).")
        elif trust_val == "quarantined":
            quarantined_stems.add(raw.stem)
            # Compute actual SHA-256 so we can detect article references.
            quarantined_shas.add(_file_sha256(raw))

    if not strict:
        return warnings, failures

    # --- Strict checks ---------------------------------------------------------
    # Build the complete set of raw SHA-256 values (for reference validation).
    raw_sha_map: dict[str, Path] = {}
    for raw in raw_files:
        raw_sha_map[_file_sha256(raw)] = raw

    article_files = [f for f in mem_dir.rglob("*.md") if f.name not in ("index.md", "log.md", ".gitkeep")]

    for article in article_files:
        text = article.read_text(encoding="utf-8", errors="ignore")
        art_rel = article.relative_to(root).as_posix()

        # Check 1: article references a quarantined raw file by stem or path.
        for stem in quarantined_stems:
            if stem in text:
                failures.append(
                    f"[x] FAIL  mem/{art_rel}: references quarantined raw file"
                    f" '{stem}' — cross-contamination detected (H-07)."
                )

        # Check 2: article lists source SHA-256s that do not match any raw file.
        listed_shas = _extract_source_sha256s(text)
        for sha in listed_shas:
            if sha not in raw_sha_map:
                failures.append(
                    f"[x] FAIL  mem/{art_rel}: Sources (SHA-256) lists"
                    f" '{sha[:16]}...' which does not match any raw file"
                    " — provenance unresolvable (H-07)."
                )

    return warnings, failures


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
        help="Fail on uncompiled raw files (raw without matching mem coverage) and on H-07 trust lifecycle violations.",
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

    # Trust lifecycle checks (H-07)
    trust_warnings, trust_failures = _check_trust_lifecycle(root, args.strict)
    for msg in trust_warnings:
        print(msg)
    for msg in trust_failures:
        print(msg)

    if trust_failures:
        print(f"[x] FAILED (--strict): {len(trust_failures)} trust lifecycle violation(s) detected (H-07).")
        sys.exit(1)

    print("PASSED.")
    sys.exit(0)


if __name__ == "__main__":
    main()
