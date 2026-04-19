# Data Vault 2.0 Reference

> Deep-dive reference. Loaded on demand for Data Vault schema design and loading patterns.

## Hub Tables

- Business key + hash key + load timestamp + record source
- Never updated, append-only
- One hub per business concept (Customer, Order, Product)

### Hub DDL Pattern

```sql
CREATE TABLE hub_customer (
    hash_key         BINARY(32)    NOT NULL,  -- SHA-256 of business_key
    business_key     VARCHAR(255)  NOT NULL,
    load_timestamp   TIMESTAMP     NOT NULL,
    record_source    VARCHAR(255)  NOT NULL,
    CONSTRAINT pk_hub_customer PRIMARY KEY (hash_key)
);
```

## Link Tables

- Hash key + foreign keys to hubs + load timestamp + record source
- Represent relationships between business entities
- Composite hash key derived from all linked hub keys

### Link DDL Pattern

```sql
CREATE TABLE link_order_customer (
    hash_key              BINARY(32)    NOT NULL,  -- SHA-256 of hub keys combined
    hub_order_hash_key    BINARY(32)    NOT NULL,
    hub_customer_hash_key BINARY(32)    NOT NULL,
    load_timestamp        TIMESTAMP     NOT NULL,
    record_source         VARCHAR(255)  NOT NULL,
    CONSTRAINT pk_link_order_customer PRIMARY KEY (hash_key)
);
```

## Satellite Tables

- Hash key + descriptive attributes + load timestamp + hash diff
- Track changes over time (Type 2 history)
- One satellite per rate-of-change group

### Satellite DDL Pattern

```sql
CREATE TABLE sat_customer_details (
    hub_customer_hash_key BINARY(32)    NOT NULL,
    load_timestamp        TIMESTAMP     NOT NULL,
    hash_diff             BINARY(32)    NOT NULL,  -- SHA-256 of all descriptive columns
    first_name            VARCHAR(255),
    last_name             VARCHAR(255),
    email                 VARCHAR(255),
    record_source         VARCHAR(255)  NOT NULL,
    CONSTRAINT pk_sat_customer PRIMARY KEY (hub_customer_hash_key, load_timestamp)
);
```

## Key Rules

- **Hash keys**: SHA-256 of business key(s), uppercase trimmed, UTF-8 encoded
- **Load date**: source system timestamp, not processing time
- **Record source**: full lineage identifier (system.schema.table)
- **Hash diff**: SHA-256 of all descriptive columns in the satellite, used to detect actual changes

## Loading Patterns

### Hub Load (PySpark)

```python
from pyspark.sql import functions as F

new_hubs = (
    source_df
    .withColumn("hash_key", F.sha2(F.upper(F.trim(F.col("business_key"))), 256))
    .withColumn("load_timestamp", F.col("_source_timestamp"))
    .withColumn("record_source", F.lit("crm.public.customers"))
    .select("hash_key", "business_key", "load_timestamp", "record_source")
)

# Insert only new keys (hub is append-only)
existing_keys = spark.read.table("hub_customer").select("hash_key")
inserts = new_hubs.join(existing_keys, on="hash_key", how="left_anti")
inserts.write.mode("append").saveAsTable("hub_customer")
```

### Satellite Load with Change Detection

```python
new_sats = (
    source_df
    .withColumn("hub_hash_key", F.sha2(F.upper(F.trim(F.col("business_key"))), 256))
    .withColumn("hash_diff", F.sha2(F.concat_ws("||", "first_name", "last_name", "email"), 256))
    .withColumn("load_timestamp", F.col("_source_timestamp"))
    .withColumn("record_source", F.lit("crm.public.customers"))
)

# Only insert records where hash_diff has changed
latest_sats = (
    spark.read.table("sat_customer_details")
    .groupBy("hub_customer_hash_key")
    .agg(F.max("load_timestamp").alias("max_load"))
)
latest_with_diff = (
    spark.read.table("sat_customer_details").alias("s")
    .join(latest_sats.alias("l"),
          (F.col("s.hub_customer_hash_key") == F.col("l.hub_customer_hash_key"))
          & (F.col("s.load_timestamp") == F.col("l.max_load")))
    .select("s.hub_customer_hash_key", "s.hash_diff")
)

changed = new_sats.join(
    latest_with_diff,
    on=(new_sats.hub_hash_key == latest_with_diff.hub_customer_hash_key)
       & (new_sats.hash_diff == latest_with_diff.hash_diff),
    how="left_anti"
)
changed.write.mode("append").saveAsTable("sat_customer_details")
```

## PIT (Point-in-Time) Tables

- Snapshot joins for a given business date
- Pre-computed for query performance on satellites
- Rebuild periodically or on each load

## Bridge Tables

- Pre-joined link paths for complex multi-hub traversals
- Materialized for performance, rebuilt on schedule
