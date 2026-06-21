# Time Series Reference

> Deep-dive companion to `data-science` skill. Load when forecasting time series.

## Forecasting Method Selection

```text
Data characteristics?
|
|-- Strong seasonality + holidays + business calendar -> Prophet
|-- Stationary, single seasonality -> SARIMA
|-- Multiple related series, exogenous variables, large data -> XGBoost / LightGBM on lag features
|-- Hierarchical (region -> store -> SKU) -> Hierarchical reconciliation (hts library or bottom-up Prophet)
|-- Very long horizon (>1 year out) -> State-space models or simple averages; forecast quality decays
|-- Sub-second / streaming -> Exponential smoothing or Kalman filter
```

## Mandatory First Step: Decomposition

```python
from statsmodels.tsa.seasonal import seasonal_decompose, STL

# Quick view (additive)
result = seasonal_decompose(ts, model="additive", period=7)  # period = seasonality
result.plot()

# Robust to outliers and changing seasonality (preferred)
stl = STL(ts, period=7, robust=True).fit()
stl.plot()
```

What to look for:

- **Trend**: linear, exponential, or piecewise? Determines model class.
- **Seasonality**: weekly, monthly, yearly? Multiple cycles?
- **Residuals**: should look like white noise. Patterns mean the model is missing something.

## Stationarity (Required for ARIMA Family)

```python
from statsmodels.tsa.stattools import adfuller

result = adfuller(ts.dropna())
print(f"ADF stat: {result[0]:.3f}, p-value: {result[1]:.4f}")
# p < 0.05 -> stationary
# p >= 0.05 -> non-stationary, apply differencing
```

If non-stationary:

1. Try `ts.diff()` (first difference)
2. Test again with ADF
3. Use `d=1` (or `d=2`) in ARIMA

## Time-Based Train/Test Split (CRITICAL)

```python
# WRONG: random shuffle leaks future into past
# X_train, X_test = train_test_split(ts, test_size=0.2)  # NEVER for time series

# RIGHT: chronological split
split_date = "2026-01-01"
train = ts[ts.index < split_date]
test = ts[ts.index >= split_date]

# For CV: use TimeSeriesSplit
from sklearn.model_selection import TimeSeriesSplit
tscv = TimeSeriesSplit(n_splits=5, test_size=30)  # 30-day holdout per fold
```

## Prophet (Default for Most Business Forecasts)

```python
from prophet import Prophet

# Prophet expects columns: ds (datetime), y (value)
df_prophet = ts.reset_index().rename(columns={"date": "ds", "value": "y"})

model = Prophet(
    yearly_seasonality=True,
    weekly_seasonality=True,
    daily_seasonality=False,
    changepoint_prior_scale=0.05,  # default; lower = stiffer trend
    seasonality_prior_scale=10.0,
    seasonality_mode="multiplicative",  # use if seasonal swings scale with trend
)

# Add holidays
from prophet.make_holidays import make_holidays_df
holidays = make_holidays_df(year_list=[2024, 2025, 2026], country="US")
model.add_country_holidays(country_name="US")

# Add exogenous regressors
df_prophet["promo"] = promo_flags
model.add_regressor("promo")

model.fit(df_prophet)

# Forecast
future = model.make_future_dataframe(periods=90)  # 90 days ahead
future["promo"] = future_promo_flags  # exogenous values must be supplied
forecast = model.predict(future)

# Plot
model.plot(forecast)
model.plot_components(forecast)  # trend + seasonality + holidays
```

Tuning rules:

- Forecast too smooth / misses sharp changes -> increase `changepoint_prior_scale` (try 0.5)
- Forecast too jagged / overfits -> decrease `changepoint_prior_scale` (try 0.01)
- Seasonal swings grow with trend -> `seasonality_mode='multiplicative'`

## SARIMA (When You Need a Simpler, Interpretable Model)

