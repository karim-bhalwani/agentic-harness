# Experiment Design Reference

> Deep-dive companion to `data-science` skill. Load when designing or analyzing A/B tests.

## Pre-Experiment Checklist

Before writing a single line of analysis code:

1. [ ] **Primary metric** named, single, pre-registered
2. [ ] **Guardrail metrics** named (must not regress)
3. [ ] **Minimum detectable effect (MDE)** chosen with business stakeholder
4. [ ] **Sample size** calculated via power analysis
5. [ ] **Randomization unit** identified (user, session, request) and matches analysis unit
6. [ ] **Test duration** set (minimum 1 week to capture day-of-week effects)
7. [ ] **Stop rules** documented (no peeking; only sequential testing if pre-planned)
8. [ ] **SRM detection** plan in place

If any item is missing, the test is not ready to launch.

## Power Analysis (Sample Sizing)

### Two-proportion test (e.g., conversion rate)

```python
from statsmodels.stats.power import NormalIndPower
from statsmodels.stats.proportion import proportion_effectsize

baseline = 0.10        # current conversion rate
mde = 0.01             # detect at least +1pp absolute (10% -> 11%)
target = baseline + mde

h = proportion_effectsize(baseline, target)  # arcsine effect size

n_per_arm = NormalIndPower().solve_power(
    effect_size=h, alpha=0.05, power=0.80
)
print(f"Sample size per arm: {n_per_arm:.0f}")
```

### Two-sample t-test (e.g., revenue per user)

```python
from statsmodels.stats.power import TTestIndPower

# Effect size = (mu_treatment - mu_control) / pooled_std
mu_control = 50
mu_treatment = 52
sigma = 30
effect_size = (mu_treatment - mu_control) / sigma

n_per_arm = TTestIndPower().solve_power(
    effect_size=effect_size, alpha=0.05, power=0.80, ratio=1.0
)
```

### Rules of thumb

- **MDE too small** (e.g., 0.1pp on a 10% baseline): sample size becomes huge; rethink whether the difference matters
- **Power = 0.80** is standard; use 0.90 for high-stakes decisions
- **Alpha = 0.05** for standard tests; `alpha = 0.01` for irreversible decisions

## Randomization

### Hash-based assignment (the only reliable way)

```python
import hashlib

def assign_variant(user_id: str, experiment_id: str, n_variants: int = 2) -> int:
    h = hashlib.md5(f"{experiment_id}:{user_id}".encode()).hexdigest()
    bucket = int(h, 16) % 1000
    return bucket * n_variants // 1000
```

Properties:

- Stable: same user always gets same variant within an experiment
- Independent: different experiments do not interact
- Uniform: large samples are evenly split

Anti-patterns:

- Random number generators that reset on session reload (same user gets different variants)
- Cookie-based assignment without server-side hash (clears on logout / device switch)
- Time-based assignment (Sunday users get treatment, Monday gets control - confounded with day-of-week)

## SRM (Sample Ratio Mismatch) Detection

If you assigned 50/50 traffic and your data shows 49/51 or 48/52, your randomization is likely broken. Check before reporting any results.

```python
from scipy.stats import chisquare

observed = [n_control, n_treatment]
expected = [(n_control + n_treatment) / 2] * 2  # 50/50 expected

chi2, p = chisquare(observed, f_exp=expected)
if p < 0.001:
    raise RuntimeError(
        f"SRM detected (p={p:.4e}). Counts: control={n_control}, "
        f"treatment={n_treatment}. Investigate before trusting results."
    )
```

Common SRM causes:

- Bot traffic disproportionately routed to one variant
- Latency difference causing one variant to lose users before assignment is logged
- Bug in assignment code (e.g., off-by-one, default to control)
- Eligibility filter applied AFTER assignment (e.g., "logged-in users only" filtered post-randomization)

The `validate_experiment.py` script in this skill runs this check.

## Analysis: Conversion Rate (Two-Proportion)

```python
from statsmodels.stats.proportion import proportions_ztest, proportion_confint

successes = [conversions_control, conversions_treatment]
trials = [n_control, n_treatment]

# Two-sided test
z, p = proportions_ztest(successes, trials)

# Confidence intervals for each rate
ci_control = proportion_confint(conversions_control, n_control, alpha=0.05, method="wilson")
ci_treatment = proportion_confint(conversions_treatment, n_treatment, alpha=0.05, method="wilson")

# Lift (relative)
rate_control = conversions_control / n_control
rate_treatment = conversions_treatment / n_treatment
lift = (rate_treatment - rate_control) / rate_control * 100

# CI for lift via bootstrap
import numpy as np
def bootstrap_lift(c_succ, c_n, t_succ, t_n, n_iter=10000):
    rng = np.random.default_rng(42)
    lifts = []
    for _ in range(n_iter):
        c = rng.binomial(c_n, c_succ / c_n) / c_n
        t = rng.binomial(t_n, t_succ / t_n) / t_n
        lifts.append((t - c) / c * 100)
    return np.percentile(lifts, [2.5, 97.5])
```

