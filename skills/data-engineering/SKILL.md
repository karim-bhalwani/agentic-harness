---
name: data-engineering
description: "Comprehensive data engineering reference covering Medallion architecture, Data Vault 2.0, PySpark optimization, dbt transformation patterns, data quality frameworks, and SQL optimization. Use when building ETL/ELT pipelines, designing data schemas, optimizing Spark/SQL performance, implementing data governance, or architecting lakehouse solutions. DO NOT USE FOR: ad-hoc SQL querying (use data-analyst), deprecation analysis (use data-deprecation-analysis), LLM/RAG pipeline design (use llm-app-patterns), or CI/CD configuration (use ops)."
argument-hint: "[pipeline or data task]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: []
---

# Data Engineering Skill

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Unified reference for data pipeline design, implementation, and optimization. Covers the full stack: schema design, Spark tuning, dbt patterns, SQL optimization, and data quality.

## Behavioral Directives

- **One clear approach**: recommend a single implementation path. Present alternatives only when they meet performance benchmarks within 10% of the primary recommendation and have distinct tradeoffs (e.g., latency vs. cost, complexity vs. maintainability). Do NOT list anti-patterns as options.
- **Discovery before implementation**: before writing pipeline code, verify: source schema shape, target write mode, partition strategy, and idempotency guarantees.
- **Fail fast, explain clearly**: error messages from validators and quality checks must double as remediation instructions for the next agent or human.

## Pipeline Routing Guide

Answer these four questions in order to determine the correct pattern:

### 1. What is your data source type?

- **Batch** (historical snapshots, full scans, scheduled loads) → Go to **Step 2**
- **Streaming** (real-time events, CDC, append-only feeds) → Go to **Streaming Patterns** below

### 2. For batch pipelines: What transformation scope?

- **No transformation** (raw ingestion) → Use **Bronze Layer** (append-only, schema-on-read)
- **Deduplication, conformance, SCD** → Use **Silver Layer** (MERGE with schema enforcement)
  - Type 1 SCD (overwrite current) → Use `whenMatchedUpdateAll` in MERGE
  - Type 2 SCD (preserve history) → Use Data Vault Satellites or `_valid_from` / `_valid_to` columns
- **Aggregation, star schema** → Use **Gold Layer** (Materialized View or pre-aggregated table)

### 3. What transformation framework?

- **SQL-dominant, multiple models, clear lineage** → Use **dbt** (staging → intermediate → marts)
- **Complex logic, UDFs, feature engineering** → Use **PySpark DataFrame API**
- **Both SQL and complex logic** → Use **dbt for SQL models + PySpark for heavy transforms**

### 4. Data quality requirements?

- **Schema validation at entry** → Apply StructType enforcement or dbt schema tests in Bronze/Staging
- **Business rule checks** → Implement Great Expectations suite or dbt custom generic tests in Silver/Intermediate
- **Monitoring & alerting** → Add row count / null rate / freshness checks on Gold layer

### Streaming Patterns

- **File ingestion** (cloud storage) → Use Auto Loader or Spark Structured Streaming
- **CDC or change feed** → Use MERGE with sequence column for deterministic ordering
- **Append-only events** → Use Streaming write with checkpointing
- **Windowed aggregation** → Use stateful streaming with watermark

## Medallion Architecture

### Bronze (Raw Ingestion)

- Append-only, schema-on-read
- Preserve source metadata: `_source_file`, `_ingested_at`, `_batch_id`
- Partition by ingestion date: `_ingested_date`
- No transformations, no deduplication

### Silver (Conformed)

- Schema enforcement with `MERGE` (Type 1 or Type 2 SCD)
- Deduplication, null handling, type casting
- Business keys as primary identifiers
- Partition by business date or entity key prefix

### Bronze-to-Silver Pattern (PySpark)

```python
from delta.tables import DeltaTable

target = DeltaTable.forPath(spark, silver_path)
target.alias("t").merge(
    bronze_df.alias("s"),
    "t.business_key = s.business_key"
).whenMatchedUpdateAll(
    condition="s._ingested_at > t._ingested_at"
).whenNotMatchedInsertAll().execute()
```

### Gold (Business)

