---
name: data-science
description: "Comprehensive data science reference covering exploratory data analysis, statistical hypothesis testing, predictive modeling with scikit-learn/XGBoost, time series forecasting, and A/B experiment design. Use when profiling datasets, running hypothesis tests, building classification/regression models, forecasting time series, designing experiments, or interpreting model results. DO NOT USE FOR: ad-hoc SQL querying (use data-analyst), ETL/ELT pipeline construction (use data-engineering), LLM/RAG application design (use llm-app-patterns), MLOps and deployment automation (use ops), or pure code review (use guardian)."
argument-hint: "[analysis, model, or experiment task]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: []
---

# Data Science Skill

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Unified reference for exploratory data analysis, statistical inference, predictive modeling, time series forecasting, and experimentation. Covers the full DS workflow: from raw dataset to validated model and reproducible artifact.

## Behavioral Directives

- **Problem before model**: never train a model before the business question, success metric, and data quality are confirmed. A 99% accurate model on the wrong question is worthless.
- **EDA before modeling**: always profile distributions, missingness, and outliers before feature engineering. Skipping EDA leaks bugs into every downstream step.
- **Validation over fit**: report cross-validated metrics, never just train-set scores. Use CV mean score as the iteration signal; hold out a test set untouched until the final evaluation (evaluated exactly once, after the keep/discard loop is complete).
- **One clear approach**: recommend a single algorithm path with rationale. Present an alternative to the user only when both conditions are true: (a) the primary evaluation metric (e.g., AUC-ROC for classification, RMSE for regression - use whatever metric was agreed for the task) differs by less than 5 percentage points in absolute terms (this governs whether to surface an alternative model to the user; it is separate from the 0.002 tie tolerance used for iteration keep/discard decisions in the Fixed Evaluation Harness), and (b) one model is natively interpretable (linear/logistic/decision tree) while the other is not (ensemble/neural net).
- **One change per iteration**: when iterating to improve a model, change exactly ONE category at a time (features OR algorithm OR hyperparameters OR preprocessing). Multi-variable changes destroy the learning signal: you cannot tell which change moved the score.
- **Simplicity tie-breaker**: when two model candidates produce equal scores within tolerance, the simpler one wins. See the Simplicity tie-breaker rules in the Fixed Evaluation Harness section for exact thresholds and examples.
- **Notebook for exploration, script for production**: use Jupyter cells for EDA and model experimentation; convert to clean `.py` modules for reproducible artifacts.

## Workflow Routing Guide

**Start here**: use the quick-reference table for the common case. Only read the numbered steps below if your situation doesn't match any table row exactly.

> **How to use the table**: match your task and target type to find the workflow. Size and interpretability only matter for predictive modeling rows.

| Task            | Target      | Size | Interpretability  | → Workflow          |
| --------------- | ----------- | ---- | ----------------- | ------------------- |
| Explore data    | -           | any  | any               | EDA                 |
| Test hypothesis | -           | any  | any               | Statistical Testing |
| Predict numeric | continuous  | any  | any               | Regression          |
| Predict class   | binary      | any  | regulated         | Logistic + SHAP     |
| Predict class   | binary      | any  | internal/research | XGBoost             |
| Predict class   | multi-class | any  | any               | Multinomial         |
| Forecast        | time series | any  | any               | Time Series         |
| A/B test        | -           | any  | any               | Experiment Design   |

**Edge-case fallback only** - if no table row matches, answer each step independently before moving to the next:

### Step 1: Task Type

What are you doing?

- **Understand the data** (no model yet) → Use **EDA Workflow** below + [eda-reference.md](./references/eda-reference.md)
- **Test a hypothesis** (is A different from B?) → Use **Statistical Testing** below + [statistical-testing-reference.md](./references/statistical-testing-reference.md)
- **Predict a value or class** → Use **Predictive Modeling** below + [modeling-reference.md](./references/modeling-reference.md)
- **Forecast a future time series** → Use **Time Series** below + [time-series-reference.md](./references/time-series-reference.md)
- **Design or analyze an A/B test** → Use **Experiment Design** below + [experiment-design-reference.md](./references/experiment-design-reference.md)

