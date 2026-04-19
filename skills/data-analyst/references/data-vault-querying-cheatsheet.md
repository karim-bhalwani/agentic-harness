# Data Vault 2.0 Querying Cheatsheet

> Quick reference for querying Data Vault 2.0 models in Azure SQL Server / SQL Server.
> Our warehouse uses `PROCESS_DATE` for time determination and has **no `LOAD_END_DATE`** column.
> Default current-state pattern: `ROW_NUMBER() OVER (PARTITION BY HK ORDER BY PROCESS_DATE DESC) = 1`.
> Effectivity Satellites follow an **insert-only** pattern (no end-date updates).

---

## Team Standards: Time Columns

| Column         | Purpose                                                                        | Nullable        | Notes                                                                                                                          |
| -------------- | ------------------------------------------------------------------------------ | --------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `PROCESS_DATE` | The **reporting date** the record is for. Primary temporal filter for queries. | No              | Use this for point-in-time and current-state queries.                                                                          |
| `LOAD_DATE`    | Date/time the record was physically inserted into the warehouse.               | No (never null) | Can be updated if a fix is applied, so `MAX(LOAD_DATE)` may put records out of order. **Do not use for time-based filtering.** |

### Column Name Mapping

Our warehouse uses these column names (left) instead of common textbook names (right):

| Our Name          | Common Variant                  | Found In        |
| ----------------- | ------------------------------- | --------------- |
| `Hash_Difference` | `HASHDIFF`, `hash_diff`, `HD_*` | Satellites      |
| `Process_Date`    | `LOAD_DATE`, `load_dts`, `LDTS` | All DV entities |
| `Record_Source`   | `rec_src`, `RSRC`               | All DV entities |
| `System_Source`   | _(no standard equivalent)_      | All DV entities |

## Entity Quick Reference

| DV Entity       | Purpose                               | Naming Variants (detect all)                   | Key Column                            |
| --------------- | ------------------------------------- | ---------------------------------------------- | ------------------------------------- |
| Hub             | Business keys (unique entities)       | `Hub_*`, `HUB_*`, `hub_*`, `h_*`               | `HK_<entity>` or `hub_<entity>_hk`    |
| Link            | Relationships between hubs            | `Link_*`, `LNK_*`, `lnk_*`, `link_*`           | `HK_<link>` or `link_<name>_hk`       |
| Satellite       | Descriptive attributes (versioned)    | `Sat_*`, `SAT_*`, `sat_*`, `LSAT_*`            | `HK_parent + Process_Date`            |
| Effectivity Sat | Relationship validity periods         | `Eff_Sat_*`, `EFF_SAT_*`, `ESAT_*`, `EffSat_*` | `<Link_Name>_Hash_Key + Process_Date` |
| PIT             | Point-in-Time snapshot (pre-computed) | `PIT_*`, `pit_*`, `Pit_*`                      | `HK_entity + PIT_DATE`                |
| Bridge          | Multi-link traversal (pre-computed)   | `Bridge_*`, `BRG_*`, `brg_*`, `br_*`           | Composite hub HKs                     |
| Reference       | Lookup / code tables                  | `Ref_*`, `REF_*`, `ref_*`                      | Varies                                |
| Dimension       | IM: business-friendly entity          | `Dim_*`, `DIM_*`, `dim_*`                      | `DIM_<entity>_KEY`                    |
| Fact            | IM: measures at grain                 | `Fact_*`, `FCT_*`, `fct_*`                     | FK to dimensions                      |

## Standard Column Patterns

### Hub Columns

| Column                        | Type                       | Description                           |
| ----------------------------- | -------------------------- | ------------------------------------- |
| `HK_<entity>`                 | `BINARY(32)` or `CHAR(64)` | SHA-256 hash of business key          |
| `<entity>_BK` / `<entity>_ID` | Varies                     | Natural business key                  |
| `Process_Date`                | `DATETIME2(7)`             | Reporting date the record is for      |
| `Load_Date`                   | `DATETIME2(7)`             | When first loaded to DWH (never null) |
| `Record_Source`               | `NVARCHAR(100-200)`        | Source system identifier              |
| `System_Source`               | `NVARCHAR(100-200)`        | Originating system identifier         |

### Satellite Columns

| Column            | Type                       | Description                                                       |
| ----------------- | -------------------------- | ----------------------------------------------------------------- |
| `HK_<parent>`     | `BINARY(32)` or `CHAR(64)` | FK to parent Hub or Link                                          |
| `Process_Date`    | `DATETIME2(7)`             | Reporting date the record is for (part of PK)                     |
| `Load_Date`       | `DATETIME2(7)`             | Warehouse insert timestamp (never null, can be updated for fixes) |
| `Hash_Difference` | `BINARY(32)` or `CHAR(64)` | Hash of all descriptive columns                                   |
| `Record_Source`   | `NVARCHAR(100-200)`        | Source system identifier                                          |
| `System_Source`   | `NVARCHAR(100-200)`        | Originating system identifier                                     |
| `<attributes>`    | Varies                     | Business descriptive columns                                      |

