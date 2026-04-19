# T-SQL Optimization & Schema Exploration Reference

> Deep-dive reference. Loaded on demand for query optimization and schema discovery tasks.

## Schema Exploration - Discovery Queries

### List All User Tables

```sql
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.create_date,
    t.modify_date,
    p.rows AS row_count
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions AS p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;
```

### List All Views

```sql
SELECT
    s.name AS schema_name,
    v.name AS view_name,
    v.create_date,
    v.modify_date,
    m.definition AS view_definition
FROM sys.views AS v
INNER JOIN sys.schemas AS s ON v.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m ON v.object_id = m.object_id
WHERE v.is_ms_shipped = 0
ORDER BY s.name, v.name;
```

### Get Table Columns with Types

```sql
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    dc.definition AS default_value
FROM sys.columns AS c
INNER JOIN sys.tables AS t ON c.object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.default_constraints AS dc ON c.default_object_id = dc.object_id
WHERE t.name = @TableName AND s.name = @SchemaName
ORDER BY c.column_id;
```

### Get Primary Keys and Foreign Keys

```sql
-- Primary Keys
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    kc.name AS constraint_name,
    c.name AS column_name,
    ic.key_ordinal
FROM sys.key_constraints AS kc
INNER JOIN sys.tables AS t ON kc.parent_object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.index_columns AS ic ON kc.unique_index_id = ic.index_id AND kc.parent_object_id = ic.object_id
INNER JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE kc.type = 'PK'
ORDER BY s.name, t.name, ic.key_ordinal;

-- Foreign Keys
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    fk.name AS fk_name,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS fk_column,
    OBJECT_SCHEMA_NAME(fkc.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fkc.referenced_object_id) AS referenced_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS t ON fk.parent_object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name, fk.name;
```

### Get Indexes

```sql
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    i.is_primary_key,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS index_columns
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
INNER JOIN sys.tables AS t ON i.object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE i.name IS NOT NULL AND t.is_ms_shipped = 0
GROUP BY s.name, t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY s.name, t.name, i.name;
```

### Get Stored Procedures

```sql
SELECT
    s.name AS schema_name,
    p.name AS procedure_name,
    p.create_date,
    p.modify_date,
    m.definition AS procedure_definition
FROM sys.procedures AS p
INNER JOIN sys.schemas AS s ON p.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m ON p.object_id = m.object_id
WHERE p.is_ms_shipped = 0
ORDER BY s.name, p.name;
```

### Data Vault Schema Detection

```sql
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    CASE
        WHEN t.name LIKE 'Hub[_]%' OR t.name LIKE 'hub[_]%' OR t.name LIKE 'HUB[_]%' OR t.name LIKE 'h[_]%' THEN 'Hub'
        WHEN t.name LIKE 'Link[_]%' OR t.name LIKE 'link[_]%' OR t.name LIKE 'LNK[_]%' OR t.name LIKE 'lnk[_]%' THEN 'Link'
        WHEN t.name LIKE 'Eff[_]Sat[_]%' OR t.name LIKE 'EFF[_]SAT[_]%' OR t.name LIKE 'ESAT[_]%' OR t.name LIKE 'eff[_]sat[_]%' THEN 'Effectivity Satellite'
        WHEN t.name LIKE 'Sat[_]%' OR t.name LIKE 'sat[_]%' OR t.name LIKE 'SAT[_]%' OR t.name LIKE 'LSAT[_]%' THEN 'Satellite'
        WHEN t.name LIKE 'PIT[_]%' OR t.name LIKE 'pit[_]%' OR t.name LIKE 'Pit[_]%' THEN 'Point-in-Time'
        WHEN t.name LIKE 'Bridge[_]%' OR t.name LIKE 'BRG[_]%' OR t.name LIKE 'brg[_]%' OR t.name LIKE 'br[_]%' THEN 'Bridge'
        WHEN t.name LIKE 'Dim[_]%' OR t.name LIKE 'DIM[_]%' OR t.name LIKE 'dim[_]%' THEN 'Dimension'
        WHEN t.name LIKE 'Fact[_]%' OR t.name LIKE 'FCT[_]%' OR t.name LIKE 'fct[_]%' THEN 'Fact'
        WHEN t.name LIKE 'Ref[_]%' OR t.name LIKE 'REF[_]%' OR t.name LIKE 'ref[_]%' THEN 'Reference'
        ELSE 'Unknown/Non-DV'
    END AS dv_entity_type,
    CASE
        WHEN s.name IN ('raw', 'rdv', 'DV', 'dv') THEN 'Raw Vault'
        WHEN s.name IN ('biz', 'bdv', 'bv') THEN 'Business Vault'
        WHEN s.name IN ('mart', 'im', 'br', 'rpt') THEN 'Information Mart'
        WHEN s.name IN ('staging', 'stg', 'psa') THEN 'Staging'
        WHEN s.name IN ('Admin', 'meta', 'ctrl') THEN 'Metadata'
        ELSE s.name
    END AS dv_layer,
    p.rows AS row_count
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions AS p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
ORDER BY dv_layer, dv_entity_type, s.name, t.name;
```

