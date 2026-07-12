"""
scaffold_spec.py
================
Scaffold a structured system specification (SPEC.md) for a module or service.

Generates a fully-formed specification template with all required sections,
pre-filled where information is provided and clearly marked TODO where human
input is needed. Follows the architect skill's SPEC.md template format.

Usage (agent context):
    from skills.architect.scripts.scaffold_spec import scaffold_spec, SpecConfig
    config = SpecConfig(
        module_name="AuthService",
        description="Handles user authentication and session management",
        inputs=["LoginRequest (email, password)", "RefreshTokenRequest"],
        outputs=["AuthToken", "SessionPayload", "AuthError"],
        consumers=["API gateway", "Frontend SPA"],
    )
    print(scaffold_spec(config))

Usage (CLI):
    python scaffold_spec.py --module AuthService --description "Handles auth" \\
        --inputs "LoginRequest" "RefreshTokenRequest" \\
        --outputs "AuthToken" "AuthError" \\
        --consumers "API gateway"
"""

from __future__ import annotations

import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

# Allow running as a standalone script: ensure the repo root (which owns the
# `tests` package) is importable regardless of the current working directory.
_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tests.contracts.schema_versions import CURRENT_SCHEMA_VERSIONS  # noqa: E402


_TODO = "<!-- TODO: fill in -->"


# Canonical machine contract: YAML frontmatter consumed by verify_spec.py and
# validated against tests/contracts/schemas/spec.schema.json. Mirrors the
# frontmatter emitted by scaffold_artifacts.py so both producers agree.
def _frontmatter(config: SpecConfig) -> str:
    return (
        "---\n"
        f"spec_schema_version: {CURRENT_SCHEMA_VERSIONS['SPEC.md']}\n"
        f'version: "{config.version}"\n'
        'status: "Draft"\n'
        f'date: "{config.date}"\n'
        f'owner: "{config.author}"\n'
        'holdout_reference: ".copilot/holdout/HOLDOUT.md"\n'
        'scope_mode: "EXPANSION"\n'
        "---\n\n"
    )


@dataclass
class SpecConfig:
    module_name: str
    description: str = _TODO
    version: str = "0.1.0"
    author: str = _TODO
    inputs: list[str] = field(default_factory=list)
    outputs: list[str] = field(default_factory=list)
    consumers: list[str] = field(default_factory=list)
    dependencies: list[str] = field(default_factory=list)
    constraints: list[str] = field(default_factory=list)
    non_goals: list[str] = field(default_factory=list)
    date: str = field(default_factory=lambda: str(date.today()))


def _bullet_list(items: list[str], fallback: str = _TODO) -> str:
    if not items:
        return f"- {fallback}"
    return "\n".join(f"- {item}" for item in items)


def scaffold_spec(config: SpecConfig) -> str:
    """
    Generate a structured SPEC.md document from a SpecConfig.

    Returns
    -------
    str
        Markdown document string ready to write to SPEC.md.
    """
    return (
        _frontmatter(config)
        + f"""# Specification: {config.module_name}

> v{config.version} | {config.date} | Author: {config.author}  
> Status: DRAFT — pending architect review

---

## 1. Purpose

{config.description}

---

## 2. Primitives (Public API Surface)

### 2.1 Inputs

{_bullet_list(config.inputs)}

### 2.2 Outputs

{_bullet_list(config.outputs)}

### 2.3 Errors

- {_TODO} (list all error types this module can produce, with HTTP status or error code)

---

## 3. Contracts

### 3.1 Invariants (always true)

- {_TODO} (conditions that must hold at all times, e.g. "token is always signed")

### 3.2 Preconditions (caller's responsibility)

- {_TODO} (what the caller must ensure before invoking this module)

### 3.3 Postconditions (this module guarantees)

- {_TODO} (what this module guarantees on success)

---

## 4. Module Boundaries

### 4.1 Consumers (who calls this)

{_bullet_list(config.consumers)}

### 4.2 Dependencies (what this calls)

{_bullet_list(config.dependencies)}

### 4.3 What this module does NOT do

{_bullet_list(config.non_goals, fallback="TODO: list explicit non-goals")}

---

## 5. Data Flows

```
{_TODO}
# Example:
# LoginRequest -> validate credentials -> check rate limit -> issue AuthToken
# Each arrow = a transformation or IO operation; label with data shape
```

---

## 6. Constraints & Non-Functional Requirements

{_bullet_list(config.constraints, fallback="TODO: latency, throughput, security, compliance requirements")}

---

## 7. Open Questions

| # | Question | Owner | Decision |
|---|----------|-------|----------|
| 1 | {_TODO}  | {_TODO} | OPEN |

---

## 8. Acceptance Criteria

- [ ] {_TODO} (measurable, testable condition 1)
- [ ] {_TODO} (measurable, testable condition 2)
- [ ] {_TODO} (measurable, testable condition 3)

---

## 9. Revision History

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 0.1.0 | {config.date} | {config.author} | Initial scaffold |

---

_Generated by `architect/scripts/scaffold_spec.py`. Fill all `{_TODO}` markers before handoff to `implementer`._
"""
    )


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Scaffold a SPEC.md for a module or service")
    parser.add_argument("--module", required=True, help="Module or service name")
    parser.add_argument("--description", default=_TODO, help="One-sentence purpose")
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--author", default=_TODO)
    parser.add_argument("--inputs", nargs="*", default=[], help="Input types/contracts")
    parser.add_argument("--outputs", nargs="*", default=[], help="Output types/contracts")
    parser.add_argument("--consumers", nargs="*", default=[], help="Modules that call this")
    parser.add_argument("--dependencies", nargs="*", default=[], help="Modules this calls")
    parser.add_argument("--constraints", nargs="*", default=[], help="Non-functional requirements")
    parser.add_argument("--non-goals", nargs="*", default=[], dest="non_goals")
    parser.add_argument("--output", default=None, help="Write to file (default: stdout)")
    args = parser.parse_args()

    config = SpecConfig(
        module_name=args.module,
        description=args.description,
        version=args.version,
        author=args.author,
        inputs=args.inputs,
        outputs=args.outputs,
        consumers=args.consumers,
        dependencies=args.dependencies,
        constraints=args.constraints,
        non_goals=args.non_goals,
    )

    output = scaffold_spec(config)

    if args.output:
        from pathlib import Path

        Path(args.output).write_text(output, encoding="utf-8")
        print(f"[OK] Spec written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