```python
from statsmodels.tsa.statespace.sarimax import SARIMAX

# (p, d, q) for non-seasonal, (P, D, Q, s) for seasonal
# Use auto_arima from pmdarima for parameter selection
from pmdarima import auto_arima

auto_model = auto_arima(
    train,
    seasonal=True,
    m=7,  # weekly seasonality
    start_p=0, start_q=0,
    max_p=3, max_q=3,
    start_P=0, start_Q=0,
    max_P=2, max_Q=2,
    d=None, D=None,  # let it determine
    trace=True,
    suppress_warnings=True,
    stepwise=True,
)
print(auto_model.summary())

forecast = auto_model.predict(n_periods=30)
```

## XGBoost on Lag Features (Multi-Series, High-Volume)

```python
import pandas as pd
from xgboost import XGBRegressor

def make_lag_features(df: pd.DataFrame, lags: list[int], windows: list[int]) -> pd.DataFrame:
    df = df.copy()
    for lag in lags:
        df[f"lag_{lag}"] = df["y"].shift(lag)
    for w in windows:
        df[f"rolling_mean_{w}"] = df["y"].shift(1).rolling(w).mean()
        df[f"rolling_std_{w}"] = df["y"].shift(1).rolling(w).std()
    df["dayofweek"] = df.index.dayofweek
    df["month"] = df.index.month
    return df.dropna()

featured = make_lag_features(df, lags=[1, 7, 14, 28], windows=[7, 14, 28])

X = featured.drop(columns=["y"])
y = featured["y"]

model = XGBRegressor(n_estimators=500, max_depth=6, learning_rate=0.05, random_state=42)
model.fit(X_train, y_train)
```

For multi-step forecasts, use **direct multi-step** (one model per horizon) or **recursive** (feed predictions back as lags). Direct is more accurate; recursive is simpler.

## Forecast Evaluation Metrics

| Metric | Formula | Use when |
|--------|---------|----------|
| MAE | mean(\|y - y_hat\|) | Default; same units as target |
| RMSE | sqrt(mean((y - y_hat)^2)) | Penalize large errors more |
| MAPE | mean(\|y - y_hat\| / \|y\|) * 100 | Communicating to business; **fails when y has zeros** |
| sMAPE | symmetric variant | When y can be zero or negative |
| MASE | MAE / MAE_naive | Compare across series with different scales |

```python
from sklearn.metrics import mean_absolute_error, mean_squared_error
import numpy as np

mae = mean_absolute_error(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))

# Naive baseline: predict last value (or last seasonal value)
naive_pred = train.iloc[-7:].values * (len(test) // 7 + 1)  # repeat last week
mae_naive = mean_absolute_error(y_test, naive_pred[:len(y_test)])
mase = mae / mae_naive  # < 1 means better than naive
```

**Always compare to a naive baseline.** A model that beats "predict yesterday" is doing real work; one that does not is worthless.

## Residual Diagnostics

After fitting, residuals must look like white noise:

```python
residuals = y_test - y_pred

# 1. Mean ~ 0
print(f"Residual mean: {residuals.mean():.3f}")

# 2. No autocorrelation (Ljung-Box)
from statsmodels.stats.diagnostic import acorr_ljungbox
result = acorr_ljungbox(residuals, lags=[10], return_df=True)
# p > 0.05 -> no autocorrelation (good)

# 3. Constant variance (visual: plot residuals over time)
# 4. Approximately normal (Q-Q plot)
import scipy.stats as stats
stats.probplot(residuals, dist="norm", plot=plt)
```

If residuals have autocorrelation or trends, the model is missing structure.

## Common Pitfalls

| Pitfall | Why it breaks |
|---------|--------------|
| Random train/test split | Future leaks into past; metrics are fake |
| MAPE with zero values | Division by zero; use sMAPE or MASE |
| Forecasting raw values when log-transform would help | Multiplicative effects break additive models |
| Ignoring exogenous variables you have | Holidays, promotions, weather all matter; let the model see them |
| Forecasting > 1 year out | Uncertainty grows; very few signals beat seasonal naive at long horizons |
| Refitting on each new observation in production without monitoring | Model can silently degrade; track forecast accuracy |
| Using the same model for short and long horizons | Direct multi-step often works better; one model per horizon |
| Treating outliers as noise | They may be holidays, promotions, outages; flag and encode them |
