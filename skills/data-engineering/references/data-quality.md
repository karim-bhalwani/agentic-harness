# Data Quality Reference

> Deep-dive reference. Loaded on demand for quality gate design, Great Expectations, dbt tests, and monitoring tasks.

## Quality Gate Pattern

```text
Source -> Schema Validation -> Null/Range Checks -> Uniqueness -> Business Rules -> Write
```

- Fail fast: schema validation at entry point
- Log violations to a quarantine table, don't silently drop
- Alert on threshold breaches (e.g., >5% null rate)

## Great Expectations Integration

```python
import great_expectations as gx

context = gx.get_context()
suite = context.add_expectation_suite("bronze_orders")
suite.add_expectation(
    gx.expectations.ExpectColumnValuesToNotBeNull(column="order_id")
)
suite.add_expectation(
    gx.expectations.ExpectColumnValuesToBeBetween(
        column="amount", min_value=0, max_value=1_000_000
    )
)
```

### Common Expectations

| Expectation | Use Case |
|---|---|
| `ExpectColumnValuesToNotBeNull` | Required fields |
| `ExpectColumnValuesToBeBetween` | Numeric ranges |
| `ExpectColumnValuesToBeInSet` | Enum/category validation |
| `ExpectColumnValuesToBeUnique` | Primary keys |
| `ExpectColumnValuesToMatchRegex` | Format validation (email, phone) |
| `ExpectTableRowCountToBeBetween` | Volume anomaly detection |

## dbt Quality Tests

- Schema tests in YAML (unique, not_null, relationships, accepted_values)
- Custom generic tests for cross-table validation
- `dbt test --select tag:critical` in CI gates

### Critical Test Tagging

```yaml
models:
  - name: fct_orders
    config:
      tags: ['critical']
    columns:
      - name: order_id
        tests:
          - unique:
              tags: ['critical']
          - not_null:
              tags: ['critical']
```

## Quarantine Pattern

```python
from pyspark.sql import functions as F

valid_df = source_df.filter(F.col("order_id").isNotNull() & (F.col("amount") >= 0))
invalid_df = source_df.subtract(valid_df).withColumn(
    "rejection_reason",
    F.when(F.col("order_id").isNull(), "null_order_id")
     .when(F.col("amount") < 0, "negative_amount")
     .otherwise("unknown")
).withColumn("quarantined_at", F.current_timestamp())

valid_df.write.mode("append").saveAsTable("silver.orders")
invalid_df.write.mode("append").saveAsTable("quarantine.orders_rejected")
```

## Monitoring

- Track row counts, null rates, duplicate rates per load
- Compare against 7-day rolling averages
- Freshness checks: `dbt source freshness`

### Freshness Check Configuration

```yaml
sources:
  - name: raw_crm
    freshness:
      warn_after: {count: 12, period: hour}
      error_after: {count: 24, period: hour}
    loaded_at_field: _ingested_at
    tables:
      - name: customers
      - name: orders
```

### Alert Thresholds

| Metric | Warning | Error |
|---|---|---|
| Null rate (required field) | > 1% | > 5% |
| Duplicate rate (primary key) | > 0% | > 0.1% |
| Row count delta vs. 7-day avg | > 30% | > 50% |
| Source freshness | > 12h | > 24h |
