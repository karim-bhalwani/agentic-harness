# TDD Discipline (Red-Green-Refactor)

Work in **vertical slices** (tracer bullets): one test → minimal code to pass → repeat. Each cycle teaches what the next test should cover.

> **Anti-pattern: horizontal slices**: Do NOT write all tests first, then all code. Tests written in bulk test _imagined_ behavior, not actual behavior. They become insensitive to real changes and break on refactors that don't change behavior.

**Per-cycle checklist:**
- [ ] Test describes behavior (WHAT), not implementation (HOW)
- [ ] Test uses the public interface only (no mocking of internal collaborators)
- [ ] Code is minimal to pass this test (no speculative features)
- [ ] Tests pass before any refactoring (**never refactor while RED**)

Use the sprint contract's acceptance criteria and error scenarios to derive test cases.
