# Statistical Testing Reference

> Deep-dive companion to `data-science` skill. Load when running hypothesis tests, calculating power, or interpreting p-values.

## Test Selection Decision Tree

```text
What is the question?
|
|-- "Is mean of A different from B?"
|   |-- 2 groups, independent samples
|   |   |-- Normal-ish, equal n -> Welch's t-test (default; never assume equal variance)
|   |   |-- Non-normal or small n (<30) -> Mann-Whitney U test
|   |
|   |-- 2 groups, paired (before/after, matched)
|   |   |-- Normal-ish differences -> Paired t-test
|   |   |-- Non-normal differences -> Wilcoxon signed-rank
|   |
|   |-- 3+ groups, independent
|       |-- Normal, equal variance -> One-way ANOVA + Tukey HSD post-hoc
|       |-- Non-normal -> Kruskal-Wallis + Dunn's post-hoc
|
|-- "Is proportion A different from B?"
|   |-- 2 groups -> Two-proportion z-test or chi-square
|   |-- 3+ groups -> Chi-square test of homogeneity
|
|-- "Are two categorical variables independent?"
|   |-- All expected counts >= 5 -> Chi-square test of independence
|   |-- Any expected count < 5 -> Fisher's exact test
|
|-- "Is there a correlation?"
|   |-- Linear, normal -> Pearson r
|   |-- Monotonic, non-normal -> Spearman rho
|   |-- Categorical x ordinal -> Kendall's tau
```

## Code Patterns

### Welch's t-test (default for two-group means)

```python
from scipy import stats

t, p = stats.ttest_ind(group_a, group_b, equal_var=False)  # Welch's, not Student's
print(f"t = {t:.3f}, p = {p:.4f}")

# Effect size (Cohen's d)
import numpy as np
def cohens_d(a, b):
    nx, ny = len(a), len(b)
    pooled_std = np.sqrt(((nx - 1) * a.var(ddof=1) + (ny - 1) * b.var(ddof=1)) / (nx + ny - 2))
    return (a.mean() - b.mean()) / pooled_std

d = cohens_d(group_a, group_b)
# d ~ 0.2 small, 0.5 medium, 0.8 large
```

### Two-proportion test

```python
from statsmodels.stats.proportion import proportions_ztest

count = [successes_a, successes_b]
nobs = [n_a, n_b]
z, p = proportions_ztest(count, nobs)
```

### Chi-square independence

```python
from scipy.stats import chi2_contingency

contingency = pd.crosstab(df["group"], df["outcome"])
chi2, p, dof, expected = chi2_contingency(contingency)

# Effect size (Cramer's V)
n = contingency.sum().sum()
v = np.sqrt(chi2 / (n * (min(contingency.shape) - 1)))
# V ~ 0.1 small, 0.3 medium, 0.5 large
```

### One-way ANOVA + Tukey HSD

```python
from scipy.stats import f_oneway
from statsmodels.stats.multicomp import pairwise_tukeyhsd

f, p = f_oneway(group_a, group_b, group_c)
if p < 0.05:
    tukey = pairwise_tukeyhsd(df["value"], df["group"], alpha=0.05)
    print(tukey.summary())
```

## Power Analysis (Pre-Test Sample Sizing)

Always do this BEFORE collecting data:

```python
from statsmodels.stats.power import TTestIndPower, NormalIndPower

# Two-sample t-test
analysis = TTestIndPower()
n = analysis.solve_power(effect_size=0.3, alpha=0.05, power=0.80, ratio=1.0)
print(f"Required n per group: {np.ceil(n):.0f}")

# Two-proportion test (use ES = h, the arcsine difference)
from statsmodels.stats.proportion import proportion_effectsize
h = proportion_effectsize(0.10, 0.12)  # baseline 10%, target 12%
analysis = NormalIndPower()
n = analysis.solve_power(effect_size=h, alpha=0.05, power=0.80)
```

Default conventions:

- `alpha = 0.05` (5% false positive rate)
- `power = 0.80` (80% chance of detecting a real effect)
- For high-stakes tests (medical, finance): `alpha = 0.01`, `power = 0.90`

## Assumption Checks

### Normality

```python
from scipy.stats import shapiro, normaltest

# Shapiro-Wilk: best for n < 5000
stat, p = shapiro(data)

# D'Agostino-Pearson: works for larger n
stat, p = normaltest(data)
```

p < 0.05 means reject normality. For n > 1000, central limit theorem makes most tests robust to non-normality, so visual inspection (Q-Q plot) is more useful than the test.

### Equal Variance (Levene's)

```python
from scipy.stats import levene

stat, p = levene(group_a, group_b)
# p < 0.05 -> unequal variance -> use Welch's t-test (which is the default anyway)
```

### Independence

No statistical test for independence; check the experimental design:

- Time series? Observations are not independent. Use time series methods.
- Repeated measures? Use paired or mixed-effects models.
- Clustered data (students in classes)? Use hierarchical models or cluster-robust SE.

## Multiple Comparison Correction

If you test K > 1 hypotheses, correct alpha:

```python
from statsmodels.stats.multitest import multipletests

p_values = [0.01, 0.03, 0.04, 0.06, 0.20]

# Bonferroni: conservative, controls FWER
reject, p_corrected, _, _ = multipletests(p_values, method="bonferroni")

# Benjamini-Hochberg: less conservative, controls FDR (preferred for exploratory analysis)
reject, p_corrected, _, _ = multipletests(p_values, method="fdr_bh")
```

Rule: if you ran 20 tests at alpha = 0.05, you would expect ~1 false positive even under the null. Always correct.

## Effect Size Interpretation

| Test | Effect size | Small | Medium | Large |
|------|-------------|-------|--------|-------|
| t-test | Cohen's d | 0.2 | 0.5 | 0.8 |
| ANOVA | eta-squared | 0.01 | 0.06 | 0.14 |
| Chi-square | Cramer's V | 0.1 | 0.3 | 0.5 |
| Correlation | Pearson r | 0.1 | 0.3 | 0.5 |
| Two-proportion | Cohen's h | 0.2 | 0.5 | 0.8 |

A statistically significant result with a tiny effect size (e.g., d = 0.05) is usually not practically meaningful. Always report both.

## Reporting Template

```markdown
**Test**: Welch's two-sample t-test
**H0**: mean(treatment) = mean(control)
**H1**: mean(treatment) != mean(control)
**n**: 1200 (treatment), 1190 (control)
**Result**: t = 3.42, p = 0.0006
**Effect size**: Cohen's d = 0.18 (small)
**95% CI for difference**: [0.42, 1.58] units
**Conclusion**: The difference is statistically significant but the effect is small. Practical impact requires business-side review.
**Assumptions checked**: Normality (Q-Q plot, n large enough for CLT); equal variance not assumed (Welch's used by default).
```

## Common Mistakes

| Mistake | Why wrong | Fix |
|---------|-----------|-----|
| Reporting "p > 0.05 means no effect" | Absence of evidence != evidence of absence | Report power; if power was low, say "inconclusive" |
| Using Student's t-test instead of Welch's | Assumes equal variance; fragile | Always use `equal_var=False` |
| Multiple tests, no correction | Inflated Type I error | Bonferroni or BH correction |
| Stopping data collection when p < 0.05 ("p-hacking") | Inflates false positive rate | Pre-register sample size; never peek |
| One-tailed test post-hoc | Doubles power but is cheating if direction was not pre-specified | Pre-register direction or use two-tailed |
| Reporting only p-value | Tells nothing about magnitude | Always include effect size and CI |