> **No `LOAD_END_DATE`**: Our satellites do not have an end-date column. Use `ROW_NUMBER()` partitioned by hash key and ordered by `Process_Date DESC` to get the current record.

### Effectivity Satellite Columns (Insert-Only Pattern)

Our Effectivity Satellites use an **insert-only** pattern. Records are never updated; new rows are inserted to reflect changes in relationship status.

| Column                           | Type                | Description                                                         |
| -------------------------------- | ------------------- | ------------------------------------------------------------------- |
| `<Link_Name>_Hash_Key`           | `BINARY(32)`        | FK to parent **Link** (never Hub)                                   |
| `Process_Date`                   | `DATETIME2(7)`      | Reporting date (part of PK)                                         |
| `Load_Date`                      | `DATETIME2(7)`      | Warehouse insert timestamp (never null)                             |
| `Record_Source`                  | `NVARCHAR(100-200)` | Source system identifier                                            |
| `System_Source`                  | `NVARCHAR(100-200)` | Originating system identifier                                       |
| `<Link_Name>_Relationship_Begin` | `DATETIME2(7)`      | Business-time start of relationship                                 |
| `<Link_Name>_Relationship_End`   | `DATETIME2(7)`      | Initial value `9999-12-31 23:59:59.000` = relationship still active |

> **No `LOAD_END_DATE`**, **no `IS_DELETED`** flag, **no `Hash_Difference`** in EffSats.
>
> **Column naming**: Relationship columns follow the pattern `<Link_Name>_Relationship_Begin` / `<Link_Name>_Relationship_End`
> (e.g., `Coverage_Plan_Relationship_Begin`, `Coverage_Plan_Relationship_End`).
>
> **Insert-only rules:**
>
> - End dates are **never null**; an initial value of `9999-12-31 23:59:59.000` means "still active."
> - When a relationship ceases to be effective, a **new row** is inserted with `Relationship_End` set to 1 second before the start of the new relationship.
> - To query as-of a date: get `MAX(Load_Date)` per hash key where `Process_Date <= @AsOfDate`, then check `@AsOfDate BETWEEN Relationship_Begin AND Relationship_End`.

## Ghost Record Filtering

Ghost records are placeholders with sentinel values. **Always exclude them from results:**

```sql
-- Filter by Process_Date
WHERE s.Process_Date > '1900-01-01'
-- Or filter by Record_Source
WHERE s.Record_Source NOT IN ('GHOST', 'SYSTEM_GHOST')
-- Or filter by hash key (all zeros)
WHERE s.HK_CUSTOMER <> 0x0000000000000000000000000000000000000000000000000000000000000000
```

## Query Pattern Selection

**Step 1**: Check if Information Mart tables answer the question. If yes, use those.
**Step 2**: Check if PIT/Bridge tables exist for the entities involved. If yes, use those.
**Step 3**: Fall back to Raw Vault Hub + Satellite joins.

### Current state: `ROW_NUMBER() OVER (PARTITION BY HK ORDER BY Process_Date DESC) = 1`

> Our warehouse has no `LOAD_END_DATE`. The `ROW_NUMBER` pattern is the **primary** method for current-state queries.

## Query Patterns

### 1. Current State (ROW_NUMBER - Primary)

```sql
WITH Latest AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY HK_ENTITY ORDER BY Process_Date DESC) AS rn
    FROM [schema].[Sat_Entity_Detail]
    WHERE Process_Date > '1900-01-01'
)
SELECT h.<BK_COLUMN>, l.*
FROM [schema].[Hub_Entity] AS h
INNER JOIN Latest AS l ON h.HK_ENTITY = l.HK_ENTITY AND l.rn = 1;
```

### 2. Multi-Satellite on Same Hub (Current State)

```sql
WITH Latest_Detail AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY HK_ENTITY ORDER BY Process_Date DESC) AS rn
    FROM [schema].[Sat_Entity_Detail]
    WHERE Process_Date > '1900-01-01'
),
Latest_Address AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY HK_ENTITY ORDER BY Process_Date DESC) AS rn
    FROM [schema].[Sat_Entity_Address]
    WHERE Process_Date > '1900-01-01'
)
SELECT h.<BK_COLUMN>, s1.<attr>, s2.<attr>
FROM [schema].[Hub_Entity] AS h
LEFT JOIN Latest_Detail AS s1
    ON h.HK_ENTITY = s1.HK_ENTITY AND s1.rn = 1
LEFT JOIN Latest_Address AS s2
    ON h.HK_ENTITY = s2.HK_ENTITY AND s2.rn = 1;
```

