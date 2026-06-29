# Self-Review Checklist (Step 6)

Before declaring work done or handing off to Guardian:

1. **Re-read changed files** - scan the actual diff, not just tool output
2. **Intent check** - does the change solve the problem stated in the spec/mini-contract, not a different problem?
3. **Debris sweep** - remove dead imports, commented-out code, debug prints, unresolved TODOs
4. **Readability gut-check** - would a new team member understand this without asking the author?
5. **Fix in-place** - if any issue is found, fix it now (don't log it for later)

This is a semantic review ("did I do the right thing well?"), not a mechanical gate ("did the linter pass?"). It complements, not replaces, the verification-before-completion skill.
