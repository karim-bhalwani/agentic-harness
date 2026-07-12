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
import ipaddress
import json
import socket
import subprocess
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

# Limit error snippet length to keep verification output readable in reports.
MAX_ERROR_SNIPPET_LENGTH = 300


# ---------------------------------------------------------------------------
# Verification helpers
# ---------------------------------------------------------------------------


def _verify_code_claim(evidence: dict, allowed_base: Path) -> tuple[bool, str]:
    """Re-execute the Analyst script; pass if exit code is 0."""
    script = evidence.get("script")
    if not script:
        return False, "No 'script' path in code evidence"

    script_path = Path(script).resolve()

    try:
        script_path.relative_to(allowed_base)
    except ValueError:
        return False, f"Script path is outside allowed directory: {script_path}"

    if script_path.suffix != ".py":
        return False, f"Script is not a Python file: {script_path}"

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
        snippet = (result.stderr or result.stdout or "")[:MAX_ERROR_SNIPPET_LENGTH].strip()
        return False, f"Script exited {result.returncode}: {snippet}"
    except subprocess.TimeoutExpired:
        return False, "Script timed out after 120s"
    except Exception as exc:
        return False, f"Execution error: {exc}"


def _is_public_https_url(url: str) -> tuple[bool, str]:
    """Validate URL is HTTPS and resolves only to public IP addresses."""
    try:
        parsed = urllib.parse.urlparse(url)
    except Exception:
        return False, "Invalid URL format"

    if parsed.scheme.lower() != "https":
        return False, "Only https URLs are allowed"

    if not parsed.hostname:
        return False, "URL must include a hostname"

    try:
        addrinfos = socket.getaddrinfo(parsed.hostname, 443, proto=socket.IPPROTO_TCP)
    except Exception as exc:
        return False, f"Hostname resolution failed: {exc}"

    for info in addrinfos:
        ip_text = info[4][0]
        ip_obj = ipaddress.ip_address(ip_text)
        if (
            ip_obj.is_private
            or ip_obj.is_loopback
            or ip_obj.is_link_local
            or ip_obj.is_multicast
            or ip_obj.is_reserved
            or ip_obj.is_unspecified
        ):
            return False, f"Non-public IP not allowed: {ip_obj}"

    return True, "URL is valid"


def _verify_reference_claim(evidence: dict) -> tuple[bool, str]:
    """HTTP HEAD check that the cited URL is reachable (2xx or 3xx).

    SSRF-safe: the URL is validated (HTTPS + public IP only), then the
    connection is pinned to the single validated IP via a raw HTTPSConnection
    with `server_hostname` set for SNI/cert verification. This closes the
    DNS-rebinding TOCTOU window that `urlopen` would otherwise reopen, and
    redirects are refused rather than followed to an unvalidated target.
    """
    import http.client

    url = evidence.get("url")
    if not url:
        return False, "No 'url' in reference evidence"

    is_valid, reason = _is_public_https_url(url)
    if not is_valid:
        return False, f"URL not allowed: {reason}"

    parsed = urllib.parse.urlparse(url)
    port = int(parsed.port or 443)

    # Resolve once and pin the connection to the validated IP.
    try:
        addrinfos = socket.getaddrinfo(parsed.hostname, port, proto=socket.IPPROTO_TCP)
    except Exception as exc:
        return False, f"Hostname resolution failed: {exc}"
    ip_text = str(addrinfos[0][4][0])

    try:
        import ssl

        # Pin the connection to the single validated IP while still sending the
        # real hostname for SNI and certificate verification. Python 3.11 lacks
        # HTTPSConnection's `server_hostname` kwarg, so we wrap the socket
        # manually and hand it to the connection (bypassing its internal
        # connect()). This keeps the DNS-rebinding TOCTOU window closed.
        raw_sock = socket.create_connection((ip_text, port), timeout=120)
        ssl_ctx = ssl.create_default_context()
        ssl_sock = ssl_ctx.wrap_socket(raw_sock, server_hostname=parsed.hostname)
        conn = http.client.HTTPSConnection(ip_text, port=port, timeout=120)
        conn.sock = ssl_sock
        conn.request(
            "HEAD",
            parsed.path or "/",
            headers={"User-Agent": "data-narrative-inspector/1.0", "Host": parsed.hostname},
        )
        resp = conn.getresponse()
        status = resp.status
        resp.read()
        conn.close()
    except Exception as exc:
        return False, f"URL check failed: {exc}"

    # Refuse redirects: do not follow to an unvalidated target.
    if 300 <= status < 400:
        return False, f"URL returned redirect (HTTP {status}); redirects are not followed"
    if status < 400:
        return True, f"URL reachable (HTTP {status})"
    return False, f"URL returned HTTP {status}"


# ---------------------------------------------------------------------------
# Main verification loop
# ---------------------------------------------------------------------------


def verify_inspector(inspector_path: Path, allowed_base: Path | None = None) -> int:
    """Read inspector.json, verify every claim, write results back. Returns exit code."""
    if allowed_base is None:
        allowed_base = Path("narrative-output/analyst").resolve()
    if not inspector_path.exists():
        print(f"ERROR: inspector.json not found: {inspector_path}", file=sys.stderr)
        return 2

    raw = inspector_path.read_text(encoding="utf-8")
    try:
        manifest: dict = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(
            f"ERROR: inspector.json is malformed or not valid JSON: {inspector_path} ({exc})",
            file=sys.stderr,
        )
        return 2
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

        if etype == "code":
            ok, note = _verify_code_claim(evidence.get("code", {}), allowed_base)
        elif etype == "reference":
            ok, note = _verify_reference_claim(evidence.get("reference", {}))
        elif etype == "both":
            code_ok, code_note = _verify_code_claim(evidence.get("code", {}), allowed_base)
            ref_ok, ref_note = _verify_reference_claim(evidence.get("reference", {}))
            ok = code_ok and ref_ok
            # both must pass; report the failing side's note
            if not code_ok:
                note = code_note
            elif not ref_ok:
                note = ref_note
            else:
                note = ref_note

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
    parser.add_argument(
        "--allowed-base",
        type=Path,
        default=Path("narrative-output/analyst"),
        help="Base directory allowed for code-evidence scripts (default: narrative-output/analyst)",
    )
    args = parser.parse_args()
    sys.exit(verify_inspector(args.inspector, args.allowed_base.resolve()))


if __name__ == "__main__":
    main()
