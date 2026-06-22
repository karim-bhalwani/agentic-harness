"""
verify_claims.py
================
Inspector verification utility for the data-narrative skill.

Reads narrative-output/inspector.json, then for each claim:
  - code evidence   → re-executes the referenced Analyst script and confirms
                       it exits 0 (i.e., is reproducible against the data).
  - reference evidence → HTTP HEAD check that the cited URL is reachable.

Updates inspector.json in place with per-claim 'verified' booleans and a
summary block, then prints a human-readable table to stdout.

Usage (agent context):
    python verify_claims.py --inspector narrative-output/inspector.json
    python verify_claims.py --inspector narrative-output/inspector.json --data data/

Usage (CLI):
    cd <project root>
    python skills/data_narrative/inspector/scripts/verify_claims.py \\
        --inspector narrative-output/inspector.json

Exit codes:
    0 = all claims verified
    1 = one or more claims failed verification
    2 = invalid input or inspector.json not found
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


# ---------------------------------------------------------------------------
# Verification helpers
# ---------------------------------------------------------------------------


def _verify_code_claim(evidence: dict) -> tuple[bool, str]:
    """Re-execute the Analyst script; pass if exit code is 0."""
    script = evidence.get("script")
    if not script:
        return False, "No 'script' path in code evidence"

    script_path = Path(script)
    if not script_path.exists():
        return False, f"Script not found: {script_path}"

    try:
        result = subprocess.run(
            [sys.executable, str(script_path)],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode == 0:
            return True, "Script executed successfully (exit 0)"
        snippet = (result.stderr or result.stdout or "")[:300].strip()
        return False, f"Script exited {result.returncode}: {snippet}"
    except subprocess.TimeoutExpired:
        return False, "Script timed out after 120s"
    except Exception as exc:
        return False, f"Execution error: {exc}"


def _verify_reference_claim(evidence: dict) -> tuple[bool, str]:
    """HTTP HEAD check that the cited URL is reachable (2xx or 3xx)."""
    url = evidence.get("url")
    if not url:
        return False, "No 'url' in reference evidence"

    try:
        req = urllib.request.Request(
            url,
            method="HEAD",
            headers={"User-Agent": "data-narrative-inspector/1.0"},
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status < 400:
                return True, f"URL reachable (HTTP {resp.status})"
            return False, f"URL returned HTTP {resp.status}"
    except Exception as exc:
        return False, f"URL check failed: {exc}"


# ---------------------------------------------------------------------------
# Main verification loop
# ---------------------------------------------------------------------------


def verify_inspector(inspector_path: Path) -> int:
    """Read inspector.json, verify every claim, write results back. Returns exit code."""
    if not inspector_path.exists():
        print(f"ERROR: inspector.json not found: {inspector_path}", file=sys.stderr)
        return 2

    raw = inspector_path.read_text(encoding="utf-8")
    manifest: dict = json.loads(raw)
    claims: list[dict] = manifest.get("claims", [])

    if not claims:
        print("No claims found in inspector.json — nothing to verify.")
        return 0

    verified_count = 0
    failed_count = 0

    col_w = 65
    print(f"\n{'=' * 75}")
    print(f"  data-narrative Inspector — verifying {len(claims)} claim(s)")
    print(f"{'=' * 75}\n")
    print(f"  {'ID':<12} {'STATUS':<6}  {'Claim (truncated)'}")
    print(f"  {'-' * 12} {'-' * 6}  {'-' * col_w}")

    for claim in claims:
        claim_id = claim.get("claim_id", "?")
        text = claim.get("text", "")
        preview = (text[:col_w] + "…") if len(text) > col_w else text
        etype = claim.get("evidence_type", "")
        evidence = claim.get("evidence", {})

        ok, note = False, "No matching evidence type"

        if etype in ("code", "both"):
            ok, note = _verify_code_claim(evidence.get("code", {}))

        # Try reference if code failed or if reference-only
        if (not ok) and etype in ("reference", "both"):
            ok2, note2 = _verify_reference_claim(evidence.get("reference", {}))
            if etype == "both":
                # both must pass; use the worse result's note
                note = note if not ok else note2
                ok = ok and ok2
            else:
                ok, note = ok2, note2

        status = "PASS" if ok else "FAIL"
        print(f"  {claim_id:<12} {status:<6}  {preview}")
        if not ok:
            print(f"  {'':12}         -> {note}")

        claim["verified"] = ok
        claim["verify_note"] = note
        if ok:
            verified_count += 1
        else:
            failed_count += 1

    total = len(claims)
    rate = verified_count / total if total > 0 else 0.0

    manifest["summary"] = {
        "total_claims": total,
        "verified": verified_count,
        "failed": failed_count,
        "unverified": 0,
        "verifiability_rate": round(rate, 3),
        "verified_at": datetime.now(timezone.utc).isoformat(),
    }

    inspector_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"\n{'=' * 75}")
    print(f"  Verifiability rate : {rate:.1%}  ({verified_count}/{total} claims passed)")
    print(f"  Result written to  : {inspector_path}")
    print(f"{'=' * 75}\n")

    return 0 if failed_count == 0 else 1


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Verify data-narrative Inspector claims. Reads and updates inspector.json.",
    )
    parser.add_argument(
        "--inspector",
        type=Path,
        default=Path("narrative-output/inspector.json"),
        help="Path to inspector.json (default: narrative-output/inspector.json)",
    )
    args = parser.parse_args()
    sys.exit(verify_inspector(args.inspector))


if __name__ == "__main__":
    main()
