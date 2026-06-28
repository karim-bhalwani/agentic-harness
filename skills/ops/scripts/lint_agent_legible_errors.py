"""Checks that raise/assert messages contain remediation hints.

Enforces Section 6 (Agent-legible errors) of copilot-instructions.
Copy this script into the target project's tools/ directory and wire
it into pre-commit. See references/mechanical-enforcement.md for the
pre-commit hook configuration.

Usage:
    python tools/lint_agent_legible_errors.py src/
    python tools/lint_agent_legible_errors.py  # defaults to src/
"""

import ast
import re
import sys
from pathlib import Path

# Actionable remediation phrase patterns — tighter than bare keywords
# to avoid false positives on generic messages like "check your input".
_KEYWORD_PATTERNS = [
    re.compile(r"(run|execute)\s+\S+", re.IGNORECASE),
    re.compile(r"(set|update|change)\s+\S+\s+to\b", re.IGNORECASE),
    re.compile(r"(install|add|remove|delete|configure|enable|disable)\s+\S+", re.IGNORECASE),
    re.compile(r"(ensure|verify|check)\s+that\b", re.IGNORECASE),
    re.compile(r"remediat", re.IGNORECASE),
    re.compile(r"fix\s+\S+", re.IGNORECASE),
    re.compile(r"resolve\s+\S+", re.IGNORECASE),
]


def _has_actionable_hint(message: str) -> bool:
    return any(pattern.search(message) for pattern in _KEYWORD_PATTERNS)


def check_file(filepath: Path) -> list[str]:
    violations: list[str] = []
    try:
        tree = ast.parse(filepath.read_text(encoding="utf-8"))
    except SyntaxError:
        return violations

    for node in ast.walk(tree):
        # Check raise statements
        if isinstance(node, ast.Raise) and node.exc and isinstance(node.exc, ast.Call) and node.exc.args:
            if not _has_actionable_hint_in_args(node.exc.args):
                violations.append(
                    f"{filepath}:{node.lineno}: Error message lacks remediation hint. "
                    f"REMEDIATION — Add actionable fix instructions "
                    f"(e.g., 'Run X to fix' or 'Ensure Y is configured')."
                )

        # Check assert statements
        if isinstance(node, ast.Assert) and node.msg:
            msg_arg = node.msg
            if isinstance(msg_arg, ast.Constant) and isinstance(msg_arg.value, str):
                if not _has_actionable_hint(msg_arg.value):
                    violations.append(
                        f"{filepath}:{node.lineno}: Assert message lacks remediation hint. "
                        f"REMEDIATION — Add actionable fix instructions "
                        f"(e.g., 'Run X to fix' or 'Ensure Y is configured')."
                    )
            elif isinstance(msg_arg, ast.JoinedStr):
                # f-string: extract string parts
                text = _extract_fstring_text(msg_arg)
                if text and not _has_actionable_hint(text):
                    violations.append(
                        f"{filepath}:{node.lineno}: Assert message lacks remediation hint. "
                        f"REMEDIATION — Add actionable fix instructions "
                        f"(e.g., 'Run X to fix' or 'Ensure Y is configured')."
                    )

    return violations


def _has_actionable_hint_in_args(args: list[ast.expr]) -> bool:
    """Check all string arguments in an exception constructor."""
    for arg in args:
        if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
            if _has_actionable_hint(arg.value):
                return True
        elif isinstance(arg, ast.JoinedStr):
            text = _extract_fstring_text(arg)
            if text and _has_actionable_hint(text):
                return True
    return False


def _extract_fstring_text(node: ast.JoinedStr) -> str:
    """Extract the static string portions of an f-string for keyword matching."""
    parts: list[str] = []
    for value in node.values:
        if isinstance(value, ast.Constant) and isinstance(value.value, str):
            parts.append(value.value)
    return " ".join(parts)


def main() -> None:
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("src")
    if not target.exists():
        return  # nothing to lint
    violations = [v for f in target.rglob("*.py") for v in check_file(f)]
    if violations:
        print("\n".join(violations))
        sys.exit(1)


if __name__ == "__main__":
    main()