### 3. As-Of-Date (Historical Snapshot)

```sql
WITH AsOf AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY HK_ENTITY ORDER BY Process_Date DESC) AS rn
    FROM [schema].[Sat_Entity_Detail]
    WHERE Process_Date <= @AsOfDate AND Process_Date > '1900-01-01'
)
SELECT h.<BK_COLUMN>, a.*
FROM [schema].[Hub_Entity] AS h
INNER JOIN AsOf AS a ON h.HK_ENTITY = a.HK_ENTITY AND a.rn = 1;
```

### 4. Change History (All Versions)

```sql
SELECT h.<BK_COLUMN>, s.*
FROM [schema].[Hub_Entity] AS h
INNER JOIN [schema].[Sat_Entity_Detail] AS s ON h.HK_ENTITY = s.HK_ENTITY
WHERE s.Process_Date > '1900-01-01'
ORDER BY h.<BK_COLUMN>, s.Process_Date;
```

### 5. Relationship Traversal (Hub-Link-Hub)

```sql
SELECT h1.<BK1>, h2.<BK2>
FROM [schema].[Link_Entity1_Entity2] AS l
INNER JOIN [schema].[Hub_Entity1] AS h1 ON l.HK_ENTITY1 = h1.HK_ENTITY1
INNER JOIN [schema].[Hub_Entity2] AS h2 ON l.HK_ENTITY2 = h2.HK_ENTITY2;
```

### 6. Hub + Link + Hub + Satellites (Full Pattern)

```sql
WITH Latest_S1 AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY HK_ENTITY1 ORDER BY Process_Date DESC) AS rn
    FROM [schema].[Sat_Entity1_Detail]
    WHERE Process_Date > '1900-01-01'
),
Latest_S2 AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY HK_ENTITY2 ORDER BY Process_Date DESC) AS rn
    FROM [schema].[Sat_Entity2_Detail]
    WHERE Process_Date > '1900-01-01'
)
SELECT
    h1.<BK1>, s1.<attr>,
    h2.<BK2>, s2.<attr>
FROM [schema].[Link_Entity1_Entity2] AS l
INNER JOIN [schema].[Hub_Entity1] AS h1 ON l.HK_ENTITY1 = h1.HK_ENTITY1
INNER JOIN [schema].[Hub_Entity2] AS h2 ON l.HK_ENTITY2 = h2.HK_ENTITY2
LEFT JOIN Latest_S1 AS s1
    ON h1.HK_ENTITY1 = s1.HK_ENTITY1 AND s1.rn = 1
LEFT JOIN Latest_S2 AS s2
    ON h2.HK_ENTITY2 = s2.HK_ENTITY2 AND s2.rn = 1;
```

### 7. Using PIT (Efficient Multi-Satellite)

```sql
SELECT h.<BK>, s1.<attr>, s2.<attr>
FROM [biz].[PIT_Entity] AS p
INNER JOIN [schema].[Hub_Entity] AS h ON p.HK_ENTITY = h.HK_ENTITY
LEFT JOIN [schema].[Sat_Entity_Detail] AS s1
    ON p.HK_ENTITY = s1.HK_ENTITY AND p.LDTS_DETAIL = s1.Process_Date
LEFT JOIN [schema].[Sat_Entity_Address] AS s2
    ON p.HK_ENTITY = s2.HK_ENTITY AND p.LDTS_ADDRESS = s2.Process_Date
WHERE p.PIT_DATE = @SnapshotDate
  AND s1.Process_Date > '1900-01-01';
```

### 8. Effectivity Satellite - Active Relationships (Insert-Only)

With the insert-only pattern, `Relationship_End = '9999-12-31 23:59:59.000'` means the relationship is still active. The query pattern uses a self-join with `MAX(Load_Date)` to get the latest physical record, then filters by business-time validity.

```sql
-- Currently active relationships as of today
SELECT
    [target].<Link_Name>_Hash_Key,
    [target].Load_Date,
    [target].Record_Source,
    [target].System_Source,
    MAX([target].<Link_Name>_Relationship_Begin) AS <Link_Name>_Relationship_Begin,
    [target].<Link_Name>_Relationship_End,
    [target].Process_Date
FROM [schema].[EffSat_<Link_Name>] AS [target]
INNER JOIN (
    -- Get the latest physical record per hash key
    SELECT
        [t2].<Link_Name>_Hash_Key,
        MAX([t2].Load_Date) AS Load_Date
    FROM [schema].[EffSat_<Link_Name>] AS [t2]
    WHERE [t2].Process_Date <= @AsOfDate
    GROUP BY [t2].<Link_Name>_Hash_Key
) AS [max_target]
    ON  [target].<Link_Name>_Hash_Key = [max_target].<Link_Name>_Hash_Key
    AND [target].Load_Date = [max_target].Load_Date
WHERE
    @AsOfDate BETWEEN [target].<Link_Name>_Relationship_Begin
                  AND [target].<Link_Name>_Relationship_End
    AND [target].Process_Date <= @AsOfDate
GROUP BY
    [target].<Link_Name>_Hash_Key,
    [target].Load_Date,
    [target].Record_Source,
    [target].System_Source,
    [target].<Link_Name>_Relationship_End,
    [target].Process_Date
ORDER BY
    [target].<Link_Name>_Hash_Key;
```

