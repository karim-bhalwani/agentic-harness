# EDA Reference

> Deep-dive companion to `data-science` skill. Load when profiling a new dataset, before any modeling.

## Why EDA First

Every modeling failure I have ever seen traces back to a step skipped in EDA: an unnoticed leak, a column whose meaning changed mid-history, a class imbalance ignored. EDA is not optional polish; it is the bug bar for the rest of the project.

## Standard EDA Checklist

### 1. Shape and Schema

```python
import pandas as pd

print(f"Shape: {df.shape}")
print(f"Memory: {df.memory_usage(deep=True).sum() / 1e6:.1f} MB")
print(df.dtypes)
df.head(10)
df.sample(5, random_state=42)  # random rows reveal what head/tail hide
```

Flags:

- Object-typed columns that should be numeric (parsing failed upstream)
- Datetime columns stored as strings
- Memory > available RAM: switch to chunked reads or PySpark

### 2. Missing Data

```python
missing = df.isnull().sum().sort_values(ascending=False)
missing_pct = (missing / len(df) * 100).round(2)
missing_report = pd.DataFrame({"count": missing, "pct": missing_pct})
print(missing_report[missing_report["count"] > 0])
```

Decision rules:

- **< 5% missing**: impute (median for numeric, mode for categorical)
- **5-30% missing**: impute + add `<col>_was_missing` indicator feature
- **> 30% missing**: investigate before imputing. Often means the column did not exist in older records.
- **Missing not at random** (MNAR): missingness itself is a signal (e.g., income missing for unemployed). Encode it.

### 3. Distributions

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Numeric
df.describe(percentiles=[0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99])
df.hist(bins=50, figsize=(15, 10))

# Categorical
for col in cat_cols:
    print(f"\n{col}: {df[col].nunique()} unique")
    print(df[col].value_counts(normalize=True).head(20))
```

Flags:

- **Skew > 3 or < -3**: consider log/Box-Cox transform
- **Bimodal distributions**: often two populations mixed; consider segmenting
- **Rare categories** (< 0.5% frequency): collapse into "Other" before encoding
- **Single-value columns** (variance = 0): drop; no information

### 4. Outliers

```python
def iqr_outliers(s: pd.Series, k: float = 1.5) -> pd.Series:
    q1, q3 = s.quantile([0.25, 0.75])
    iqr = q3 - q1
    return (s < q1 - k * iqr) | (s > q3 + k * iqr)

outlier_pct = {c: iqr_outliers(df[c]).mean() * 100 for c in num_cols}
```

Decision rules:

- **< 1% outliers**: investigate top/bottom 5 by hand; often data errors
- **Tree-based models** (XGBoost, RandomForest): tolerate outliers; do NOT remove them
- **Linear/distance-based models** (LinearRegression, KNN, SVM): cap at 1st/99th percentile or use robust scaler

### 5. Correlations

```python
corr = df[num_cols].corr()
sns.heatmap(corr, annot=False, cmap="coolwarm", center=0)

# Find pairs with |r| > 0.9
high_corr = (
    corr.abs()
    .where(lambda m: m < 1.0)
    .stack()
    .sort_values(ascending=False)
    .head(20)
)
```

Flags:

- **|r| > 0.9 between features**: multicollinearity. Drop one or use regularization (Ridge, Lasso).
- **|r| > 0.95 between feature and target**: likely leakage. Investigate before celebrating.

### 6. Target Leakage Audit

For every feature, ask: **would this value be known at the moment of prediction?**

Common leaks:

- `total_revenue` predicting `churn` (revenue includes future months)
- `account_status` predicting `default` (status is set after default)
- IDs encoded numerically that happen to correlate with time-based target
- Aggregations computed over the full dataset (including future)

### 7. Class Balance (Classification)

```python
y.value_counts(normalize=True)
```

Decision rules:

- **Balanced (40-60%)**: any metric, default loss
- **Mild imbalance (10-40% minority)**: use stratified split, ROC-AUC or F1
- **Severe imbalance (< 10% minority)**: use PR-AUC (not ROC-AUC), `class_weight='balanced'` or SMOTE, threshold tuning
- **Extreme imbalance (< 1%)**: anomaly detection framing may fit better than classification

## Categorical Encoding Decision

| Cardinality | Encoder | Notes |
|-------------|---------|-------|
| 2 (binary) | Label or one-hot | Either works |
| 3-15 (low) | One-hot encoding | Default for tree and linear models |
| 15-50 (medium) | Target encoding (cross-validated) | Tree models; watch for leakage |
| > 50 (high) | Target encoding, frequency encoding, or embeddings | One-hot creates curse of dimensionality |

## Datetime Feature Engineering

Decompose every timestamp into:

```python
df["dt"] = pd.to_datetime(df["dt"])
df["dt_year"] = df["dt"].dt.year
df["dt_month"] = df["dt"].dt.month
df["dt_dayofweek"] = df["dt"].dt.dayofweek
df["dt_hour"] = df["dt"].dt.hour
df["dt_is_weekend"] = df["dt_dayofweek"].isin([5, 6]).astype(int)

# Cyclical encoding for periodic features (hour, month, day-of-week)
import numpy as np
df["hour_sin"] = np.sin(2 * np.pi * df["dt_hour"] / 24)
df["hour_cos"] = np.cos(2 * np.pi * df["dt_hour"] / 24)
```

## Reporting Output

End every EDA notebook with a short summary:

```markdown
## EDA Summary

- **Rows / cols**: 1.2M x 47
- **Date range**: 2023-01-01 to 2026-04-30
- **Target**: `churn` (binary), 8.4% positive class (mild imbalance)
- **Critical issues**:
  - `customer_lifetime_value` leaks future revenue -> drop
  - `region` has 312 unique values -> target encode
  - 22% missing in `last_purchase_date` -> add `_was_missing` flag
- **Recommended modeling**: XGBoost with stratified 5-fold CV, PR-AUC primary metric
```

This summary is the contract handed off to modeling. No model gets trained without it.
