"""
check_pipeline_health.py
========================
Validate CI/CD pipeline configuration files for common issues before deployment.

Checks GitHub Actions workflows, Dockerfiles, and environment configuration for:
- Hard-coded secrets and credentials
- Unpinned image tags (latest, no digest)
- Missing health-check or timeout settings
- Deprecated CI runner images

Usage (agent context):
    from skills.ops.scripts.check_pipeline_health import check_pipeline_health
    issues = check_pipeline_health(Path(".github/workflows"))

Usage (CLI):
    python check_pipeline_health.py --path .github/workflows
    python check_pipeline_health.py --path Dockerfile
"""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass
from enum import Enum
from collections.abc import Iterator
from pathlib import Path

_JOB_INDENT_OFFSET = 2


class IssueSeverity(str, Enum):
    CRITICAL = "critical"  # Blocks deploy
    WARNING = "warning"  # Should fix soon
    INFO = "info"  # Informational


@dataclass
class PipelineIssue:
    severity: IssueSeverity
    file: str
    line: int
    message: str
    remediation: str

    def __str__(self) -> str:
        return (
            f"[{self.severity.value.upper()}] {self.file}:{self.line} — {self.message}\n"
            f"  Remediation: {self.remediation}"
        )


# Patterns that indicate hard-coded secrets
# Password detector structure:
# - Match common password key names followed by ":" or "="
# - Allow an optional opening quote before the value
# - Exclude template/runtime substitutions:
#   * "${{ ... }}" (GitHub Actions expression syntax)
#   * "$(...)" (shell command substitution)
#   * "name(...)" (function-style expression)
# - Require a non-whitespace value length of at least 12 chars
_PASSWORD_KEY = r"(?i)\b(password|passwd|pwd)\b"
_ASSIGNMENT = r"\s*[:=]\s*"
_OPTIONAL_OPEN_QUOTE = r'["\']?'
_EXCLUDE_GITHUB_EXPR = r"(?!\$\{\{)"
_EXCLUDE_SHELL_SUBSTITUTION = r"(?!\$\()"
_EXCLUDE_FUNCTION_CALL = r"(?![A-Za-z_][A-Za-z0-9_]*\()"
_PASSWORD_VALUE = r"(?:[^\s]{12,})"
_HARDCODED_PASSWORD_PATTERN = (
    _PASSWORD_KEY
    + _ASSIGNMENT
    + _OPTIONAL_OPEN_QUOTE
    + _EXCLUDE_GITHUB_EXPR
    + _EXCLUDE_SHELL_SUBSTITUTION
    + _EXCLUDE_FUNCTION_CALL
    + _PASSWORD_VALUE
)

_API_KEY_NAME = r"(?i)(api[_-]?key|apikey)"
_API_KEY_VALUE = r"(?:[^\s]{10,})"
_HARDCODED_API_KEY_PATTERN = (
    _API_KEY_NAME
    + _ASSIGNMENT
    + _OPTIONAL_OPEN_QUOTE
    + _EXCLUDE_GITHUB_EXPR
    + _EXCLUDE_SHELL_SUBSTITUTION
    + _EXCLUDE_FUNCTION_CALL
    + _API_KEY_VALUE
)

_SECRET_TOKEN_NAME = r"(?i)(secret|token)"
_SECRET_TOKEN_VALUE = r"(?:[^\s]{8,})"
_HARDCODED_SECRET_TOKEN_PATTERN = (
    _SECRET_TOKEN_NAME
    + _ASSIGNMENT
    + _OPTIONAL_OPEN_QUOTE
    + _EXCLUDE_GITHUB_EXPR
    + _EXCLUDE_SHELL_SUBSTITUTION
    + _EXCLUDE_FUNCTION_CALL
    + _SECRET_TOKEN_VALUE
)

_SECRET_PATTERNS: list[tuple[re.Pattern, str]] = [
    (
        re.compile(_HARDCODED_PASSWORD_PATTERN),
        "Hard-coded password",
    ),
    (
        re.compile(_HARDCODED_API_KEY_PATTERN),
        "Hard-coded API key",
    ),
    (
        re.compile(_HARDCODED_SECRET_TOKEN_PATTERN),
        "Hard-coded secret/token",
    ),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "AWS Access Key ID"),
    (
        re.compile(r'(?i)connectionstring\s*[:=]\s*["\'].{20,}'),
        "Hard-coded connection string",
    ),
]

# Unpinned Docker image tags
_UNPINNED_IMAGE = re.compile(r"^\s*(FROM|image:)\s+\S+:latest", re.IGNORECASE)