> **Why this pattern?**
>
> 1. The inner subquery finds the latest physical row (`MAX(Load_Date)`) per hash key that existed as of `@AsOfDate` (filtered by `Process_Date`).
> 2. The outer join retrieves the full row at that `Load_Date`.
> 3. The `BETWEEN` clause checks business-time validity: was the relationship active at `@AsOfDate`?
> 4. `MAX(Relationship_Begin)` with `GROUP BY` resolves ties when multiple rows share the same `Load_Date`.
> 5. For **currently active** relationships, set `@AsOfDate = GETDATE()` and rows with `Relationship_End = '9999-12-31 23:59:59.000'` will pass the `BETWEEN` filter.
> 6. For **expired** relationships, the `BETWEEN` filter naturally excludes them since `@AsOfDate` falls outside their validity window.

### 9. Effectivity Satellite - Browse All Records for a Hash Key

To inspect all EffSat rows for a specific relationship (useful for debugging):

```sql
SELECT
    <Link_Name>_Hash_Key,
    Load_Date,
    Record_Source,
    Process_Date,
    <Link_Name>_Relationship_Begin,
    <Link_Name>_Relationship_End,
    System_Source
FROM [schema].[EffSat_<Link_Name>]
WHERE <Link_Name>_Hash_Key = @HashKey
ORDER BY Process_Date DESC;
```

### 10. Bridge Table Query

```sql
WITH Latest_Sat AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY HK_LINK ORDER BY Process_Date DESC) AS rn
    FROM [schema].[Sat_Detail]
    WHERE Process_Date > '1900-01-01'
)
SELECT h1.<BK1>, h2.<BK2>, s.<measure>
FROM [biz].[Bridge_Name] AS br
INNER JOIN [schema].[Hub_Entity1] AS h1 ON br.HK_ENTITY1 = h1.HK_ENTITY1
INNER JOIN [schema].[Hub_Entity2] AS h2 ON br.HK_ENTITY2 = h2.HK_ENTITY2
LEFT JOIN Latest_Sat AS s
    ON br.HK_LINK = s.HK_LINK AND s.rn = 1;
```

### 11. Information Mart (Star Schema)

```sql
-- Prefer mart tables when they exist - pre-joined and optimized
SELECT d.*, f.<measure>
FROM [mart].[FCT_Sales] AS f
INNER JOIN [mart].[DIM_Customer] AS d ON f.FK_CUSTOMER = d.DIM_CUSTOMER_KEY
WHERE d.IS_CURRENT = 1;
```

## Anti-Pattern Checklist

| Anti-Pattern                               | Correct Approach                                                                                                               |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| Joining EffSat to Hub                      | EffSat always joins to its parent **Link**                                                                                     |
| `LOAD_END_DATE IS NULL` for current row    | We have no `LOAD_END_DATE`. Use `ROW_NUMBER() OVER (PARTITION BY HK ORDER BY Process_Date DESC) = 1`                           |
| `MAX(LOAD_DATE)` for current satellite row | `LOAD_DATE` can be updated by fixes, putting rows out of order. Use `Process_Date` with `ROW_NUMBER` for satellites.           |
| Using `LOAD_DATE` for time filtering       | Use `Process_Date` (reporting date). `LOAD_DATE` is the warehouse insert timestamp and can shift.                              |
| `EFF_TO_DATE IS NULL` for active EffSat    | Our EffSats use insert-only: use self-join with `MAX(Load_Date)` subquery + `BETWEEN Relationship_Begin AND Relationship_End`. |
| Ignoring ghost records                     | Filter `WHERE Process_Date > '1900-01-01'`                                                                                     |
| Joining on business keys inside vault      | Join on hash keys (`HK_*`) within DV                                                                                           |
| Using `SELECT *`                           | List explicit columns                                                                                                          |
| Skipping PIT when it exists                | Check for PIT tables first, use equi-joins                                                                                     |
| Querying raw vault when mart exists        | Prefer Information Mart views/tables                                                                                           |
| `UNION` instead of `UNION ALL`             | Use `UNION ALL` unless dedup needed                                                                                            |
| Functions on indexed columns in WHERE      | Rearrange for SARGable predicates                                                                                              |