### Step 2: Target Type (predictive modeling only)

What does the model predict?

- **Continuous numeric** → Regression (LinearRegression baseline → XGBoost / LightGBM for nonlinear)
- **Binary categorical** → Binary classification (LogisticRegression baseline → XGBoost; check class balance)
- **Multi-class categorical** → Multinomial classification (one-vs-rest LogisticRegression → XGBoost with `objective='multi:softprob'`)
- **Ordinal categorical** → Ordinal regression or binned regression (avoid naive multi-class; ordering matters)

### Step 3: Dataset Size

How many rows?

- **< 10K rows** → Pandas + scikit-learn; use stratified k-fold CV
- **10K - 1M rows** → Pandas + scikit-learn / XGBoost; consider feature subsampling
- **> 1M rows** → Sample for development, then scale via PySpark MLlib or Dask, OR delegate ETL to `data-engineer`

### Step 4: Interpretability Requirement

Who will use the output and in what domain?

- **Regulated domain** (credit, healthcare, hiring) → Linear/logistic models or tree models with SHAP explanations
- **Internal tool** → Any model; provide SHAP summary for top features
- **Research / exploratory** → Any model; document assumptions and limitations

## EDA Workflow

The non-negotiable profiling sequence before any modeling:

1. **Shape and types**: `df.shape`, `df.dtypes`, sample 10 rows
2. **Missing data**: per-column null counts and percentages; flag columns > 30% missing
3. **Distributions**: histograms for numerics, value counts for categoricals; flag skew and rare categories
4. **Outliers**: IQR or z-score on numerics; visualize with boxplots
5. **Correlations**: pairwise correlations for numerics; flag |r| > 0.9 for multicollinearity
6. **Target leakage check**: any feature suspiciously correlated with target (|r| > 0.95) is likely leaked
7. **Class balance** (classification only): document target distribution; flag minority class < 10%

> If the dataset has already been split or partially processed, explicitly audit what transformations have been applied, whether split happened before or after those transformations, and whether EDA was performed on the full dataset or only the training fold. Document findings before proceeding.

> Full EDA checklist with code patterns and visualization recipes: [references/eda-reference.md](./references/eda-reference.md)

## Statistical Testing

Test selection by question type:

- **"Is mean of A different from B?"** (2 groups, numeric) → Welch's t-test (do not assume equal variance)
- **"Are groups A, B, C different?"** (3+ groups, numeric) → One-way ANOVA → Tukey HSD post-hoc
- **"Is proportion A different from B?"** (2 groups, binary) → Two-proportion z-test or chi-square
- **"Are categorical variables independent?"** (categorical x categorical) → Chi-square test of independence
- **"Non-normal distributions or small n?"** → Mann-Whitney U (2 groups), Kruskal-Wallis (3+ groups)
- **"Paired observations?"** (before/after) → Paired t-test or Wilcoxon signed-rank

