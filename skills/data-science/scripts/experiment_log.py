"""
experiment_log.py
=================
Append-only experiment ledger for data science iterations.

Every iteration of a model (or analysis, or experiment) is logged with metrics, 
a description, and a keep/discard decision. The ledger is the project memory; 
the meta-loop (human or agent) reads it before proposing the next change.

Stored as JSON Lines (.jsonl) for easy programmatic access while remaining
human-readable. One line per experiment. Append-only; never edit past entries.

Usage (agent context):
    from skills.data_science.scripts.experiment_log import (
        log_experiment,
        read_experiments,
        get_baseline,
        decide_keep_discard,
    )

    log_experiment(
        ledger_path="experiments/model_log.jsonl",
        algo="XGBoost",
        cv_mean=0.812,
        cv_std=0.014,
        test_score=0.805,
        primary_metric="roc_auc",
        decision="Keep",
        description="Added rolling 7-day mean as feature; +0.012 over baseline",
        change_kind="features",
    )

Usage (CLI):
    python experiment_log.py log --ledger experiments/log.jsonl \
        --algo XGBoost --cv-mean 0.812 --cv-std 0.014 --test 0.805 \
        --metric roc_auc --decision Keep \
        --description "Added rolling 7-day mean as feature" \
        --change-kind features

    python experiment_log.py show --ledger experiments/log.jsonl
    python experiment_log.py decide --ledger experiments/log.jsonl \
        --candidate-cv 0.815 --candidate-test 0.808 --simpler

Decision rules:
  - Score improved -> Keep
  - Score equal AND candidate is simpler -> Keep (simplification win)
  - Score equal, no simplification -> Discard
  - Score degraded -> Discard

Ledger lifecycle:
  ONE ledger file = ONE fixed evaluation harness (test set + primary metric +
  target definition). If any of those change, START A NEW LEDGER FILE with a
  new path. Mixing metrics or test sets in the same ledger destroys the
  comparability that the keep/discard rules depend on. The 'log' subcommand
  prints a warning when the requested metric does not match the most recent
  entry in the file.

Exit codes:
    0 = OK
    1 = Decision = Discard (when running 'decide')
    2 = Invalid input
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path


class Decision(str, Enum):
    KEEP = "Keep"
    DISCARD = "Discard"
    PENDING = "Pending"


class ChangeKind(str, Enum):
    """One change per iteration. Pick the dominant category."""

    FEATURES = "features"
    ALGORITHM = "algorithm"
    HYPERPARAMETERS = "hyperparameters"
    PREPROCESSING = "preprocessing"
    DATA = "data"
    EVALUATION = "evaluation"
    OTHER = "other"


# Default tolerance for "score equal" comparison. Anything within this many
# points (in either direction) is treated as a tie.
DEFAULT_TIE_TOLERANCE = 0.002


@dataclass
class ExperimentEntry:
    timestamp: str
    algo: str
    primary_metric: str
    cv_mean: float | None
    cv_std: float | None
    test_score: float | None
    decision: str
    change_kind: str
    description: str
    extra_metrics: dict[str, float] = field(default_factory=dict)
    notes: str = ""

    @classmethod
    def new(
        cls,
        algo: str,
        primary_metric: str,
        cv_mean: float | None,
        cv_std: float | None,
        test_score: float | None,
        decision: Decision | str,
        change_kind: ChangeKind | str,
        description: str,
        extra_metrics: dict[str, float] | None = None,
        notes: str = "",
    ) -> "ExperimentEntry":
        if isinstance(decision, Decision):
            decision = decision.value
        if isinstance(change_kind, ChangeKind):
            change_kind = change_kind.value
        return cls(
            timestamp=datetime.now(timezone.utc).isoformat(timespec="seconds"),
            algo=algo,
            primary_metric=primary_metric,
            cv_mean=cv_mean,
            cv_std=cv_std,
            test_score=test_score,
            decision=str(decision),
            change_kind=str(change_kind),
            description=description.strip(),
            extra_metrics=extra_metrics or {},
            notes=notes.strip(),
        )


def log_experiment(
    ledger_path: str | Path,
    algo: str,
    primary_metric: str,
    cv_mean: float | None,
    cv_std: float | None,
    test_score: float | None,
    decision: Decision | str,
    change_kind: ChangeKind | str,
    description: str,
    extra_metrics: dict[str, float] | None = None,
    notes: str = "",
    warn_stream=sys.stderr,
) -> ExperimentEntry:
    """Append a single experiment entry to the ledger.

    Prints a warning to ``warn_stream`` if ``primary_metric`` does not match
    the most recent entry in the ledger. A metric mismatch usually means the
    harness changed (different test set or different metric definition); the
    keep/discard rules require an unchanged harness, so a new ledger file
    should be started instead of appending here.
    """
    if not description or len(description.strip()) < 10:
        raise ValueError(
            "description must be at least 10 characters; "
            "describe WHAT changed and WHY in plain English"
        )

    # Metric-mismatch guard: warn if the new entry's metric differs from
    # the most recent entry in the same ledger.
    existing = read_experiments(ledger_path)
    if existing:
        last_metric = existing[-1].primary_metric
        if last_metric != primary_metric:
            print(
                f"WARNING: ledger {ledger_path} last entry uses metric "
                f"{last_metric!r}, but new entry uses {primary_metric!r}. "
                "Mixing metrics in one ledger breaks keep/discard comparability. "
                "Start a new ledger file when the harness changes.",
                file=warn_stream,
            )

    entry = ExperimentEntry.new(
        algo=algo,
        primary_metric=primary_metric,
        cv_mean=cv_mean,
        cv_std=cv_std,
        test_score=test_score,
        decision=decision,
        change_kind=change_kind,
        description=description,
        extra_metrics=extra_metrics,
        notes=notes,
    )

    path = Path(ledger_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(asdict(entry), ensure_ascii=False) + "\n")
    return entry


def read_experiments(ledger_path: str | Path) -> list[ExperimentEntry]:
    """Read all entries from the ledger (oldest first)."""
    path = Path(ledger_path)
    if not path.exists():
        return []
    entries: list[ExperimentEntry] = []
    with path.open("r", encoding="utf-8") as f:
        for i, line in enumerate(f, start=1):
            stripped = line.strip()
            if not stripped:
                continue
            try:
                data = json.loads(stripped)
                entries.append(ExperimentEntry(**data))
            except (json.JSONDecodeError, TypeError) as e:
                raise ValueError(
                    f"Corrupt ledger at line {i} of {path}: {e}. "
                    "Investigate before logging more entries."
                ) from e
    return entries


def get_baseline(
    ledger_path: str | Path, primary_metric: str
) -> ExperimentEntry | None:
    """Return the best Kept entry for the given metric, or None."""
    entries = read_experiments(ledger_path)
    kept = [
        e
        for e in entries
        if e.decision == Decision.KEEP.value
        and e.primary_metric == primary_metric
        and e.test_score is not None
    ]
    if not kept:
        return None
    return max(kept, key=lambda e: e.test_score or 0.0)


def decide_keep_discard(
    baseline_score: float | None,
    candidate_score: float,
    candidate_is_simpler: bool = False,
    higher_is_better: bool = True,
    tie_tolerance: float = DEFAULT_TIE_TOLERANCE,
) -> tuple[Decision, str]:
    """
    Apply the AUTOAGENT keep/discard rules.

    Returns (decision, rationale).
    """
    if baseline_score is None:
        return Decision.KEEP, "No baseline yet; this becomes the baseline."

    if higher_is_better:
        delta = candidate_score - baseline_score
    else:
        delta = baseline_score - candidate_score

    if delta > tie_tolerance:
        return (
            Decision.KEEP,
            f"Score improved by {abs(delta):.4f} (tolerance {tie_tolerance}).",
        )
    if delta < -tie_tolerance:
        return (
            Decision.DISCARD,
            f"Score degraded by {abs(delta):.4f} (tolerance {tie_tolerance}).",
        )
    # Within tolerance -> tie
    if candidate_is_simpler:
        return (
            Decision.KEEP,
            "Score equal within tolerance and candidate is simpler "
            "(simplification win).",
        )
    return (
        Decision.DISCARD,
        "Score equal within tolerance and no simplification gained.",
    )


def summarize_ledger(entries: list[ExperimentEntry]) -> str:
    """Format the ledger as a compact human-readable table."""
    if not entries:
        return "Ledger is empty."
    header = (
        "timestamp                | algo            | metric    | cv_mean | "
        "test    | decision  | change         | description"
    )
    lines = [header, "-" * 130]
    for e in entries:
        cv = f"{e.cv_mean:.4f}" if e.cv_mean is not None else "  -   "
        ts = f"{e.test_score:.4f}" if e.test_score is not None else "  -   "
        lines.append(
            f"{e.timestamp:<24} | {e.algo:<15} | {e.primary_metric:<9} | "
            f"{cv:>7} | {ts:>7} | {e.decision:<9} | {e.change_kind:<14} | "
            f"{e.description[:60]}"
        )
    return "\n".join(lines)


def _parse_extra_metrics(values: list[str] | None) -> dict[str, float]:
    if not values:
        return {}
    out: dict[str, float] = {}
    for v in values:
        if "=" not in v:
            raise ValueError(f"--extra expects key=value pairs, got {v!r}")
        k, val = v.split("=", 1)
        out[k.strip()] = float(val)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description="Data science experiment ledger")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_log = sub.add_parser("log", help="Append an experiment entry")
    p_log.add_argument("--ledger", type=Path, required=True)
    p_log.add_argument("--algo", required=True)
    p_log.add_argument(
        "--metric", required=True, help="primary metric name (e.g. roc_auc)"
    )
    p_log.add_argument("--cv-mean", type=float, default=None)
    p_log.add_argument("--cv-std", type=float, default=None)
    p_log.add_argument("--test", type=float, default=None, dest="test_score")
    p_log.add_argument(
        "--decision",
        required=True,
        choices=[d.value for d in Decision],
    )
    p_log.add_argument(
        "--change-kind",
        required=True,
        choices=[c.value for c in ChangeKind],
    )
    p_log.add_argument("--description", required=True)
    p_log.add_argument("--extra", action="append", help="key=value, repeatable")
    p_log.add_argument("--notes", default="")

    p_show = sub.add_parser("show", help="Print the ledger as a table")
    p_show.add_argument("--ledger", type=Path, required=True)

    p_baseline = sub.add_parser("baseline", help="Show the best Kept entry")
    p_baseline.add_argument("--ledger", type=Path, required=True)
    p_baseline.add_argument("--metric", required=True)

    p_decide = sub.add_parser(
        "decide",
        help="Apply keep/discard rule against the current baseline",
    )
    p_decide.add_argument("--ledger", type=Path, required=True)
    p_decide.add_argument("--metric", required=True)
    p_decide.add_argument("--candidate-cv", type=float, default=None)
    p_decide.add_argument("--candidate-test", type=float, required=True)
    p_decide.add_argument("--simpler", action="store_true")
    p_decide.add_argument("--lower-is-better", action="store_true")
    p_decide.add_argument("--tie-tolerance", type=float, default=DEFAULT_TIE_TOLERANCE)

    args = parser.parse_args()

    if args.cmd == "log":
        try:
            entry = log_experiment(
                ledger_path=args.ledger,
                algo=args.algo,
                primary_metric=args.metric,
                cv_mean=args.cv_mean,
                cv_std=args.cv_std,
                test_score=args.test_score,
                decision=args.decision,
                change_kind=args.change_kind,
                description=args.description,
                extra_metrics=_parse_extra_metrics(args.extra),
                notes=args.notes,
            )
        except ValueError as e:
            print(f"ERROR: {e}", file=sys.stderr)
            return 2
        print(f"Logged at {entry.timestamp}: {entry.decision} | {entry.description}")
        return 0

    if args.cmd == "show":
        entries = read_experiments(args.ledger)
        print(summarize_ledger(entries))
        return 0

    if args.cmd == "baseline":
        baseline = get_baseline(args.ledger, args.metric)
        if baseline is None:
            print(f"No Kept entries for metric {args.metric!r} yet.")
            return 0
        print(json.dumps(asdict(baseline), indent=2))
        return 0

    if args.cmd == "decide":
        baseline = get_baseline(args.ledger, args.metric)
        baseline_score = baseline.test_score if baseline else None
        decision, rationale = decide_keep_discard(
            baseline_score=baseline_score,
            candidate_score=args.candidate_test,
            candidate_is_simpler=args.simpler,
            higher_is_better=not args.lower_is_better,
            tie_tolerance=args.tie_tolerance,
        )
        print(f"Decision: {decision.value}")
        print(f"Rationale: {rationale}")
        if baseline is not None:
            print(f"Baseline test score: {baseline.test_score}")
            print(f"Candidate test score: {args.candidate_test}")
        return 0 if decision == Decision.KEEP else 1

    return 2


if __name__ == "__main__":
    sys.exit(main())