# Deprecated GitHub Actions runner images.
# Source of truth: GitHub-hosted runners documentation/changelog:
# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
# Keep this default baseline conservative; override via
#   DEPRECATED_GITHUB_RUNNERS
# if (comma-separated) to update without code changes.
_DEFAULT_DEPRECATED_RUNNERS = (
    "ubuntu-18.04",
    "ubuntu-20.04",
    "windows-2019",
    "macos-10.15",
)


def _load_deprecated_runners() -> set[str]:
    configured = os.getenv("DEPRECATED_GITHUB_RUNNERS", "")
    if not configured.strip():
        return set(_DEFAULT_DEPRECATED_RUNNERS)
    parsed = {item.strip() for item in configured.split(",") if item.strip()}
    return parsed if parsed else set(_DEFAULT_DEPRECATED_RUNNERS)


_DEPRECATED_RUNNERS = _load_deprecated_runners()


def _check_file(path: Path) -> Iterator[PipelineIssue]:
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return

    # Per-job timeout tracking for GitHub Actions workflow files.
    in_jobs_block = False
    jobs_indent: int | None = None
    current_job_name: str | None = None
    current_job_line: int | None = None
    current_job_indent: int | None = None
    current_job_has_timeout = False

    for lineno, line in enumerate(lines, 1):
        # Secret detection
        for pattern, label in _SECRET_PATTERNS:
            if pattern.search(line):
                yield PipelineIssue(
                    severity=IssueSeverity.CRITICAL,
                    file=str(path),
                    line=lineno,
                    message=f"{label} detected",
                    remediation=(
                        "Move the value to a GitHub Secret or Azure Key Vault reference. "
                        "Replace with ${{ secrets.MY_SECRET }} in workflows or "
                        "an environment-variable reference in Dockerfiles."
                    ),
                )
                break  # One secret finding per line is sufficient

        # Unpinned Docker tags
        if path.name in {
            "Dockerfile",
            "docker-compose.yml",
            "docker-compose.yaml",
        } or path.suffix in {".yml", ".yaml"}:
            if _UNPINNED_IMAGE.match(line):
                yield PipelineIssue(
                    severity=IssueSeverity.WARNING,
                    file=str(path),
                    line=lineno,
                    message="Unpinned Docker image tag ':latest' — non-reproducible builds",
                    remediation=(
                        "Pin to a specific version tag (e.g., python:3.12-slim) or "
                        "a digest (python:3.12-slim@sha256:...) for reproducible builds."
                    ),
                )

        # Deprecated runner images (GitHub Actions)
        if path.suffix in {".yml", ".yaml"}:
            for runner in _DEPRECATED_RUNNERS:
                runner_value_pattern = re.compile(
                    r"(?<![a-zA-Z0-9_\-])" + re.escape(runner) + r"(?![a-zA-Z0-9_\-])"
                )
                if runner_value_pattern.search(line):
                    yield PipelineIssue(
                        severity=IssueSeverity.WARNING,
                        file=str(path),
                        line=lineno,
                        message=f"Deprecated runner image '{runner}'",
                        remediation=(
                            "Update to a supported runner: ubuntu-22.04, ubuntu-24.04, "
                            "windows-2022, or macos-13. See GitHub hosted runners docs."
                        ),
                    )

        # Missing timeout-minutes in GitHub Actions jobs (check per job)
        if path.suffix in {".yml", ".yaml"}:
            stripped = line.strip()
            indent = len(line) - len(line.lstrip(" "))

            # Enter jobs block
            if not in_jobs_block and re.match(r"^\s*jobs\s*:\s*$", line):
                in_jobs_block = True
                jobs_indent = indent
                # Determine actual job indent dynamically from
                # first job key line.
                current_job_indent = None
                continue

            if in_jobs_block:
                # A top-level key block after jobs/indentation returns to
                # jobs_indent (or less) and is not a job — close the block.
                if (
                    stripped
                    and not stripped.startswith("#")
                    and jobs_indent is not None
                    and indent <= jobs_indent
                    and not re.match(r"^\s*jobs\s*:\s*$", line)
                ):
                    # Flush previous job if any
                    if current_job_name and not current_job_has_timeout:
                        yield PipelineIssue(
                            severity=IssueSeverity.INFO,
                            file=str(path),
                            line=current_job_line or lineno,
                            message=(
                                f"Job '{current_job_name}' has no "
                                "'timeout-minutes' — runaway jobs will block your "
                                "queue"
                            ),
                            remediation=(
                                "Add `timeout-minutes: 15` (or appropriate "
                                "value) under each job definition. "
                                "This prevents hung jobs from blocking the "
                                "runner queue indefinitely."
                            ),
                        )
                    in_jobs_block = False
                    jobs_indent = None
                    current_job_name = None
                    current_job_line = None
                    current_job_indent = None
                    current_job_has_timeout = False
                    continue

                # Detect job definitions: infer first job key
                # indent dynamically
                # (YAML allows variable indentation widths).
                # GitHub Actions job IDs can be letter/digit-led
                # and use
                # letters, digits, underscores, and hyphens.
                job_match = re.match(r"^(\s+)([a-zA-Z0-9][a-zA-Z0-9_-]*)\s*:", line)
                if job_match:
                    candidate_indent = len(job_match.group(1))
                    if (
                        current_job_indent is None
                        or candidate_indent == current_job_indent
                    ):
                        # New job found — flush previous
                        if current_job_name and not current_job_has_timeout:
                            yield PipelineIssue(
                                severity=IssueSeverity.INFO,
                                file=str(path),
                                line=current_job_line or lineno,
                                message=(
                                    f"Job '{current_job_name}' has no "
                                    "'timeout-minutes' — runaway jobs will "
                                    "block your queue"
                                ),
                                remediation=(
                                    "Add `timeout-minutes: 15` (or appropriate "
                                    "value) under each job definition. "
                                    "This prevents hung jobs from blocking "
                                    "the runner queue indefinitely."
                                ),
                            )
                        current_job_name = job_match.group(2)
                        current_job_line = lineno
                        current_job_indent = candidate_indent
                        current_job_has_timeout = False

                timeout_match = re.match(r"^(\s*)timeout-minutes\s*:", line)
                if (
                    timeout_match
                    and current_job_indent is not None
                    and len(timeout_match.group(1))
                    == (current_job_indent + _JOB_INDENT_OFFSET)
                ):
                    current_job_has_timeout = True

    # Finalize: last job in file might still be open
    if in_jobs_block and current_job_name and not current_job_has_timeout:
        yield PipelineIssue(
            severity=IssueSeverity.INFO,
            file=str(path),
            line=current_job_line or len(lines),
            message=(
                f"Job '{current_job_name}' has no "
                "'timeout-minutes' — runaway jobs will block your "
                "queue"
            ),
            remediation=(
                "Add `timeout-minutes: 15` (or appropriate "
                "value) under each job definition. "
                "This prevents hung jobs from blocking the runner "
                "queue indefinitely."
            ),
        )