## T-SQL Optimization

### Query Structure Best Practices

- **CTEs over nested subqueries**: readable, easier to debug, optimizer-friendly
- **EXISTS over IN** for correlated existence checks (short-circuits evaluation)
- **UNION ALL over UNION** when duplicate elimination is unnecessary
- **Window functions over self-joins** for running totals, ranks, and lag/lead
- **Parameterized queries**: always use `@parameters` for literal values (plan cache reuse)
- **SET NOCOUNT ON**: reduce network overhead in stored procedures
- **OPTION (RECOMPILE)**: use sparingly for highly variable parameter distributions

### Index-Friendly Patterns

```sql
-- DO: Use SARGable predicates (index-seekable)
WHERE created_date >= '2025-01-01'
WHERE customer_id = @CustomerId
WHERE last_name LIKE 'Smith%'

-- DON'T: Functions on indexed columns (forces scan)
WHERE YEAR(created_date) = 2025
WHERE UPPER(last_name) = 'SMITH'
WHERE ISNULL(status, 'Unknown') = 'Active'
WHERE amount * 1.1 > 1000
```

### Join Optimization

```sql
-- Prefer explicit JOIN syntax (never implicit comma joins)
SELECT o.order_id, c.customer_name
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_date >= @StartDate
ORDER BY o.order_date DESC;
```

### Pagination Pattern

```sql
SELECT order_id, customer_name, order_date, order_total
FROM vw_orders_summary
ORDER BY order_date DESC
OFFSET @PageSize * (@PageNumber - 1) ROWS
FETCH NEXT @PageSize ROWS ONLY;
```

### Conditional Aggregation

```sql
SELECT
    product_category,
    SUM(CASE WHEN YEAR(order_date) = 2024 THEN order_total ELSE 0 END) AS revenue_2024,
    SUM(CASE WHEN YEAR(order_date) = 2025 THEN order_total ELSE 0 END) AS revenue_2025,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM fact_orders
GROUP BY product_category
ORDER BY revenue_2025 DESC;
```

### Temporal Table Queries (Azure SQL)

```sql
SELECT * FROM employees FOR SYSTEM_TIME AS OF '2025-06-15T10:00:00';
SELECT * FROM employees FOR SYSTEM_TIME BETWEEN '2025-01-01' AND '2025-12-31';
SELECT * FROM employees FOR SYSTEM_TIME ALL WHERE employee_id = @EmployeeId ORDER BY SysStartTime;
```

### Recursive CTE for Hierarchical Data

```sql
WITH OrgChart AS (
    SELECT employee_id, employee_name, manager_id, 0 AS level
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.employee_name, e.manager_id, oc.level + 1
    FROM employees AS e
    INNER JOIN OrgChart AS oc ON e.manager_id = oc.employee_id
)
SELECT * FROM OrgChart
ORDER BY level, employee_name
OPTION (MAXRECURSION 100);
```

### Execution Plan Analysis

When optimizing a slow query:

1. Run `SET STATISTICS IO ON; SET STATISTICS TIME ON;`
2. Check `INCLUDE ACTUAL EXECUTION PLAN` (Ctrl+M in SSMS)
3. Look for: Table Scan, Key Lookup, Hash Match, Sort, Parallelism, Thick arrows
4. Check missing index suggestions in execution plan XML

### Missing Index DMV

```sql
SELECT TOP 20
    ROUND(s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans), 0) AS impact_score,
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
ORDER BY impact_score DESC;
```

## SSMS Workflow Tips

### Query Shortcuts

- **Ctrl+M**: Include Actual Execution Plan
- **Ctrl+L**: Display Estimated Execution Plan
- **Ctrl+K, Ctrl+C**: Comment selection
- **Ctrl+K, Ctrl+U**: Uncomment selection
- **Alt+F1**: `sp_help` on selected object

### Useful System Procedures

```sql
EXEC sp_help 'dbo.TableName';
EXEC sp_helptext 'dbo.ViewOrProcName';
EXEC sp_helpindex 'dbo.TableName';
EXEC sp_depends 'dbo.ObjectName';
EXEC sp_databases;
EXEC sp_tables;
EXEC sp_columns 'TableName';
```


