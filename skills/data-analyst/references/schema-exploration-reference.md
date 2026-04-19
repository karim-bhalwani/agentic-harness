# Schema Exploration Reference

> System catalog queries for Azure SQL Server / SQL Server schema discovery.

## Quick Discovery Sequence

Run these in order when exploring an unfamiliar database:

### Step 1: Database Overview

```sql
-- Database name and compatibility level
SELECT
    name AS database_name,
    compatibility_level,
    collation_name,
    state_desc,
    recovery_model_desc
FROM sys.databases
WHERE name = DB_NAME();
```

### Step 2: Schema and Object Counts

```sql
-- Count of objects by type per schema
SELECT
    s.name AS schema_name,
    SUM(CASE WHEN o.type = 'U' THEN 1 ELSE 0 END) AS tables,
    SUM(CASE WHEN o.type = 'V' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN o.type = 'P' THEN 1 ELSE 0 END) AS procedures,
    SUM(CASE WHEN o.type IN ('FN', 'IF', 'TF') THEN 1 ELSE 0 END) AS functions
FROM sys.objects AS o
INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
GROUP BY s.name
ORDER BY s.name;
```

### Step 3: Table Inventory with Row Counts

```sql
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.rows AS approx_row_count,
    CAST(ROUND((SUM(a.total_pages) * 8.0) / 1024, 2) AS DECIMAL(18,2)) AS size_mb,
    t.create_date,
    t.modify_date
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes AS i ON t.object_id = i.object_id AND i.index_id <= 1
INNER JOIN sys.partitions AS p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, p.rows, t.create_date, t.modify_date
ORDER BY p.rows DESC;
```

### Step 4: Column Details for a Specific Table

```sql
-- Replace @SchemaName and @TableName with actual values
DECLARE @SchemaName NVARCHAR(128) = N'dbo';
DECLARE @TableName NVARCHAR(128) = N'YourTableName';

SELECT
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    CASE
        WHEN ty.name IN ('varchar', 'nvarchar', 'char', 'nchar') THEN
            CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR) END
        WHEN ty.name IN ('decimal', 'numeric') THEN
            CAST(c.precision AS VARCHAR) + ',' + CAST(c.scale AS VARCHAR)
        ELSE NULL
    END AS type_detail,
    c.is_nullable,
    c.is_identity,
    dc.definition AS default_value,
    ep.value AS column_description
FROM sys.columns AS c
INNER JOIN sys.tables AS t ON c.object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.default_constraints AS dc ON c.default_object_id = dc.object_id
LEFT JOIN sys.extended_properties AS ep
    ON ep.major_id = c.object_id AND ep.minor_id = c.column_id AND ep.name = 'MS_Description'
WHERE t.name = @TableName AND s.name = @SchemaName
ORDER BY c.column_id;
```

### Step 5: Relationships (Foreign Keys)

```sql
SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS from_schema,
    OBJECT_NAME(fk.parent_object_id) AS from_table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS from_column,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS to_schema,
    OBJECT_NAME(fk.referenced_object_id) AS to_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS to_column,
    fk.name AS fk_name,
    fk.delete_referential_action_desc AS on_delete,
    fk.update_referential_action_desc AS on_update
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY from_schema, from_table, fk.name;
```

### Step 6: Index Coverage

```sql
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns,
    STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN c.name END, ', ')
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS included_columns
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
INNER JOIN sys.tables AS t ON i.object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0 AND i.name IS NOT NULL
GROUP BY s.name, t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY s.name, t.name, i.name;
```

## Data Vault Detection

Detect DV entities by naming convention (both PascalCase and UPPERCASE) **and** schema context:

```sql
-- Identify Data Vault entities by naming pattern + schema layer
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    CASE
        WHEN t.name LIKE 'Hub[_]%' OR t.name LIKE 'hub[_]%' OR t.name LIKE 'HUB[_]%' OR t.name LIKE 'h[_]%' THEN 'Hub'
        WHEN t.name LIKE 'Link[_]%' OR t.name LIKE 'link[_]%' OR t.name LIKE 'LNK[_]%' OR t.name LIKE 'lnk[_]%' THEN 'Link'
        WHEN t.name LIKE 'Eff[_]Sat[_]%' OR t.name LIKE 'EFF[_]SAT[_]%' OR t.name LIKE 'ESAT[_]%' OR t.name LIKE 'eff[_]sat[_]%' THEN 'Effectivity Satellite'
        WHEN t.name LIKE 'Sat[_]%' OR t.name LIKE 'sat[_]%' OR t.name LIKE 'SAT[_]%' OR t.name LIKE 'LSAT[_]%' THEN 'Satellite'
        WHEN t.name LIKE 'PIT[_]%' OR t.name LIKE 'pit[_]%' OR t.name LIKE 'Pit[_]%' THEN 'Point-in-Time'
        WHEN t.name LIKE 'Bridge[_]%' OR t.name LIKE 'BRG[_]%' OR t.name LIKE 'brg[_]%' THEN 'Bridge'
        WHEN t.name LIKE 'Dim[_]%' OR t.name LIKE 'DIM[_]%' OR t.name LIKE 'dim[_]%' THEN 'Dimension'
        WHEN t.name LIKE 'Fact[_]%' OR t.name LIKE 'FCT[_]%' OR t.name LIKE 'fct[_]%' THEN 'Fact'
        WHEN t.name LIKE 'Ref[_]%' OR t.name LIKE 'REF[_]%' OR t.name LIKE 'ref[_]%' THEN 'Reference'
        ELSE 'Unknown/Non-DV'
    END AS dv_entity_type,
    CASE
        WHEN s.name IN ('raw', 'rdv', 'DV', 'dv') THEN 'Raw Vault'
        WHEN s.name IN ('biz', 'bdv', 'bv') THEN 'Business Vault'
        WHEN s.name IN ('mart', 'im', 'br', 'rpt') THEN 'Information Mart'
        WHEN s.name IN ('staging', 'stg', 'psa', 'Staging') THEN 'Staging'
        WHEN s.name IN ('Admin', 'meta', 'ctrl') THEN 'Metadata/Control'
        ELSE s.name
    END AS dv_layer,
    p.rows AS row_count
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions AS p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
ORDER BY dv_layer, dv_entity_type, s.name, t.name;
```

