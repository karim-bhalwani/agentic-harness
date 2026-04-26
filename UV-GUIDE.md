# UV Guide

> Practical reference for using [UV](https://docs.astral.sh/uv/) as the standard Python package manager across all projects.

---

## 1. Installing UV (No Admin Required)

UV installs to your user directory (`%USERPROFILE%\.local\bin`). No admin privileges needed.

```powershell
irm https://astral.sh/uv/install.ps1 | iex
```

Verify:

```powershell
uv --version
```

Upgrade:

```powershell
uv self update
```

### Shell Autocompletion (Optional)

```powershell
Add-Content -Path $PROFILE -Value '(& uv generate-shell-completion powershell) | Out-String | Invoke-Expression'
```

Restart your terminal after adding autocompletion.

---

## 2. Starting a New Project

Run these **before** calling Greenfield Interview or Brownfield Discovery agents.

### Create from Scratch

```powershell
uv init my-project
cd my-project
```

This generates:

- `pyproject.toml` (project metadata and dependencies)
- `.python-version` (pinned Python version)
- `main.py` (starter script)

### Initialize in an Existing Directory

```powershell
cd my-existing-project
uv init
```

### Pin a Specific Python Version

```powershell
uv python pin 3.11
```

UV will auto-download the pinned version if not already installed.

### Install Python Versions

```powershell
# List available versions
uv python list

# Install a specific version
uv python install 3.11
```

---

## 3. Essential Commands Cheatsheet

### Dependencies

| Command | What it does |
|---------|-------------|
| `uv add <pkg>` | Add a dependency (updates `pyproject.toml` + `uv.lock`) |
| `uv add --dev <pkg>` | Add a dev dependency (ruff, ty, pytest, etc.) |
| `uv add "fastapi>=0.100"` | Add with version constraint |
| `uv remove <pkg>` | Remove a dependency |
| `uv lock` | Regenerate `uv.lock` without installing |
| `uv sync` | Install everything from `uv.lock` into `.venv` |
| `uv sync --frozen` | Install from lockfile, fail if lockfile is stale (CI use) |
| `uv tree` | View dependency tree |

### Running Code

| Command | What it does |
|---------|-------------|
| `uv run python app.py` | Run a script in the project venv (auto-syncs first) |
| `uv run pytest` | Run pytest from the project venv |
| `uvx ty check .` | Run ty type checker (Astral, Rust-based) |

### One-Off Tools (Not in Project Deps)

| Command | What it does |
|---------|-------------|
| `uvx ruff check .` | Run ruff without adding it to the project |
| `uvx pip-audit` | Run pip-audit ephemerally |
| `uvx black --check .` | Run black without installing it |

### Project Management

| Command | What it does |
|---------|-------------|
| `uv init` | Initialize a new project |
| `uv init --lib` | Initialize as a library (with `src/` layout) |
| `uv build` | Build distribution archives (sdist + wheel) |
| `uv publish` | Publish to PyPI |

---

## 4. Files to Commit

| File | Commit? | Purpose |
|------|---------|---------|
| `pyproject.toml` | Yes | Project metadata, dependencies, tool config |
| `uv.lock` | Yes | Exact locked versions for reproducible installs |
| `.python-version` | Yes | Pinned Python version |
| `.venv/` | No | Local virtual environment (add to `.gitignore`) |

---

## 5. Migrating from pip / requirements.txt

### Quick Migration

```powershell
# Convert an existing requirements.txt to a UV project
uv init
$deps = Get-Content requirements.txt | Where-Object { $_ -and $_ -notmatch '^#' }
uv add @deps
Remove-Item requirements.txt
```

### From pip-tools (requirements.in)

```powershell
uv init
$deps = Get-Content requirements.in | Where-Object { $_ -and $_ -notmatch '^#' }
uv add @deps
```

### Verify

```powershell
uv sync
uv run python -c "import your_package; print('OK')"
```

See the full [migration guide](https://docs.astral.sh/uv/guides/migration/pip-to-project/).

---

## 6. CI/CD Integration (GitHub Actions)

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: astral-sh/setup-uv@v4
  - uses: actions/setup-python@v5
    with:
      python-version-file: ".python-version"
  - run: uv sync --frozen
  - run: uv run pytest
```

Key points:

- `astral-sh/setup-uv@v4` installs UV in the runner
- `uv sync --frozen` fails if `uv.lock` is stale (catches uncommitted dependency changes)
- Use `uvx <tool>` for tools not in your project deps (e.g., `uvx pip-audit`)

---

## 7. pyproject.toml Structure (UV-Managed)

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Project description"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "fastapi>=0.100",
    "pydantic>=2.0",
]

[dependency-groups]
dev = [
    "pytest>=8.0",
    "ruff>=0.4",
    "ty>=0.1",
]

[tool.ruff]
line-length = 120
target-version = "py313"

[tool.ty.rules]
all = "warn"
```

---

## 8. Common Workflows

### Add a New Dependency

```powershell
uv add httpx
# pyproject.toml updated, uv.lock regenerated, package installed
```

### Set Up Dev Tools

```powershell
uv add --dev ruff ty pytest pytest-cov
```

### Run Tests

```powershell
uv run pytest --cov --cov-report=term-missing
```

### Format and Lint

```powershell
uvx ruff check . --fix
uvx ruff format .
```

### Update All Dependencies

```powershell
uv lock --upgrade
uv sync
```

### Update a Single Dependency

```powershell
uv lock --upgrade-package httpx
uv sync
```

---

## 9. Tips

- **Never use bare `pip install`** for project dependencies. It bypasses `pyproject.toml` and `uv.lock`.
- **`uv run` auto-syncs**: it checks `uv.lock` and installs missing packages before running your command.
- **`uvx` is ephemeral**: the tool runs in a temporary environment and leaves no trace in your project.
- **UV manages Python itself**: no need for pyenv or manual Python installs. Use `uv python install 3.13`.
- **Speed**: UV resolves and installs 10-100x faster than pip. Cold installs that took minutes take seconds.
- **Private indexes**: configure in `pyproject.toml` under `[[tool.uv.index]]` or via `UV_EXTRA_INDEX_URL`.

---

## Links

- [UV Documentation](https://docs.astral.sh/uv/)
- [Installation](https://docs.astral.sh/uv/getting-started/installation/)
- [Project Guide](https://docs.astral.sh/uv/guides/projects/)
- [Migration from pip](https://docs.astral.sh/uv/guides/migration/pip-to-project/)
- [GitHub Actions Integration](https://docs.astral.sh/uv/guides/integration/github/)
- [Docker Integration](https://docs.astral.sh/uv/guides/integration/docker/)
