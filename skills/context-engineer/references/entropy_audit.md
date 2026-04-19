# Entropy Audit Checklist

> Run during retrospectives or on a quarterly cadence.
> Scans the codebase for accumulated technical debt, pattern drift, and stale artifacts.

## 1. Pattern Consistency

- [ ] Are there multiple approaches to the same problem? (e.g., 3 different logging patterns, mixed error handling styles)
- [ ] Do new files follow the conventions documented in `CODEBASE_PATTERNS.md`?
- [ ] Are there imports or dependencies that contradict the documented tech stack?

**If deviations found**: Identify the "golden pattern" (most common or documented approach) and list files that deviate. Recommend a targeted refactoring PR per pattern.

## 2. Documentation Freshness

- [ ] Does `PROJECT_CONTEXT.md` match the actual tech stack versions?
- [ ] Do documented build/test commands still work?
- [ ] Are module descriptions in `ARCHITECTURE.md` still accurate?
- [ ] Are there documented APIs or contracts that no longer exist in code?

**If stale docs found**: Mark each with `[STALE: reason]` and recommend specific updates.

## 3. Dead Code & Abandoned Work

- [ ] Commented-out code blocks (> 5 lines)
- [ ] Unused imports across multiple files
- [ ] Feature flags that are always on or always off
- [ ] Files with no references from any other file
- [ ] Incomplete implementations marked with TODO/FIXME older than 2 cycles

**If dead code found**: List each instance with file path and line range. Recommend removal PR.

## 4. Dependency Health

- [ ] Are all dependencies still maintained (last release < 12 months)?
- [ ] Are there known CVEs in current dependency versions?
- [ ] Are there duplicate dependencies serving the same purpose?
- [ ] Are dependency versions pinned (not floating on latest)?

**If issues found**: List each with severity (CVE = Critical, unmaintained = Medium, duplicate = Low).

## 5. Convention Drift

- [ ] Do test file names follow the project's naming convention?
- [ ] Are new modules placed in the correct directory per the architecture doc?
- [ ] Are error messages agent-legible (contain remediation hints)?
- [ ] Do new endpoints/functions have the required type hints and docstrings?

**If drift found**: Cite the convention source and the deviating files.

## Output Format

```markdown
### Entropy Audit Results

**Date**: YYYY-MM-DD
**Scope**: [full repo / specific modules]
**Auditor**: context-engineer (via /retrospective)

| Category | Items Found | Severity | Recommended Action |
|----------|-------------|----------|-------------------|
| Pattern consistency | N deviations | Medium | Consolidation PR |
| Documentation freshness | N stale docs | Low | Doc update PR |
| Dead code | N instances | Low | Cleanup PR |
| Dependency health | N issues | [varies] | Update/replace |
| Convention drift | N deviations | Low | Fix in next sprint |

**Overall Entropy Score**: LOW / MEDIUM / HIGH
(LOW = 0-3 items, MEDIUM = 4-8 items, HIGH = 9+ items)
```


