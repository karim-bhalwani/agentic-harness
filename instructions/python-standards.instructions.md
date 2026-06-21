---
name: "Python Coding Standards"
description: "PEP 8 style, type hints, dataclasses/Pydantic, pathlib, and UV package management for Python files."
applyTo: "**/*.py"
version: "9.0"
updated: "01-July-2026"
---

# Python Coding Standards

---

## Python Style

- PEP 8 compliance. Use type hints (`typing` module) for all function signatures.
- F-strings for string formatting. Dataclasses or Pydantic for structured data models.
- `pathlib.Path` for all file operations. No `os.path` string concatenation.
- Minimal inline comments; use only for logic that cannot be immediately understood from the code or function names.
- **Use `logging` over `print`**: production code must use the `logging` module. `print` has no log levels, no destinations, and no structured output - it can't be silenced or redirected without code changes.
- **Exception naming**: custom exceptions must end with `Error` (e.g., `ValidationError`, `PipelineError`). Never `Exception` suffix.
- **Linting and type checking**: use `ruff check .` for linting, `ruff format .` for formatting, and `ty check` for type checking. Run both after every code change.
  - **Error handling**: If `ruff`, `ty`, or other tools are unavailable, ensure they are installed as dev dependencies via `uv add --dev ruff` or `uv add --dev pyright` (for type checking). Then run `uv sync` to install. Use `uv run ruff check .` to execute through the virtual environment if PATH issues occur.
- **Legacy code**: For existing code that does not comply with these standards, prioritize incremental updates to align with these standards during active development. No need to refactor non-active legacy code.
- **`minion:` comment convention**: when intentionally taking a simpler path at an early rung of the pre-write simplicity ladder (e.g., using a linear scan instead of an index, a naive heuristic instead of a full algorithm), mark it with a `minion:` comment that names the ceiling and the upgrade path. Example: `# minion: linear scan OK for < 500 items; switch to bisect_left if list grows`. This keeps shortcuts visible and grep-able for tech-debt reviews.

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
- **Error handling**: If `uv` commands fail (e.g., missing dependencies, corrupted lockfiles), check the error output, verify `pyproject.toml` and `uv.lock` integrity, and re-run `uv sync`. For persistent issues, delete `.venv` and run `uv sync` again.
