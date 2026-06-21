"""
model_eval_report.py
====================
Generates a structured model evaluation report for a trained scikit-learn /
XGBoost / LightGBM model. Produces agent-legible findings: what passed, what
failed, and what to fix next.

Required packages (install via uv / pip):
    pandas, numpy, scikit-learn, joblib   (always required)
    shap                                  (optional; SHAP section degrades
                                           gracefully if missing)
    xgboost / lightgbm                    (optional; only needed if the
                                           loaded model uses them)

Usage (agent context):
    from skills.data_science.scripts.model_eval_report import generate_report

    report = generate_report(
        model=trained_pipeline,
        X_test=X_test,
        y_test=y_test,
        cv_scores=cv_scores,
        task="classification",
    )
    print(report.to_markdown())

Usage (CLI):
    python model_eval_report.py \\
        --model artifacts/model.pkl \\
        --x-test data/X_test.parquet \\
        --y-test data/y_test.parquet \\
        --task classification \\
        --output reports/model_eval.md

Exit codes:
    0 = Report generated, model meets quality bar
    1 = Report generated, model has critical issues (see findings)
    2 = Invalid input or unable to evaluate
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any


class Severity(str, Enum):
    CRITICAL = "CRITICAL"
    WARNING = "WARNING"
    INFO = "INFO"


@dataclass
class Finding:
    severity: Severity
    category: str
    message: str
    remediation: str


@dataclass
class EvalReport:
    task: str
    metrics: dict[str, float] = field(default_factory=dict)
    cv_summary: dict[str, float] = field(default_factory=dict)
    findings: list[Finding] = field(default_factory=list)
    feature_importance: list[tuple[str, float]] = field(default_factory=list)
    has_critical: bool = False

    def to_markdown(self) -> str:
        lines: list[str] = []
        lines.append("# Model Evaluation Report")
        lines.append("")
        lines.append(f"**Task**: {self.task}")
        lines.append("")

        lines.append("## Metrics (Test Set)")
        lines.append("")
        for name, value in self.metrics.items():
            lines.append(f"- **{name}**: {value:.4f}")
        lines.append("")

        if self.cv_summary:
            lines.append("## Cross-Validation Summary")
            lines.append("")
            for name, value in self.cv_summary.items():
                lines.append(f"- **{name}**: {value:.4f}")
            lines.append("")

        if self.feature_importance:
            lines.append("## Top Features")
            lines.append("")
            lines.append("| Feature | Importance |")
            lines.append("| ------- | ---------- |")
            for name, imp in self.feature_importance[:15]:
                lines.append(f"| {name} | {imp:.4f} |")
            lines.append("")

        lines.append("## Findings")
        lines.append("")
        if not self.findings:
            lines.append("No issues detected. Model meets the quality bar.")
        else:
            lines.append("| Severity | Category | Issue | Remediation |")
            lines.append("| -------- | -------- | ----- | ----------- |")
            for f in self.findings:
                lines.append(
                    f"| {f.severity.value} | {f.category} | {f.message} | {f.remediation} |"
                )
        lines.append("")

        verdict = "BLOCKED" if self.has_critical else "PASSED"
        lines.append(f"## Verdict: {verdict}")
        lines.append("")
        if self.has_critical:
            lines.append(
                "Critical findings present. Address before promoting to production."
            )
        else:
            lines.append("Ready for review and handoff to ai-engineer or ops.")

        return "\n".join(lines)


def _check_overfit(
    cv_mean: float, test_score: float, threshold: float = 0.05
) -> Finding | None:
    gap = abs(cv_mean - test_score)
    if gap > threshold:
        return Finding(
            severity=Severity.WARNING,
            category="generalization",
            message=f"CV mean ({cv_mean:.3f}) differs from test ({test_score:.3f}) by {gap:.3f}.",
            remediation=(
                "Investigate distribution shift between train and test, or "
                "leakage that inflates CV score. Re-check fold assignment."
            ),
        )
    return None


def _check_cv_stability(cv_std: float, threshold: float = 0.05) -> Finding | None:
    if cv_std > threshold:
        return Finding(
            severity=Severity.WARNING,
            category="stability",
            message=f"CV std is high ({cv_std:.3f}); model performance varies across folds.",
            remediation=(
                "Increase training data, reduce model complexity, or check for "
                "imbalanced fold composition (use stratified CV)."
            ),
        )
    return None


def _check_baseline(
    score: float, baseline: float, metric_name: str, min_lift: float = 0.05
) -> Finding | None:
    lift = score - baseline
    if lift < min_lift:
        return Finding(
            severity=Severity.CRITICAL,
            category="baseline",
            message=(
                f"{metric_name}={score:.3f} barely beats dummy baseline ({baseline:.3f}); "
                f"lift = {lift:.3f}."
            ),
            remediation=(
                "Model may not be learning useful structure. Re-examine features, "
                "target definition, and EDA. A model that does not beat the baseline "
                "is not worth deploying."
            ),
        )
    return None


def generate_report(
    model: Any,
    X_test: Any,
    y_test: Any,
    cv_scores: list[float] | None = None,
    task: str = "classification",
    baseline_score: float | None = None,
) -> EvalReport:
    """
    Generate a structured evaluation report.

    Args:
        model: trained scikit-learn estimator or Pipeline
        X_test: test features (pd.DataFrame or np.ndarray)
        y_test: test target
        cv_scores: list of cross-validation scores (from cross_val_score)
        task: 'classification' or 'regression'
        baseline_score: dummy baseline score for comparison
    """
    try:
        import numpy as np
    except ImportError:
        raise RuntimeError("numpy is required to generate the report")

    report = EvalReport(task=task)

    if cv_scores is not None and len(cv_scores) > 0:
        cv_arr = np.asarray(cv_scores)
        report.cv_summary = {
            "cv_mean": float(cv_arr.mean()),
            "cv_std": float(cv_arr.std()),
            "cv_min": float(cv_arr.min()),
            "cv_max": float(cv_arr.max()),
            "n_folds": int(len(cv_arr)),
        }

    if task == "classification":
        from sklearn.metrics import (
            accuracy_score,
            f1_score,
            log_loss,
            precision_score,
            recall_score,
            roc_auc_score,
        )

        y_pred = model.predict(X_test)
        report.metrics["accuracy"] = float(accuracy_score(y_test, y_pred))
        report.metrics["precision"] = float(
            precision_score(y_test, y_pred, average="weighted", zero_division=0)
        )
        report.metrics["recall"] = float(
            recall_score(y_test, y_pred, average="weighted", zero_division=0)
        )
        report.metrics["f1_weighted"] = float(
            f1_score(y_test, y_pred, average="weighted", zero_division=0)
        )

        if hasattr(model, "predict_proba"):
            try:
                y_proba = model.predict_proba(X_test)
                if y_proba.shape[1] == 2:
                    report.metrics["roc_auc"] = float(
                        roc_auc_score(y_test, y_proba[:, 1])
                    )
                    report.metrics["log_loss"] = float(log_loss(y_test, y_proba))
            except (ValueError, AttributeError):
                pass

        primary_score = report.metrics.get("roc_auc", report.metrics.get("f1_weighted"))
        if baseline_score is not None and primary_score is not None:
            f = _check_baseline(primary_score, baseline_score, "primary metric")
            if f:
                report.findings.append(f)

    elif task == "regression":
        from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

        y_pred = model.predict(X_test)
        report.metrics["mae"] = float(mean_absolute_error(y_test, y_pred))
        report.metrics["rmse"] = float(np.sqrt(mean_squared_error(y_test, y_pred)))
        report.metrics["r2"] = float(r2_score(y_test, y_pred))

        if baseline_score is not None:
            f = _check_baseline(report.metrics["r2"], baseline_score, "R^2")
            if f:
                report.findings.append(f)
    else:
        raise ValueError(
            f"Unsupported task: {task}. Use 'classification' or 'regression'."
        )

    if report.cv_summary:
        primary_test_metric = (
            report.metrics.get("roc_auc")
            or report.metrics.get("f1_weighted")
            or report.metrics.get("r2")
        )
        if primary_test_metric is not None:
            f = _check_overfit(report.cv_summary["cv_mean"], primary_test_metric)
            if f:
                report.findings.append(f)

        f = _check_cv_stability(report.cv_summary["cv_std"])
        if f:
            report.findings.append(f)

    final_estimator = _get_final_estimator(model)
    feature_names = _get_feature_names(model, X_test)
    if hasattr(final_estimator, "feature_importances_") and feature_names is not None:
        importances = final_estimator.feature_importances_
        pairs = sorted(
            zip(feature_names, importances), key=lambda x: x[1], reverse=True
        )
        report.feature_importance = [(str(n), float(v)) for n, v in pairs]

    report.has_critical = any(f.severity == Severity.CRITICAL for f in report.findings)
    return report


def _get_final_estimator(model: Any) -> Any:
    if hasattr(model, "named_steps"):
        return list(model.named_steps.values())[-1]
    return model


def _get_feature_names(model: Any, X: Any) -> list[str] | None:
    if hasattr(model, "get_feature_names_out"):
        try:
            return list(model.get_feature_names_out())
        except Exception:
            pass
    if hasattr(X, "columns"):
        return list(X.columns)
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Model evaluation report generator")
    parser.add_argument(
        "--model", type=Path, required=True, help="Path to pickled model"
    )
    parser.add_argument(
        "--x-test", type=Path, required=True, help="Path to X_test parquet/csv"
    )
    parser.add_argument(
        "--y-test", type=Path, required=True, help="Path to y_test parquet/csv"
    )
    parser.add_argument(
        "--task", choices=["classification", "regression"], required=True
    )
    parser.add_argument(
        "--baseline", type=float, default=None, help="Baseline metric for comparison"
    )
    parser.add_argument(
        "--output", type=Path, default=None, help="Write report markdown here"
    )
    args = parser.parse_args()

    try:
        import joblib
        import pandas as pd
    except ImportError as e:
        print(f"ERROR: required dependency missing: {e}", file=sys.stderr)
        return 2

    if not args.model.exists():
        print(f"ERROR: model file not found: {args.model}", file=sys.stderr)
        return 2

    model = joblib.load(args.model)
    x_loader = pd.read_parquet if args.x_test.suffix == ".parquet" else pd.read_csv
    y_loader = pd.read_parquet if args.y_test.suffix == ".parquet" else pd.read_csv
    X_test = x_loader(args.x_test)
    y_test = y_loader(args.y_test).squeeze()

    report = generate_report(
        model=model,
        X_test=X_test,
        y_test=y_test,
        task=args.task,
        baseline_score=args.baseline,
    )

    md = report.to_markdown()
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(md, encoding="utf-8")
        print(f"Report written to {args.output}")
    else:
        print(md)

    return 1 if report.has_critical else 0


if __name__ == "__main__":
    sys.exit(main())