def check_pipeline_health(target: Path) -> list[PipelineIssue]:
    """
    Scan a file or directory tree for pipeline health issues.

    Parameters
    ----------
    target : Path
        A single file or directory to scan recursively.

    Returns
    -------
    List of PipelineIssue. Empty = no issues found.
    """
    issues: list[PipelineIssue] = []
    paths: list[Path] = []

    if target.is_file():
        paths = [target]
    elif target.is_dir():
        paths = [
            p
            for p in target.rglob("*")
            if p.is_file() and (p.suffix in {".yml", ".yaml"} or p.name == "Dockerfile")
        ]
    else:
        raise FileNotFoundError(f"Path not found: {target}")

    for path in sorted(paths):
        issues.extend(_check_file(path))

    return issues


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Check CI/CD pipeline health")
    parser.add_argument(
        "--path", required=True, type=Path, help="File or directory to scan"
    )
    parser.add_argument("--fail-on-warning", action="store_true", default=False)
    args = parser.parse_args()

    issues = check_pipeline_health(args.path)

    if not issues:
        print(f"✅ Pipeline health check passed — no issues found in {args.path}")
        sys.exit(0)

    criticals = [issue for issue in issues if issue.severity == IssueSeverity.CRITICAL]
    warnings = [issue for issue in issues if issue.severity == IssueSeverity.WARNING]
    infos = [issue for issue in issues if issue.severity == IssueSeverity.INFO]

    severity_order = {
        IssueSeverity.CRITICAL: 0,
        IssueSeverity.WARNING: 1,
        IssueSeverity.INFO: 2,
    }

    print(
        f"Found {len(issues)} issue(s): "
        f"{len(criticals)} critical, {len(warnings)} warnings, "
        f"{len(infos)} info\n"
    )

    for issue in sorted(issues, key=lambda item: severity_order[item.severity]):
        print(issue)
        print()

    exit_code = 1 if (criticals or (args.fail_on_warning and warnings)) else 0
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
