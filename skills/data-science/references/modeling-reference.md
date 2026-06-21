# Modeling Reference

> Deep-dive companion to `data-science` skill. Load when building classification or regression models.

## Algorithm Selection Tree

```text
Target type?
|
|-- Continuous numeric (regression)
|   |-- Linear relationship suspected -> LinearRegression / Ridge / Lasso baseline
|   |-- Non-linear, tabular -> XGBoost / LightGBM (default for tabular)
|   |-- Many features, sparse -> Lasso (L1 selects features)
|   |-- Time series -> See time-series-reference.md
|
|-- Binary classification
|   |-- Interpretable required -> LogisticRegression with L2
|   |-- Default tabular -> XGBoost / LightGBM
|   |-- Imbalanced (<5% minority) -> XGBoost with scale_pos_weight, PR-AUC metric
|   |-- Tiny dataset (<500 rows) -> LogisticRegression or RandomForest
|
|-- Multi-class
|   |-- Few classes (3-10), tabular -> XGBoost (objective='multi:softprob')
|   |-- Many classes (>50) -> Hierarchical or one-vs-rest framing
|   |-- Ordinal classes -> Ordinal regression (mord library) or binned regression
|
|-- Survival / time-to-event -> CoxPH (lifelines) or XGBoost survival objective
```

## Baseline Discipline

Always train a dumb baseline first. If your fancy model is not significantly better than the baseline, you have a problem.

```python
from sklearn.dummy import DummyClassifier, DummyRegressor

# Classification baseline: predict majority class
baseline = DummyClassifier(strategy="stratified", random_state=42)
baseline.fit(X_train, y_train)
print(f"Baseline AUC: {roc_auc_score(y_test, baseline.predict_proba(X_test)[:, 1]):.3f}")

# Regression baseline: predict the mean
baseline = DummyRegressor(strategy="mean")
```

## Pipeline Pattern (Standard Template)

```python
import pandas as pd
import numpy as np
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from xgboost import XGBClassifier

RANDOM_STATE = 42

# 1. Identify columns
num_cols = X.select_dtypes(include=np.number).columns.tolist()
cat_cols = X.select_dtypes(include="object").columns.tolist()

# 2. Build preprocessor
preprocessor = ColumnTransformer(
    transformers=[
        ("num", Pipeline([
            ("imp", SimpleImputer(strategy="median")),
            ("sc", StandardScaler()),
        ]), num_cols),
        ("cat", Pipeline([
            ("imp", SimpleImputer(strategy="most_frequent")),
            ("oh", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
        ]), cat_cols),
    ],
    remainder="drop",
)

# 3. Wrap in full pipeline
pipe = Pipeline([
    ("prep", preprocessor),
    ("clf", XGBClassifier(
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        random_state=RANDOM_STATE,
        eval_metric="auc",
    )),
])

# 4. Split BEFORE fitting anything
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=RANDOM_STATE
)

# 5. Cross-validate on TRAIN only
cv_scores = cross_val_score(pipe, X_train, y_train, cv=5, scoring="roc_auc", n_jobs=-1)
print(f"CV AUC: {cv_scores.mean():.3f} +/- {cv_scores.std():.3f}")

# 6. Fit and evaluate on TEST exactly once
pipe.fit(X_train, y_train)
test_auc = roc_auc_score(y_test, pipe.predict_proba(X_test)[:, 1])
print(f"Test AUC: {test_auc:.3f}")
```

## Hyperparameter Tuning

### Use Bayesian search for XGBoost / LightGBM

```python
from sklearn.model_selection import RandomizedSearchCV
from scipy.stats import randint, uniform

param_dist = {
    "clf__n_estimators": randint(100, 500),
    "clf__max_depth": randint(3, 10),
    "clf__learning_rate": uniform(0.01, 0.3),
    "clf__subsample": uniform(0.6, 0.4),
    "clf__colsample_bytree": uniform(0.6, 0.4),
    "clf__min_child_weight": randint(1, 10),
}

search = RandomizedSearchCV(
    pipe,
    param_distributions=param_dist,
    n_iter=50,
    cv=5,
    scoring="roc_auc",
    n_jobs=-1,
    random_state=RANDOM_STATE,
    refit=True,
)
search.fit(X_train, y_train)
print(f"Best params: {search.best_params_}")
print(f"Best CV AUC: {search.best_score_:.3f}")
```

