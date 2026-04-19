# Ops Deep-Dive: CI/CD Patterns, Docker, Deployment & IaC

> Deep-dive reference. Loaded on demand for copy-ready CI/CD templates, Docker patterns, deployment configs, and IaC examples.

## GitHub Actions Patterns

### Standard CI Pipeline

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: uv sync --frozen
      - run: uvx ruff check .
      - run: uvx ruff format --check .

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: uv sync --frozen
      - run: uv run pytest --cov --cov-report=xml
      - uses: codecov/codecov-action@v4

  security:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - run: uvx pip-audit
```

### Reusable Workflow Pattern

```yaml
# .github/workflows/reusable-deploy.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      AZURE_CREDENTIALS:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - run: ./deploy.sh ${{ inputs.environment }}
```

### Matrix Strategy

```yaml
strategy:
  matrix:
    python-version: ["3.10", "3.11", "3.12"]
    os: [ubuntu-latest, windows-latest]
  fail-fast: false
```

### Caching

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements*.txt') }}
    restore-keys: ${{ runner.os }}-pip-
```

### PR Automation

```yaml
# Auto-label PRs by path
- uses: actions/labeler@v5
  with:
    repo-token: ${{ secrets.GITHUB_TOKEN }}
# Use CODEOWNERS and branch protection rules for enforcement
```

## Docker Patterns

### Python Dockerfile

```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN pip install poetry && poetry export -f requirements.txt -o requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./src/
USER nonroot
ENTRYPOINT ["python", "-m", "src.main"]
```

### Best Practices

- Multi-stage builds to minimize image size
- Pin base image versions (not just `latest`)
- Non-root user in production
- `.dockerignore` for build context optimization
- Health checks for orchestrated deployments

## Deployment Patterns

### Databricks Asset Bundles

```yaml
# databricks.yml
bundle:
  name: my-pipeline

environments:
  dev:
    workspace:
      host: https://adb-xxx.azuredatabricks.net
    resources:
      jobs:
        etl_daily:
          name: "[dev] ETL Daily"
          tasks:
            - task_key: bronze_ingest
              spark_python_task:
                python_file: src/bronze/ingest.py
```

### Azure Deployment

- Use `azure/login@v2` with OIDC (federated credentials), not service principal secrets
- Environment-specific configs via GitHub Environments
- Deployment slots for zero-downtime (staging -> production swap)

### Rollback Strategy

- Immutable artifacts: every build produces a versioned, unchangeable artifact
- Blue-green or canary for stateless services
- Database migrations: forward-only with backward compatibility
- Rollback plan documented BEFORE deployment, not after failure

## Release Management

### Semantic Versioning

- `MAJOR.MINOR.PATCH` (e.g., 2.1.3)
- MAJOR: breaking changes; MINOR: new features (backward compatible); PATCH: bug fixes only
- Pre-release: `1.0.0-rc.1`, `1.0.0-beta.2`

### Changelog Template

```markdown
## [1.2.0] - YYYY-MM-DD

### Added
- Feature X for improved Y (#123)

### Changed
- Refactored Z for better performance (#124)

### Fixed
- Bug in W that caused Q (#125)

### Security
- Updated dependency A to patch CVE-YYYY-XXXX (#126)
```

### Release Checklist

- [ ] All CI checks pass on release branch
- [ ] Changelog updated
- [ ] Version bumped in pyproject.toml / package.json
- [ ] Security scan clean
- [ ] Staging deployment tested
- [ ] Rollback plan documented
- [ ] Tag created and pushed

## Infrastructure as Code

### Principles

- Everything in version control
- Idempotent: running twice produces same result
- Environment parity: dev/staging/prod from same templates
- Secrets via vault references, never in templates

### Terraform Patterns

```hcl
module "storage" {
  source      = "./modules/storage"
  environment = var.environment
  location    = var.location
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatesa"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```