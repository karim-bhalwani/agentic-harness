"""
validate_experiment.py
======================
A/B experiment validation utility.

Two modes:
  1. Sample size calculation (pre-experiment): how many users per arm?
  2. SRM detection (post-experiment): is randomization broken?

Usage (agent context):
    from skills.data_science.scripts.validate_experiment import (
        calculate_sample_size,
        detect_srm,
    )
    n = calculate_sample_size(baseline=0.10, mde=0.01)
    srm = detect_srm(n_control=50420, n_treatment=49180)

Usage (CLI):
    # Sample size for proportion test (e.g., conversion rate)
    python validate_experiment.py size --baseline 0.10 --mde 0.01

    # Sample size for continuous metric (e.g., revenue)
    python validate_experiment.py size --mu-control 50 --mu-treatment 52 --sigma 30

    # SRM detection
    python validate_experiment.py srm --n-control 50420 --n-treatment 49180

Exit codes:
    0 = OK (sample size computed, or no SRM detected)
    1 = SRM detected (randomization may be broken)
    2 = Invalid input
"""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass


SRM_THRESHOLD = 0.001  # p-value below this means likely SRM


@dataclass
class SampleSizeResult:
    n_per_arm: int
    total_n: int
    test_type: str
    effect_size: float
    alpha: float
    power: float


@dataclass
class SrmResult:
    is_srm: bool
    chi2: float
    p_value: float
    observed: tuple[int, int]
    expected_split: tuple[float, float]
    message: str