For Optuna (better for >100 trials):

```python
import optuna

def objective(trial):
    params = {
        "n_estimators": trial.suggest_int("n_estimators", 100, 500),
        "max_depth": trial.suggest_int("max_depth", 3, 10),
        "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.3, log=True),
    }
    model = Pipeline([("prep", preprocessor), ("clf", XGBClassifier(**params, random_state=42))])
    return cross_val_score(model, X_train, y_train, cv=5, scoring="roc_auc").mean()

study = optuna.create_study(direction="maximize")
study.optimize(objective, n_trials=50)
```

## Metric Selection

| Task | Imbalance | Primary Metric | Why |
|------|-----------|---------------|-----|
| Binary classification | Balanced | ROC-AUC | Threshold-independent |
| Binary classification | < 10% positive | PR-AUC | ROC-AUC is misleading on rare classes |
| Multi-class | Balanced | Accuracy or macro-F1 | Macro-F1 weights classes equally |
| Multi-class | Imbalanced | Macro-F1 or weighted F1 | Penalizes ignoring minority classes |
| Regression | - | RMSE (penalizes large errors) or MAE (robust to outliers) | Pick based on cost function |
| Regression with outliers | - | MAE or Huber loss | RMSE is dominated by outliers |
| Probability calibration matters | - | Log loss / Brier score | Penalizes overconfidence |

## Imbalanced Classes

Tactics in order of preference:

1. **Class weighting**: `XGBClassifier(scale_pos_weight=neg_count/pos_count)` or `class_weight='balanced'` in scikit-learn
2. **Threshold tuning**: train as normal, then move decision threshold based on PR curve
3. **SMOTE / oversampling**: only if (1) and (2) are insufficient; risk of overfitting on synthetic samples
4. **Anomaly detection framing**: if minority is < 1%, classification may not be the right framing

```python
from sklearn.metrics import precision_recall_curve

probs = model.predict_proba(X_val)[:, 1]
prec, rec, thresh = precision_recall_curve(y_val, probs)
# Pick threshold that meets your business constraint (e.g., precision >= 0.8)
target_precision = 0.8
valid = prec[:-1] >= target_precision
best_thresh = thresh[valid][np.argmax(rec[:-1][valid])] if valid.any() else 0.5
```

## SHAP for Explainability

```python
import shap

# Tree models (XGBoost, LightGBM, RandomForest)
explainer = shap.TreeExplainer(pipe.named_steps["clf"])
X_test_transformed = pipe.named_steps["prep"].transform(X_test)
shap_values = explainer.shap_values(X_test_transformed)

# Global feature importance
shap.summary_plot(shap_values, X_test_transformed, feature_names=feature_names)

# Single-prediction explanation
shap.force_plot(explainer.expected_value, shap_values[0], X_test_transformed[0])
```

For black-box models, use `shap.Explainer` with `KernelExplainer` (slow but model-agnostic).

## Calibration

If your downstream system uses predicted probabilities (not just classifications), check calibration:

```python
from sklearn.calibration import CalibratedClassifierCV, calibration_curve
import matplotlib.pyplot as plt

# Diagnose
prob_true, prob_pred = calibration_curve(y_test, probs, n_bins=10)
plt.plot(prob_pred, prob_true, marker="o")
plt.plot([0, 1], [0, 1], linestyle="--")  # perfect calibration line

# Fix: wrap with Platt scaling or isotonic
calibrated = CalibratedClassifierCV(model, method="isotonic", cv=5)
calibrated.fit(X_train, y_train)
```

XGBoost and LightGBM are usually well-calibrated out of the box. Random Forest and SVM rarely are.

## Cross-Validation Strategies