## DV Metadata Tables

Some DV warehouses have admin/metadata tables that describe the ETL configuration. Check for these:

```sql
-- Detect metadata/admin tables (useful for understanding DV structure)
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE s.name IN ('Admin', 'meta', 'ctrl', 'admin')
   OR t.name LIKE '%Meta%Data%'
   OR t.name LIKE '%Config%'
   OR t.name LIKE '%DV[_]Hub%'
   OR t.name LIKE '%DV[_]Sat%'
   OR t.name LIKE '%DV[_]Link%'
ORDER BY s.name, t.name;
```

## Satellite Column Detection

Verify satellite column naming conventions (`Process_Date`, `Hash_Difference`, `Record_Source`, `System_Source`):

```sql
-- Check satellite column names and confirm no LOAD_END_DATE exists
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    MAX(CASE WHEN c.name LIKE '%Process_Date%' OR c.name LIKE '%process_date%' THEN 1 ELSE 0 END) AS has_process_date,
    MAX(CASE WHEN c.name LIKE '%Hash_Difference%' OR c.name LIKE '%HASHDIFF%' OR c.name LIKE '%hash_diff%' THEN 1 ELSE 0 END) AS has_hashdiff,
    MAX(CASE WHEN c.name LIKE '%System_Source%' THEN 1 ELSE 0 END) AS has_system_source,
    MAX(CASE WHEN c.name LIKE '%LOAD_END%' OR c.name LIKE '%load_end%' THEN 1 ELSE 0 END) AS has_end_dating
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.columns AS c ON t.object_id = c.object_id
WHERE (t.name LIKE 'Sat[_]%' OR t.name LIKE 'sat[_]%' OR t.name LIKE 'SAT[_]%'
    OR t.name LIKE 'Eff[_]Sat[_]%' OR t.name LIKE 'EFF[_]SAT[_]%' OR t.name LIKE 'ESAT[_]%')
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
```

## Hash Key Column Detection

Identify whether hash keys are stored as `BINARY(32)` (raw SHA-256) or `CHAR(64)` (hex string):

```sql
-- Detect hash key storage format
SELECT DISTINCT
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    CASE
        WHEN ty.name = 'binary' AND c.max_length = 32 THEN 'BINARY(32) - raw SHA-256'
        WHEN ty.name = 'char' AND c.max_length = 64 THEN 'CHAR(64) - hex string'
        WHEN ty.name = 'varbinary' AND c.max_length = 32 THEN 'VARBINARY(32) - raw SHA-256'
        ELSE ty.name + '(' + CAST(c.max_length AS VARCHAR) + ')'
    END AS hash_format
FROM sys.columns AS c
INNER JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
WHERE (c.name LIKE 'HK[_]%' OR c.name LIKE 'hk[_]%'
    OR c.name LIKE '%[_]hk' OR c.name LIKE '%[_]HK'
    OR c.name LIKE 'HASHDIFF%' OR c.name LIKE 'hash[_]diff%');
```

## Performance Diagnostics

### Top Expensive Queries (by CPU)

```sql
SELECT TOP 20
    qs.total_worker_time / qs.execution_count AS avg_cpu_time_us,
    qs.execution_count,
    qs.total_worker_time AS total_cpu_time_us,
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time_us,
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
    SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset) / 2) + 1) AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY avg_cpu_time_us DESC;
```

### Missing Indexes

```sql
SELECT TOP 20
    ROUND(s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans), 0) AS impact,
    d.statement AS table_name,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
    s.user_seeks,
    s.user_scans
FROM sys.dm_db_missing_index_group_stats AS s
INNER JOIN sys.dm_db_missing_index_groups AS g ON s.group_handle = g.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS d ON g.index_handle = d.index_handle
WHERE d.database_id = DB_ID()
ORDER BY impact DESC;
```


