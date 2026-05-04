---
name: "Python Coding Standards"
description: "PEP 8 style, type hints, dataclasses/Pydantic, pathlib, and UV package management for Python files."
applyTo: "**/*.py"
version: "8.0"
updated: "2026-05-03"
---

# Python Coding Standards

---

## Python Style

- PEP 8 compliance. Use type hints (`typing` module) for all function signatures.
- F-strings for string formatting. Dataclasses or Pydantic for structured data models.
- `pathlib.Path` for all file operations. No `os.path` string concatenation.
- Minimal inline comments; only for non-obvious logic.
- **Use `logging` over `print`**: production code must use the `logging` module. `print` has no log levels, no destinations, and no structured output - it can't be silenced or redirected without code changes.
- **Exception naming**: custom exceptions must end with `Error` (e.g., `ValidationError`, `PipelineError`). Never `Exception` suffix.
- **Linting and type checking**: use `ruff check .` for linting, `ruff format .` for formatting, and `ty check` for type checking. Run both after every code change.

---

## Dependencies & Packaging

- Prefer stable/LTS libraries. Pin major versions; let minor/patch float.
- Document all versions in `pyproject.toml`. Use `uv.lock` as the lockfile (committed to repo).
- Add runtime deps via `uv add <pkg>`. Add dev tools via `uv add --dev <pkg>`.
- **Never use bare `pip install` for project deps.** Never install packages globally.
- Never hardcode secrets; use `.env.example` (no actual values).

---

## Python Environment (UV)

- **UV is the standard package manager.** Use `uv sync` to install from lockfile, `uv add` to add deps.
- Check for `.venv` in project root before running Python. UV creates it automatically via `uv sync`.
- Prefer `uv run <script>` to execute Python (auto-activates the venv).
- For one-off CLI tools not in project deps, use `uvx <tool>` (e.g., `uvx ruff check .`).