| Data type | CV strategy |
|-----------|-------------|
| Standard tabular | `StratifiedKFold(n_splits=5)` for classification, `KFold` for regression |
| Time series | `TimeSeriesSplit` (forward chaining) |
| Grouped data (users with multiple rows) | `GroupKFold` (no group leakage across folds) |
| Tiny dataset (< 200 rows) | `LeaveOneOut` or repeated stratified k-fold |
| Imbalanced + grouped | `StratifiedGroupKFold` |

## Reproducibility Checklist

- [ ] `random_state` set on every randomized operation (split, model, CV)
- [ ] Numpy seed set: `np.random.seed(42)`
- [ ] Environment locked: `uv.lock`, `requirements.txt`, or `conda env export`
- [ ] Data version recorded: hash of input file or dataset version ID
- [ ] Model artifact saved with metric scores: `joblib.dump(model, f"model_v{version}_auc{score:.3f}.pkl")`
- [ ] Notebook outputs cleared or stripped before commit (`nbstripout`)

## Model Failure Taxonomy

When a model underperforms (low CV score, large CV/test gap, fails to beat baseline), classify the failure BEFORE changing anything. Fix the class of failure, not the specific symptom. The category determines what kind of change to try next.

| # | Category | Symptoms | Diagnostic | Right kind of fix |
|---|----------|----------|-----------|-------------------|
| 1 | **Wrong target** | Model technically works but does not answer the business question; SHAP shows nonsensical drivers | Re-read the spec; ask "what decision does this model drive?" Check whether the target is even computable from the available signal | Redefine target. Hand off to architect if target is structurally wrong. |
| 2 | **Target leakage** | CV score suspiciously high (>0.95 AUC); top features are post-hoc fields; model fails on fresh data | Audit each top feature: would this value exist at the moment of prediction? Check `corr(feature, target) > 0.95` | Remove leaking feature; re-train. Often the only fix needed. |
| 3 | **Weak features** | All models cluster near the dummy baseline; no algorithm helps | Compare top-feature SHAP values; check `mutual_info_classif` against target | Add domain-derived features; engineer interactions; pull richer source data via data-engineer |
| 4 | **Wrong algorithm family** | Strong feature signal in EDA but model underperforms; non-linear relationships in linear model, or noise overfit by deep model | Plot residuals vs features; check learning curve (high bias = underfit, high variance = overfit) | Switch family (linear -> gradient boosting, or vice versa); change model capacity |
| 5 | **Data quality / volume** | High CV variance across folds; results swing with seed; test score wildly different from CV | Check fold sizes, class balance per fold, presence of duplicates, label noise rate | Get more data; clean labels; use more robust CV (RepeatedStratifiedKFold); collapse rare classes |
| 6 | **Silent failure** | Score looks fine but downstream consumer reports broken predictions; calibration off; threshold wrong | Recompute metrics on production-like distribution; check predicted-probability histogram; manual review of 20 predictions | Recalibrate (Platt / isotonic); tune threshold on PR curve; surface assumptions to stakeholder |

### Diagnostic gate

Before any fix, write one sentence: **"This is a category-N failure because [evidence]."** If you cannot say which category, you do not have enough diagnostic signal yet. Run the relevant diagnostic before changing the model.

### Generalization check

Before keeping any fix, ask: **"If this exact training dataset disappeared, would this change still be a worthwhile improvement?"** If no, the fix is overfit to a quirk and should be discarded.

## Anti-Patterns

| Anti-pattern | Why it breaks |
|--------------|--------------|
| Fitting StandardScaler on full X before split | Test set statistics leak into training |
| `train_test_split(shuffle=True)` on time series | Future leaks into past |
| Tuning hyperparameters on test set | Test set becomes a second train set |
| Comparing models with different CV splits | Variance from CV randomness gets confused with model differences |
| Reporting CV mean without std | Hides high variance / unstable model |
| Ignoring class imbalance with accuracy | "95% accuracy" on a 95% majority class is the dummy baseline |
| One-hot encoding before splitting | Creates encoded columns based on full data; test-only categories silently absorbed |
| Changing features AND algorithm in the same iteration | Cannot attribute score change; learning signal lost |
| Editing the test set or metric mid-project | All prior scores become incomparable; iteration history is destroyed |
