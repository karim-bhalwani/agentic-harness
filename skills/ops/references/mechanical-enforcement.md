# Mechanical Enforcement Templates

> Copy-ready configuration snippets for setting up mechanical enforcement in a target project. Load this reference when setting up a new project or promoting a behavioral rule to a mechanical check.

## Pre-commit Hooks

Install in the target project:

```bash
pip install pre-commit
pre-commit install   # activates hooks in .git/hooks/
```

### Base Configuration

```yaml
# .pre-commit-config.yaml
repos:
  # Code quality (Python)
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  # Type checking
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.14.0
    hooks:
      - id: mypy
        additional_dependencies: [pydantic]

  # Secret detection
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
```

### Custom Structural Hooks

Add these under `repo: local` for project-specific enforcement. Every error message starts with `REMEDIATION:` so agents know the fix.

```yaml
  - repo: local
    hooks:
      # Project Bible must exist
      - id: project-bible-exists
        name: Project Bible exists
        entry: python -c "from pathlib import Path; assert Path('.copilot/context/PROJECT_CONTEXT.md').exists(), 'REMEDIATION - Run brownfield-discovery or greenfield-interview to create .copilot/context/PROJECT_CONTEXT.md'"
        language: system
        pass_filenames: false
        always_run: true

      # Holdout isolation: implementation code cannot import holdout
      - id: holdout-isolation
        name: No holdout imports in implementation code
        entry: python -c "
import sys, re, pathlib
violations = []
for f in pathlib.Path('src').rglob('*.py'):
    for i, line in enumerate(f.read_text().splitlines(), 1):
        if re.search(r'(from|import).*holdout', line):
            violations.append(f'{f}:{i}')
if violations:
    print('HOLDOUT ISOLATION VIOLATION')
    print('REMEDIATION - Only the Guardian agent reads holdout files during review. Remove these imports:')
    print('\n'.join(violations))
    sys.exit(1)
"
        language: system
        pass_filenames: false
        types: [python]

      # Spec must exist on feature branches
      - id: spec-before-code
        name: Spec exists for feature branches
        entry: python -c "
import subprocess, sys, pathlib
branch = subprocess.check_output(['git', 'branch', '--show-current']).decode().strip()
if branch.startswith(('feature/', 'feat/')):
    if not list(pathlib.Path('.copilot/specs').glob('*.md')):
        print(f'SPEC MISSING on branch {branch}')
        print('REMEDIATION - Run /design to create a spec at .copilot/specs/ before implementing.')
        sys.exit(1)
"
        language: system
        pass_filenames: false
        always_run: true

      # Agent-legible error messages (wire to scripts/lint_agent_legible_errors.py)
      - id: agent-legible-errors
        name: Error messages contain remediation hints
        entry: python tools/lint_agent_legible_errors.py src/
        language: system
        pass_filenames: false
        types: [python]
```

## Ruff Configuration

Add to the target project's `pyproject.toml`. Adapt rule selection to the project's language and framework.

```toml
[tool.ruff]
target-version = "py312"
line-length = 120

[tool.ruff.lint]
select = [
    "E", "W",   # pycodestyle
    "F",         # pyflakes
    "I",         # isort
    "N",         # pep8-naming
    "UP",        # pyupgrade
    "S",         # bandit (security)
    "B",         # bugbear
    "A",         # builtins shadowing
    "T20",       # no print() in production code
    "SIM",       # simplify
    "RUF",       # ruff-specific
]

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]
".copilot/holdout/**" = ["ALL"]
"scripts/**" = ["T20"]
```

## GitHub Actions Enforcement Workflow

Runs on every PR as a safety net for anything pre-commit missed.

```yaml
# .github/workflows/mega-minions-enforcement.yml
name: Mega Minions Enforcement

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  structural-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Project Bible freshness
        run: |
          BIBLE=".copilot/context/PROJECT_CONTEXT.md"
          if [ ! -f "$BIBLE" ]; then
            echo "::error::Project Bible missing. REMEDIATION: Run brownfield-discovery or greenfield-interview."
            exit 1
          fi
          BIBLE_MOD=$(git log -1 --format="%ct" -- "$BIBLE" 2>/dev/null || echo 0)
          NEWEST_SRC=$(git log -1 --format="%ct" -- "src/" 2>/dev/null || echo 0)
          if [ "$NEWEST_SRC" -gt "$BIBLE_MOD" ]; then
            echo "::warning::Project Bible is older than latest source changes. Run /retrospective to update context."
          fi

      - name: Doc freshness
        run: |
          CHANGED=$(git diff --name-only origin/main...HEAD 2>/dev/null || echo "")
          SRC_CHANGED=$(echo "$CHANGED" | grep -c "^src/" || true)
          DOC_CHANGED=$(echo "$CHANGED" | grep -c "^docs/\|^README\|^\.copilot/context/" || true)
          if [ "$SRC_CHANGED" -gt 5 ] && [ "$DOC_CHANGED" -eq 0 ]; then
            echo "::warning::$SRC_CHANGED source files changed but no docs updated. Consider updating docs/ or PROJECT_CONTEXT.md."
          fi

      - name: Holdout isolation
        run: |
          if grep -rn "from.*holdout\|import.*holdout" src/ --include="*.py" 2>/dev/null; then
            echo "::error::Implementation code imports from holdout directory. REMEDIATION: Only Guardian reads holdout files. Remove the import."
            exit 1
          fi

  code-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install ruff mypy
      - name: Lint
        run: ruff check . --output-format=github
      - name: Format check
        run: ruff format --check .
      - name: Type check
        run: mypy src/ --ignore-missing-imports
```