def _z_score(p: float) -> float:
    """Inverse standard normal CDF (approx, for alpha/power lookup)."""
    # Beasley-Springer-Moro approximation, sufficient for our needs
    a = [
        -3.969683028665376e01,
        2.209460984245205e02,
        -2.759285104469687e02,
        1.383577518672690e02,
        -3.066479806614716e01,
        2.506628277459239e00,
    ]
    b = [
        -5.447609879822406e01,
        1.615858368580409e02,
        -1.556989798598866e02,
        6.680131188771972e01,
        -1.328068155288572e01,
    ]
    c = [
        -7.784894002430293e-03,
        -3.223964580411365e-01,
        -2.400758277161838e00,
        -2.549732539343734e00,
        4.374664141464968e00,
        2.938163982698783e00,
    ]
    d = [
        7.784695709041462e-03,
        3.224671290700398e-01,
        2.445134137142996e00,
        3.754408661907416e00,
    ]
    p_low, p_high = 0.02425, 1 - 0.02425
    if p < p_low:
        q = math.sqrt(-2 * math.log(p))
        return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) / (
            (((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1
        )
    if p <= p_high:
        q = p - 0.5
        r = q * q
        return (
            (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5])
            * q
            / (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1)
        )
    q = math.sqrt(-2 * math.log(1 - p))
    return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) / (
        (((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1
    )


def calculate_sample_size_proportion(
    baseline: float,
    mde_absolute: float,
    alpha: float = 0.05,
    power: float = 0.80,
) -> SampleSizeResult:
    """
    Sample size per arm for a two-proportion z-test.

    Args:
        baseline: current conversion rate (0 to 1)
        mde_absolute: minimum detectable effect, absolute (e.g., 0.01 = +1pp)
        alpha: significance level (default 0.05, two-sided)
        power: 1 - Type II error rate (default 0.80)
    """
    if not 0 < baseline < 1:
        raise ValueError(f"baseline must be in (0, 1), got {baseline}")
    target = baseline + mde_absolute
    if not 0 < target < 1:
        raise ValueError(f"baseline + mde must be in (0, 1), got {target}")

    # Arcsine effect size (Cohen's h)
    h = 2 * (math.asin(math.sqrt(target)) - math.asin(math.sqrt(baseline)))

    z_alpha = _z_score(1 - alpha / 2)
    z_beta = _z_score(power)
    n = ((z_alpha + z_beta) / h) ** 2
    n_per_arm = int(math.ceil(n))

    return SampleSizeResult(
        n_per_arm=n_per_arm,
        total_n=n_per_arm * 2,
        test_type="two-proportion z-test",
        effect_size=h,
        alpha=alpha,
        power=power,
    )


def calculate_sample_size_means(
    mu_control: float,
    mu_treatment: float,
    sigma: float,
    alpha: float = 0.05,
    power: float = 0.80,
) -> SampleSizeResult:
    """
    Sample size per arm for a two-sample t-test.

    Args:
        mu_control: expected mean in control
        mu_treatment: expected mean in treatment (sets the MDE)
        sigma: pooled standard deviation
        alpha: significance level
        power: 1 - Type II error rate
    """
    if sigma <= 0:
        raise ValueError(f"sigma must be positive, got {sigma}")
    effect_size = abs(mu_treatment - mu_control) / sigma
    if effect_size == 0:
        raise ValueError("mu_treatment equals mu_control; effect size is 0")

    z_alpha = _z_score(1 - alpha / 2)
    z_beta = _z_score(power)
    n = 2 * ((z_alpha + z_beta) / effect_size) ** 2
    n_per_arm = int(math.ceil(n))

    return SampleSizeResult(
        n_per_arm=n_per_arm,
        total_n=n_per_arm * 2,
        test_type="two-sample t-test",
        effect_size=effect_size,
        alpha=alpha,
        power=power,
    )


def detect_srm(
    n_control: int,
    n_treatment: int,
    expected_control_share: float = 0.5,
    threshold: float = SRM_THRESHOLD,
) -> SrmResult:
    """
    Sample Ratio Mismatch detection via chi-square goodness of fit.

    Args:
        n_control: observed count in control
        n_treatment: observed count in treatment
        expected_control_share: planned share for control (0 to 1)
        threshold: p-value below which we flag SRM
    """
    if n_control < 0 or n_treatment < 0:
        raise ValueError("counts must be non-negative")
    if not 0 < expected_control_share < 1:
        raise ValueError("expected_control_share must be in (0, 1)")
    total = n_control + n_treatment
    if total == 0:
        raise ValueError("total count is 0")

    expected_control = total * expected_control_share
    expected_treatment = total * (1 - expected_control_share)

    chi2 = (n_control - expected_control) ** 2 / expected_control + (
        n_treatment - expected_treatment
    ) ** 2 / expected_treatment

    # Chi-square with 1 dof: p = exp(-chi2 / 2) (closed form)
    p_value = math.exp(-chi2 / 2)
    is_srm = p_value < threshold

    if is_srm:
        message = (
            f"SRM DETECTED (p={p_value:.4e} < {threshold}). "
            f"Observed control={n_control}, treatment={n_treatment}. "
            f"Expected ~{expected_control:.0f}/{expected_treatment:.0f}. "
            "Investigate randomization, eligibility filters, and bot traffic "
            "BEFORE trusting any results from this experiment."
        )
    else:
        message = (
            f"No SRM detected (p={p_value:.4f}). "
            f"Observed split is consistent with planned "
            f"{expected_control_share:.0%}/{1 - expected_control_share:.0%}."
        )

    return SrmResult(
        is_srm=is_srm,
        chi2=chi2,
        p_value=p_value,
        observed=(n_control, n_treatment),
        expected_split=(expected_control_share, 1 - expected_control_share),
        message=message,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="A/B experiment validator")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_size = sub.add_parser("size", help="Calculate required sample size")
    p_size.add_argument(
        "--baseline", type=float, help="Baseline conversion rate (proportion test)"
    )
    p_size.add_argument("--mde", type=float, help="Minimum detectable effect, absolute")
    p_size.add_argument("--mu-control", type=float, help="Control mean (means test)")
    p_size.add_argument(
        "--mu-treatment", type=float, help="Treatment mean (means test)"
    )
    p_size.add_argument("--sigma", type=float, help="Pooled std dev (means test)")
    p_size.add_argument("--alpha", type=float, default=0.05)
    p_size.add_argument("--power", type=float, default=0.80)

    p_srm = sub.add_parser("srm", help="Detect Sample Ratio Mismatch")
    p_srm.add_argument("--n-control", type=int, required=True)
    p_srm.add_argument("--n-treatment", type=int, required=True)
    p_srm.add_argument("--expected-control-share", type=float, default=0.5)
    p_srm.add_argument("--threshold", type=float, default=SRM_THRESHOLD)

    args = parser.parse_args()

    if args.cmd == "size":
        if args.baseline is not None and args.mde is not None:
            result = calculate_sample_size_proportion(
                baseline=args.baseline,
                mde_absolute=args.mde,
                alpha=args.alpha,
                power=args.power,
            )
        elif (
            args.mu_control is not None
            and args.mu_treatment is not None
            and args.sigma is not None
        ):
            result = calculate_sample_size_means(
                mu_control=args.mu_control,
                mu_treatment=args.mu_treatment,
                sigma=args.sigma,
                alpha=args.alpha,
                power=args.power,
            )
        else:
            print(
                "ERROR: provide either --baseline+--mde or --mu-control+--mu-treatment+--sigma",
                file=sys.stderr,
            )
            return 2

        print(f"Test type: {result.test_type}")
        print(f"Effect size: {result.effect_size:.4f}")
        print(f"Alpha: {result.alpha}, Power: {result.power}")
        print(f"Required n per arm: {result.n_per_arm:,}")
        print(f"Total sample size: {result.total_n:,}")
        return 0

    if args.cmd == "srm":
        srm_result = detect_srm(
            n_control=args.n_control,
            n_treatment=args.n_treatment,
            expected_control_share=args.expected_control_share,
            threshold=args.threshold,
        )
        print(f"chi2 = {srm_result.chi2:.4f}")
        print(f"p-value = {srm_result.p_value:.4e}")
        print(srm_result.message)
        return 1 if srm_result.is_srm else 0

    return 2


if __name__ == "__main__":
    sys.exit(main())