Always report effect size (Cohen's d, odds ratio, eta-squared), not just p-value. Run power analysis before declaring "no significant difference."

> Full test selection tree, power analysis code, and assumption checks: [references/statistical-testing-reference.md](./references/statistical-testing-reference.md)

## Predictive Modeling

Standard workflow:

```python
# 1. Split BEFORE feature engineering (avoid leakage)
from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y  # stratify for classification
)

# 2. Pipeline: impute -> encode -> scale -> model (single object, fit once)
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from xgboost import XGBClassifier

preprocessor = ColumnTransformer([
    ("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), num_cols),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), cat_cols),
])

model = Pipeline([
    ("prep", preprocessor),
    ("clf", XGBClassifier(n_estimators=200, max_depth=6, learning_rate=0.1, random_state=42)),
])

# 3. Cross-validate on train; fit on full train; evaluate ONCE on test
from sklearn.model_selection import cross_val_score
cv_scores = cross_val_score(model, X_train, y_train, cv=5, scoring="roc_auc")
print(f"CV AUC: {cv_scores.mean():.3f} +/- {cv_scores.std():.3f}")

model.fit(X_train, y_train)
test_score = model.score(X_test, y_test)
```

Key rules: split before feature engineering, use Pipeline objects (no leakage from scaling/imputing on full data), cross-validate on train only, evaluate on test exactly once.

> Full guide: algorithm selection, hyperparameter tuning, SHAP explainability, calibration, imbalanced classes: [references/modeling-reference.md](./references/modeling-reference.md)

## Time Series

Forecasting decision tree:

- **Strong seasonality + holidays + business calendar** → Prophet (`pip install prophet`)
- **Stationary, single seasonality, no exogenous** → SARIMA via statsmodels
- **Multiple related series, exogenous variables, large data** → Gradient-boosted regression on lag features (XGBoost / LightGBM)
- **Hierarchical (store-level + region-level)** → Reconcile with hts library or hierarchical Prophet

Always: decompose into trend + seasonality + residual first; check stationarity (ADF test) for ARIMA family; use time-based train/test split (NEVER random shuffle).

> Full reference: ARIMA parameter selection, Prophet tuning, residual diagnostics, forecast evaluation metrics (MAPE, sMAPE, MASE): [references/time-series-reference.md](./references/time-series-reference.md)

## Experiment Design (A/B Testing)

Pre-experiment checklist:

1. **Define primary metric**: one metric, pre-registered. Secondary metrics are descriptive only.
2. **Calculate sample size**: power analysis with realistic minimum detectable effect (MDE). Use the `validate_experiment.py` script.
3. **Define guardrails**: secondary metrics that must not regress (latency, error rate, revenue per user)
4. **Define randomization unit**: user, session, or request? Must be the same as the analysis unit.
5. **Define test duration**: minimum 1 week (capture day-of-week effects); never stop early on positive results (peeking inflates false positives)

Post-experiment validation:

- **SRM check**: chi-square test on observed vs expected traffic split. p < 0.001 means randomization is broken; results are invalid.
- **Novelty effect**: compare week 1 vs week 2 results; large drops indicate novelty effect, not real impact.
- **Heterogeneous effects**: segment by user cohort but treat as exploratory (multiple comparison problem).

> Full reference: power analysis formulas, SRM detection, sequential testing, multi-armed bandits: [references/experiment-design-reference.md](./references/experiment-design-reference.md)

## Fixed Evaluation Harness (Hill-Climbing Protocol)

When iterating to improve a model, treat the project as a hill-climbing loop with a strict separation between fixed and editable surfaces.

### The Boundary

| Surface                                   | Status                            | Examples                                                                                          |
| ----------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------- |
| **FIXED** (do not change while iterating) | Frozen at problem-definition time | Test set rows, primary metric definition, target definition, business question, evaluation script |
| **EDITABLE** (the optimization surface)   | Changes one category at a time    | Feature engineering, algorithm choice, hyperparameters, preprocessing, sampling strategy          |

If the test set or metric changes, all prior scores become incomparable. Treat the harness as immutable for the duration of the iteration loop. If the metric must change (e.g., business pivot), restart the ledger with a new file and a documented reason.

### Keep / Discard Rules

After every iteration:

| Outcome                                                       | Decision                      |
| ------------------------------------------------------------- | ----------------------------- |
| CV mean score improves beyond tie tolerance (default 0.002)   | **Keep**                      |
| CV mean score equal within tolerance AND candidate is simpler | **Keep** (simplification win) |
| CV mean score equal within tolerance, no simplification       | **Discard**                   |
| CV mean score degrades beyond tie tolerance                   | **Discard**                   |

> The held-out test set is evaluated exactly once after the keep/discard loop is complete, consistent with the Validation over fit directive.

"Simpler" means: fewer features, fewer preprocessing steps, smaller hyperparameter footprint, or removing custom code. A 0.001 drop from deleting 50 lines of preprocessing is a clear keep. A 0.001 gain from adding 50 lines is a clear discard.

### One Change Per Iteration

Every iteration changes ONE category from the editable surface:

- features (added, removed, transformed)
- algorithm (e.g., LogisticRegression -> XGBoost)
- hyperparameters
- preprocessing (encoder swap, imputation strategy)
- data (more rows, different sampling)
- evaluation (CV strategy change - rare; usually counts as a harness change)

Multi-variable changes destroy the learning signal. If you change features AND swap the algorithm in the same iteration, you cannot tell which moved the score.

### Generalization Gate

Before keeping any change, ask:

> "If this exact dataset disappeared and was replaced with a refresh, would this change still be a worthwhile improvement?"

If no, the change is overfit to a quirk of the current data and should be discarded even if the score moved up. Common red flags: a feature that mirrors a single anomalous date, a hyperparameter tuned to a specific fold split, a preprocessing step that only helps because of a known data error upstream.

### The Ledger

Every iteration is logged via [scripts/experiment_log.py](./scripts/experiment_log.py) with:

- algorithm, primary metric, CV mean/std, test score
- change category (features | algorithm | hyperparameters | preprocessing | data | evaluation)
- Keep / Discard decision and rationale
- description (what changed, why, what was expected)

The ledger is append-only; never edit past entries. Discarded runs stay logged because they carry signal: which features did NOT help is as valuable as which did.

**One ledger file = one fixed harness.** A ledger represents a single (test set + primary metric + target definition) tuple. If any of those change, **start a new ledger file with a new path** (e.g., `model_log_v2_pr_auc.jsonl`). The script prints a warning to stderr when a logged entry's metric does not match the most recent entry in the file. Mixing metrics or test sets in one ledger destroys the comparability that the keep/discard rules depend on.

### Failure Diagnosis Before Fixing

When a model underperforms, classify the failure before changing anything. The 6 categories are documented in [references/modeling-reference.md](./references/modeling-reference.md) under "Model Failure Taxonomy". Fix the class of failure, not the specific symptom.

## Code Standards

- **Reproducibility**: set `random_state` / `random_seed` in every randomized operation
- **No leakage**: split data before any fit, transform, or imputation
- **Pipelines over loose steps**: scikit-learn `Pipeline` and `ColumnTransformer` for any multi-step preprocessing
- **Type hints on production scripts**: `def train(X: pd.DataFrame, y: pd.Series) -> Pipeline:`
- **Notebook hygiene**: each notebook starts with imports + config; clear all outputs before commit (or use `nbstripout`)
- **Version data and models**: log dataset hash, model artifact path, and metric scores together

## Definition of Done

- [ ] Business question, success metric, and data inventory documented before modeling started
- [ ] EDA artifact saved (notebook or report) covering shape, missingness, distributions, correlations
- [ ] Train/validation/test split applied BEFORE feature engineering (no leakage)
- [ ] Cross-validation scores reported with mean and standard deviation
- [ ] Test set evaluated exactly once, after model selection
- [ ] Feature importance / SHAP summary produced for the chosen model
- [ ] Reproducibility: `random_state` set everywhere; environment captured (`requirements.txt` or `uv.lock`)
- [ ] Limitations and assumptions documented in the final report
- [ ] When iterating to improve a model: every iteration (Keep AND Discard) logged to the experiment ledger via `scripts/experiment_log.py`, with change category and decision rationale

## When to Load This Skill

- Profiling a new dataset (EDA)
- Running hypothesis tests on business data
- Building classification or regression models
- Forecasting time series (sales, demand, KPIs)
- Designing or analyzing A/B experiments
- Reviewing a colleague's statistical methodology, model choices, or experiment design for correctness (not code style - use guardian for code review)

## Constraints

- Does NOT design data ingestion pipelines (use `data-engineering` skill)
- Does NOT write SQL against production databases (use `data-analyst` skill)
- Does NOT serve models behind APIs or LLM agents (use `llm-app-patterns` skill or `ai-engineer` agent)
- Does NOT manage MLOps infrastructure or CI/CD (use `ops` skill)
- Does NOT skip EDA, even on a familiar dataset (data drifts; assumptions break)

## Common Traps

| Trap                                                     | Why It Fails                                                                        | Correct Approach                                                                          |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Fitting scaler/imputer on full data before split         | Test set statistics leak into training; CV scores are optimistic                    | Fit preprocessing inside a `Pipeline`; train/test split first                             |
| Random shuffle on time series                            | Future data leaks into training; forecast appears unrealistically accurate          | Use `TimeSeriesSplit` or chronological split                                              |
| Reporting only training accuracy                         | Hides overfitting; no signal on generalization                                      | Always report cross-validated and held-out test metrics                                   |
| Stopping A/B test early on a positive result ("peeking") | Inflates false positive rate well above 5%                                          | Pre-register sample size; only stop at planned duration or via sequential test correction |
| Using accuracy on imbalanced classes                     | 95% accuracy meaningless when 95% is majority class                                 | Use ROC-AUC, PR-AUC, F1, or class-weighted metrics                                        |
| Treating p-value as effect size                          | Statistically significant != practically significant                                | Always report effect size (Cohen's d, lift %, odds ratio) alongside p-value               |
| Multiple comparisons without correction                  | Family-wise error rate explodes; spurious "discoveries"                             | Apply Bonferroni or Benjamini-Hochberg when testing > 1 hypothesis                        |
| One-hot encoding high-cardinality categoricals           | Curse of dimensionality; sparse, slow models                                        | Use target encoding, frequency encoding, or embeddings                                    |
| Tuning hyperparameters on test set                       | Test set becomes a second train set; final score is optimistic                      | Tune on validation (or via CV); test set is touched once                                  |
| Imputing target leakage features                         | Future-only signals (e.g., `total_spend`) imputed for past records corrupt training | Audit each feature: would this value be available at prediction time?                     |
| Ignoring SRM in A/B tests                                | Broken randomization makes results invalid; you can't fix it post-hoc               | Run SRM check (chi-square) before reporting any A/B result                                |
| Production model with no monitoring plan                 | Silent drift; model decays without anyone noticing                                  | Define data-drift and performance-drift alerts before handoff to deployment               |

## Integration Points

- **architect**: Provides ML system design specs (input/output contracts, latency budgets, retraining cadence)
- **data-engineer**: Builds the upstream pipeline that feeds clean data to the model
- **ai-engineer**: Wraps trained models behind RAG / agent / API surfaces; takes over at deployment boundary
- **data-analyst**: Sources curated SQL datasets for analysis; receives DS findings for business reporting
- **guardian**: Reviews modeling code for leakage, reproducibility, and statistical validity
- **ops**: Owns MLOps infrastructure (CI/CD, model registry, monitoring) once the model artifact is signed off

## References

Load these on demand for deep-dive guidance. Read the relevant reference before writing code for that domain.

### Reference Guides

- [EDA Reference](./references/eda-reference.md) - profiling checklist, distribution analysis, missingness patterns, outlier detection, leakage diagnostics
- [Statistical Testing Reference](./references/statistical-testing-reference.md) - test selection tree, power analysis, assumption checks, effect sizes, multiple comparison correction
- [Modeling Reference](./references/modeling-reference.md) - algorithm selection, hyperparameter tuning, SHAP explainability, calibration, imbalanced classes
- [Time Series Reference](./references/time-series-reference.md) - decomposition, ARIMA vs Prophet, exogenous variables, forecast evaluation, residual diagnostics
- [Experiment Design Reference](./references/experiment-design-reference.md) - power analysis, SRM detection, sequential testing, novelty effects, multi-armed bandits

### Scripts

- [validate_experiment.py](./scripts/validate_experiment.py) - SRM (Sample Ratio Mismatch) detector and minimum-sample-size calculator. Run before launching an A/B test (sample size) and before reading results (SRM).
- [model_eval_report.py](./scripts/model_eval_report.py) - generates a structured model evaluation report (CV scores, test metrics, feature importance, calibration). Produces agent-legible findings.
- [experiment_log.py](./scripts/experiment_log.py) - append-only model iteration ledger (JSON Lines). Records every model candidate with metrics, change category, and Keep/Discard decision. Implements the fixed-harness keep/discard rules so iteration history is auditable.