- Pre-aggregated, query-optimized views
- Star schema or wide denormalized tables
- Partition by common query dimensions (date, region)
- Z-ORDER on high-cardinality filter columns

## Data Vault 2.0

Three core table types: **Hubs** (business keys, append-only), **Links** (relationships between hubs), **Satellites** (descriptive attributes, Type 2 history). Hash keys use SHA-256 of uppercase-trimmed business keys. Load date = source system timestamp, not processing time.

> Full DDL patterns, loading code, and PIT/Bridge tables: [references/data-vault.md](./references/data-vault.md)

## PySpark Optimization

Key rules: target 128-256MB per partition, broadcast tables < 100MB, filter before joins, prefer explicit `StructType` over `inferSchema`, enable AQE (`spark.sql.adaptive.enabled = true`).

> Full tuning guide with code examples, skew handling, and config reference: [references/pyspark-optimization.md](./references/pyspark-optimization.md)

## PySpark Coding Standards

- **DataFrame API over RDD.** Always `import pyspark.sql.functions as F` and use `F.col()` notation.
- Chain transformations logically; break long chains with `\` or parentheses for readability.
- Prefer built-in Spark functions over Python UDFs; UDFs bypass Catalyst optimizer and hurt performance.
- Schema-validate DataFrames at pipeline entry points before any transformations ("fail fast").
- **Never `.collect()` large DataFrames**: `.collect()` pulls all data to the driver, causing OOM. Use `.limit(n).collect()` for sampling, or write to storage.
- **Cache strategically**: `.cache()` or `.persist(StorageLevel.DISK_AND_MEMORY)` for DataFrames reused 3+ times. Always `.unpersist()` when done to free memory.
- **Broadcast small tables in joins**: wrap with `F.broadcast(small_df)` for any join side < ~100 MB to avoid full shuffle.
- Default write format is `delta`. Use `mergeSchema=True` for additive schema evolution; `overwriteSchema=True` only when intentionally replacing the schema.
- Prefer `MERGE INTO` (upsert) over full overwrites for incremental loads.

## dbt Transformation Patterns

Three-layer model organization: `staging/` (1:1 source mirrors), `intermediate/` (business logic), `marts/` (final entities). Naming: `stg_<source>__<entity>`, `int_<entity>__<verb>`, `fct_<entity>` / `dim_<entity>`. Test every primary key with `unique` + `not_null`.

> Full patterns with incremental strategies, YAML examples, and project scaffolding: [references/dbt-patterns.md](./references/dbt-patterns.md)

## Data Quality Frameworks

Gate pattern: `Source -> Schema Validation -> Null/Range Checks -> Uniqueness -> Business Rules -> Write`. Fail fast at entry point, quarantine rejected records (never silently drop), alert on threshold breaches.

> Full guide with Great Expectations, dbt tests, quarantine code, and alert thresholds: [references/data-quality.md](./references/data-quality.md)

## SQL Optimization

Key rules: CTEs over subqueries, EXISTS over IN, window functions over self-joins, composite indexes with most selective column first. Always run `EXPLAIN ANALYZE` on slow queries and `ANALYZE` tables after bulk loads.

> Full reference with index design, query patterns, EXPLAIN reading guide, and anti-patterns: [references/sql-optimization.md](./references/sql-optimization.md)

## Pipeline Orchestration Patterns

Core rules: idempotent tasks (re-runnable without side effects), `execution_date` for time partitioning, sensor timeouts always set, retry with exponential backoff, alert on task failure (not just DAG failure).

> Full patterns with code examples, circuit breakers, and DAG design: [references/pipeline-orchestration.md](./references/pipeline-orchestration.md)

## Definition of Done

- [ ] Pipeline is idempotent (re-runnable without side effects)
- [ ] Data quality checks pass (schema validation, null/range checks, uniqueness)
- [ ] dbt tests pass (`unique`, `not_null`, `relationships` on all keys)
- [ ] Spark jobs have no shuffle spills and partitions are within 128-256MB target
- [ ] Quarantine table exists for rejected records (no silent data drops)

## When to Load This Skill

- Building or reviewing any data pipeline (ETL/ELT)
- Optimizing Spark jobs or SQL queries
- Designing data schemas (Medallion, Data Vault, star schema)
- Implementing data quality checks
- Working with dbt models or Airflow DAGs
- Reviewing pipeline architecture

## Constraints

- Does NOT manage cloud infrastructure (use ops skill for IaC)
- Does NOT build ML model training pipelines (use ai-engineer agent)
- Does NOT handle real-time streaming without explicit architecture approval
- Does NOT skip schema validation even for exploratory pipelines

## Common Traps

| Trap                                         | Why It Fails                                                       | Correct Approach                                                                                     |
| -------------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| Using `inferSchema` in production            | Non-deterministic across files, slow on large datasets             | Define explicit `StructType` schema. Store as JSON or Python constant                                |
| `repartition()` before `coalesce()`          | Triggers a full shuffle only to reduce partitions                  | Use `coalesce(n)` to reduce without shuffle. Only `repartition(n, col)` when changing partition keys |
| Running `OPTIMIZE` + `ZORDER` on every write | Compaction overhead exceeds benefit for small/frequent writes      | Schedule `OPTIMIZE` as a separate maintenance job (daily or after N writes)                          |
| Aggregation in a streaming table             | Streaming tables are append-only; aggregates require recomputation | Use a Materialized View with batch read for Gold-layer aggregations                                  |
| `UNION` of streaming sources                 | Non-deterministic ordering, potential data loss on failure         | Use multiple append flows (fan-in), one per source                                                   |
| `SELECT *` in production queries             | Reads unnecessary columns, breaks on schema changes                | Explicitly name required columns                                                                     |
| Functions on indexed columns in `WHERE`      | Breaks predicate pushdown (e.g., `WHERE UPPER(name) = 'X'`)        | Use computed/generated columns or functional indexes                                                 |
| `cache()` without `unpersist()`              | Memory leak across long-running jobs                               | Cache only when reused 3+ times; always `unpersist()` after last use                                 |
| Implicit type conversions in joins           | Silent mismatches cause wrong results or slow hash joins           | Cast join keys to identical types explicitly before the join                                         |
| Skipping schema validation in Bronze         | Corrupt upstream data propagates silently to Silver/Gold           | Validate schema at entry point; quarantine non-conforming records                                    |
| Hardcoded file paths or connection strings   | Breaks across environments (dev/staging/prod)                      | Use parameterized paths and environment-based configs (env vars, Airflow Variables)                  |
| Non-idempotent pipeline tasks                | Re-runs create duplicates or partial writes                        | Use MERGE or `replaceWhere` overwrite semantics; design for safe re-execution                        |

## Integration Points

- **architect**: Provides data model specs and pipeline architecture decisions
- **guardian**: Reviews pipeline code for quality, security (secret handling), and performance
- **ops**: Handles CI/CD pipeline deployment and Airflow DAG scheduling
- **context-engineer**: Documents data lineage and pipeline decisions in Project Bible
- **data-analyst**: Queries and analyzes data in Azure SQL / SQL Server using optimized T-SQL and Data Vault patterns

## References

Load these on demand for deep-dive guidance. Read the relevant reference before writing code for that domain.

### Reference Guides

- [PySpark Optimization](./references/pyspark-optimization.md) - partitioning, joins, broadcast, skew handling, shuffle reduction, memory tuning
- [dbt Patterns](./references/dbt-patterns.md) - model organization, naming, incremental strategy, testing, documentation
- [Data Vault 2.0](./references/data-vault.md) - hubs, links, satellites, hash key rules, load date conventions
- [SQL Optimization](./references/sql-optimization.md) - index strategy, query patterns, EXPLAIN analysis, anti-patterns
- [Data Quality](./references/data-quality.md) - Great Expectations, quality gate pattern, dbt tests, monitoring
- [Pipeline Orchestration](./references/pipeline-orchestration.md) - Airflow best practices, error handling, retry patterns

### Scripts

- [validate_schema.py](./scripts/validate_schema.py) - DataFrame schema contract validator. Run after every transformation step to catch missing columns, type mismatches, and nullable violations before writing to Delta. Produces agent-legible remediation instructions on failure.
