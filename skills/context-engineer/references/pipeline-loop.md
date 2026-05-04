# Pipeline Loop Awareness Protocol

> Canonical reference for agents participating in the Release Manager → Senior Developer → Guardian → Release Manager review cycle.

## The Cycle

The pipeline runs an intentional 3-agent loop: after a Guardian `NEEDS WORK` or `FAIL`, fixes re-enter review automatically; after a Release Manager gate failure, the fix loop returns for re-validation.

## Cross-Session Iteration Tracking

On startup, read `.copilot/state/SESSION_STATE.md` and check the `Pipeline Loop` section for `Iteration Count`:

- If present, increment it.
- If absent, set it to 1.
- Write the updated count back when saving session state. (Guardian, which cannot write files, must include the updated count in its session state output block for the user to save.)

This ensures the circuit breaker works across sessions, not just within one.

## Circuit Breaker (Three-Strike Rule)

If `Iteration Count` reaches **3** (or the same failing test, finding, or gate has been handed back three times without resolution), STOP and surface the loop to the user instead of attempting a fourth handoff. Describe what was tried across iterations and why the loop is not converging.

## Per-Agent Notes

- **Senior Developer**: do not re-introduce findings that were previously fixed. Read the Guardian review report carefully before starting.
- **Guardian**: use finding history across cycles to detect regressions introduced by fix attempts.
- **Release Manager**: note in the Gate Report when this is a re-run following a previous fix cycle, and include the current iteration count.
