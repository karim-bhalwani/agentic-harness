# PySpark Optimization Reference

> Deep-dive reference. Loaded on demand for Spark tuning and performance optimization tasks.

## Partitioning

- Target 128MB-256MB per partition for batch
- `spark.sql.shuffle.partitions` = 2-3x cores for shuffle-heavy jobs
- Use `repartition(n, col)` before writes; `coalesce(n)` to reduce partitions without shuffle

## Joins

- **Broadcast**: tables < 100MB, use `F.broadcast(small_df)`
- **Sort-merge**: default for large-large joins, pre-sort on join key
- **Skew handling**: salt skewed keys, split-and-union

### Broadcast Join Example

```python
from pyspark.sql import functions as F

result = large_df.join(
    F.broadcast(small_df),
    on="join_key",
    how="left"
)
```

### Skew Handling Pattern

```python
import pyspark.sql.functions as F

SALT_BUCKETS = 10

# Salt the skewed side
salted_left = skewed_df.withColumn(
    "salt", (F.rand() * SALT_BUCKETS).cast("int")
).withColumn(
    "salted_key", F.concat(F.col("join_key"), F.lit("_"), F.col("salt"))
)

# Explode the small side to match all salt buckets
exploded_right = small_df.crossJoin(
    spark.range(SALT_BUCKETS).withColumnRenamed("id", "salt")
).withColumn(
    "salted_key", F.concat(F.col("join_key"), F.lit("_"), F.col("salt"))
)

result = salted_left.join(exploded_right, on="salted_key", how="inner")
```

## Predicate Pushdown

- Filter early, before joins
- Use partition columns in WHERE clauses
- Avoid UDFs on filter columns (breaks pushdown)

## Write Optimization

- `replaceWhere` for targeted partition overwrites
- `OPTIMIZE` + `ZORDER BY` for read-heavy tables (schedule separately, not on every write)
- Enable `autoCompact` and `optimizeWrite` for streaming

### Targeted Partition Overwrite

```python
(
    df.write
    .format("delta")
    .mode("overwrite")
    .option("replaceWhere", "date = '2026-04-18'")
    .save(target_path)
)
```

## Memory & Serialization

- Prefer `StructType` schemas over `inferSchema`
- Cache only when reused 3+ times; unpersist after
- Use `mapInPandas`/`applyInPandas` over row-level UDFs

### Explicit Schema Definition

```python
from pyspark.sql.types import StructType, StructField, StringType, LongType, TimestampType

ORDER_SCHEMA = StructType([
    StructField("order_id", StringType(), nullable=False),
    StructField("customer_id", StringType(), nullable=False),
    StructField("amount", LongType(), nullable=False),
    StructField("created_at", TimestampType(), nullable=False),
])

df = spark.read.schema(ORDER_SCHEMA).json(source_path)
```

## Shuffle Reduction Checklist

1. Pre-partition data on join/group keys
2. Use broadcast joins for small dimensions
3. Combine narrow transformations before wide ones
4. Set `spark.sql.adaptive.enabled = true` (AQE)
5. Monitor shuffle bytes in Spark UI; target < 1GB per stage

## Spark Configuration Quick Reference

| Config | Recommended Value | When |
|---|---|---|
| `spark.sql.adaptive.enabled` | `true` | Always (AQE auto-tunes shuffles) |
| `spark.sql.shuffle.partitions` | 2-3x cores | Shuffle-heavy jobs |
| `spark.sql.autoBroadcastJoinThreshold` | `104857600` (100MB) | When small tables are missed |
| `spark.databricks.delta.optimizeWrite.enabled` | `true` | Streaming writes |
| `spark.databricks.delta.autoCompact.enabled` | `true` | Streaming writes |
