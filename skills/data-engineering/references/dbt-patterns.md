# dbt Transformation Patterns Reference

> Deep-dive reference. Loaded on demand for dbt model design, testing, and incremental strategy tasks.

## Model Organization

```text
models/
  staging/       -- 1:1 source mirrors, rename + cast only
  intermediate/  -- business logic joins, dedup, SCD
  marts/         -- final business entities, wide tables
```

## Naming Conventions

- `stg_<source>__<entity>` for staging
- `int_<entity>__<verb>` for intermediate (e.g., `int_orders__pivoted`)
- `fct_<entity>` and `dim_<entity>` for marts

## Incremental Strategy

```sql
{{
  config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns'
  )
}}

SELECT *
FROM {{ ref('stg_orders') }}
{% if is_incremental() %}
  WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
{% endif %}
```

### Choosing Incremental Strategy

| Strategy | Use When | Engine |
|---|---|---|
| `merge` | Upserts with a unique key | Snowflake, BigQuery, Databricks |
| `delete+insert` | Partition-level replacement | Redshift, Postgres |
| `insert_overwrite` | Full partition reload | Spark, Hive |
| `append` | Events/logs, no dedup needed | All |

## Testing

- `unique` + `not_null` on every primary key
- `relationships` for foreign keys
- `accepted_values` for enums
- Custom generic tests for business rules

### Schema Test YAML Example

```yaml
models:
  - name: fct_orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      - name: customer_id
        tests:
          - not_null
          - relationships:
              to: ref('dim_customers')
              field: customer_id
      - name: status
        tests:
          - accepted_values:
              values: ['pending', 'shipped', 'delivered', 'cancelled']
```

### Custom Generic Test Example

```sql
-- tests/generic/test_positive_values.sql
{% test positive_values(model, column_name) %}
SELECT {{ column_name }}
FROM {{ model }}
WHERE {{ column_name }} < 0
{% endtest %}
```

## Documentation

- Every model has a `description` in YAML
- Column descriptions for business-critical fields
- Use `exposures` to link models to dashboards/reports

### Exposure Example

```yaml
exposures:
  - name: weekly_revenue_dashboard
    type: dashboard
    owner:
      name: Analytics Team
      email: analytics@company.com
    depends_on:
      - ref('fct_orders')
      - ref('dim_customers')
```

## Project Scaffolding

Recommended directory layout for a new dbt project:

```text
my_dbt_project/
├── dbt_project.yml
├── profiles.yml           -- connection config (gitignored)
├── models/
│   ├── staging/
│   │   └── _stg_sources.yml
│   ├── intermediate/
│   └── marts/
│       └── _marts_schema.yml
├── tests/
│   └── generic/
├── macros/
├── seeds/                 -- small reference data (CSV)
└── snapshots/             -- SCD Type 2 captures
```