Always report:

- Both absolute and relative effect
- 95% CI on the effect
- p-value (with correction if multiple metrics)

## Analysis: Continuous Metric (Two-Sample t-test)

```python
from scipy import stats

t, p = stats.ttest_ind(treatment_values, control_values, equal_var=False)

# 95% CI on the mean difference
diff = treatment_values.mean() - control_values.mean()
se = np.sqrt(treatment_values.var(ddof=1) / len(treatment_values)
             + control_values.var(ddof=1) / len(control_values))
ci_low = diff - 1.96 * se
ci_high = diff + 1.96 * se
```

For heavy-tailed metrics (revenue, session length), consider:

- Log-transform before t-test
- Bootstrap CI instead of parametric CI
- Use median + Mann-Whitney U if outliers dominate

## CUPED (Variance Reduction)

If you have pre-experiment data on the same users, use CUPED to reduce variance and shrink required sample size by 20-50%:

```python
def cuped_adjust(y_post: np.ndarray, y_pre: np.ndarray) -> np.ndarray:
    theta = np.cov(y_post, y_pre)[0, 1] / np.var(y_pre)
    return y_post - theta * (y_pre - y_pre.mean())

control_adj = cuped_adjust(control_post, control_pre)
treatment_adj = cuped_adjust(treatment_post, treatment_pre)
# Run t-test on adjusted values
```

CUPED works when the pre-experiment metric correlates with the post-experiment metric. It does not bias results.

## Sequential Testing (When You Want to Peek)

Standard t-tests inflate false positives if you peek. Use sequential tests if you must analyze early:

- **mSPRT** (mixture sequential probability ratio test)
- **Always-valid p-values** (Howard et al.)
- **Group sequential designs** with O'Brien-Fleming or Pocock boundaries

If using Optimizely, Statsig, or Eppo: use their built-in sequential analysis. Do NOT roll your own.

## Novelty Effect Detection

Compare effect in week 1 vs week 2:

```python
def novelty_check(df: pd.DataFrame, treatment_col: str, metric_col: str, week_col: str) -> dict:
    week1 = df[df[week_col] == 1]
    week2 = df[df[week_col] == 2]
    return {
        "week1_lift": compute_lift(week1, treatment_col, metric_col),
        "week2_lift": compute_lift(week2, treatment_col, metric_col),
    }
```

If week 1 lift is 10% and week 2 is 2%, you saw a novelty effect, not a sustained gain.

## Heterogeneous Treatment Effects (HTE)

Segment by user cohort but treat as exploratory:

```python
for segment_name, segment_df in df.groupby("segment"):
    n = len(segment_df)
    if n < 1000:  # too small for reliable analysis
        continue
    lift = compute_lift(segment_df)
    print(f"{segment_name}: n={n}, lift={lift:.2%}")
```

Caveats:

- Multiple comparisons inflate false positives - apply BH correction
- Post-hoc segments are NOT confirmatory - use them to generate hypotheses for future tests

## Reporting Template

```markdown
# Experiment: [Name]

**Hypothesis**: [Specific, falsifiable]
**Primary metric**: [Single metric, pre-registered]
**Duration**: 2026-04-01 to 2026-04-21 (3 weeks)
**Sample size**: 50,420 control / 50,180 treatment
**Randomization**: Hash-based (user_id), 50/50

## SRM Check
- Expected: 50.0% / 50.0%
- Observed: 50.12% / 49.88%
- p-value: 0.31 (no SRM)

## Primary Metric: Conversion Rate
- Control: 8.42% (95% CI: 8.18%, 8.66%)
- Treatment: 8.91% (95% CI: 8.66%, 9.16%)
- **Absolute lift: +0.49pp (95% CI: +0.15pp, +0.83pp)**
- **Relative lift: +5.8%**
- p-value: 0.005

## Guardrails
- Latency p95: control 240ms, treatment 245ms (no significant change)
- Error rate: 0.12% vs 0.13% (no significant change)

## Recommendation
Ship treatment. Effect is statistically significant and meets the pre-registered MDE of +0.3pp.

## Limitations
- 3-week test; long-term effect (e.g., user fatigue) unknown
- US-only traffic; international generalization not tested
```

## Anti-Patterns

| Anti-pattern | Why it breaks |
|--------------|--------------|
| Peeking at results before sample size is reached | False positive rate >> 5% |
| Stopping when p < 0.05 | Same as peeking - inflates false positives |
| Adding a second metric mid-experiment | Multiple comparisons not pre-corrected |
| Ignoring SRM | Broken randomization invalidates everything |
| One-day test | Misses day-of-week effects |
| Reporting only winning segment from many | Multiple-comparison cherry-picking |
| HARK-ing (hypothesizing after results known) | Generates false confidence in noise |
| Comparing effect to power-analysis MDE | MDE was used for sizing, not the threshold for "real effect" |
