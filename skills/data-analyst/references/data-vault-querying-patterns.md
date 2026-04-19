# Data Vault Querying Patterns (Extended)

> Deep-dive reference. Loaded on demand for DV query construction.

## Current State - Primary Pattern (ROW_NUMBER)

**Default approach.** Our satellites have no `LOAD_END_DATE`. Use `ROW_NUMBER` partitioned by hash key, ordered by `Process_Date DESC`:

```sql
-- Current customer details via ROW_NUMBER (primary pattern)
WITH LatestSat AS (
    SELECT
        s.HK_CUSTOMER,
        s.FIRST_NAME, s.LAST_NAME, s.EMAIL,
        s.Process_Date,
        ROW_NUMBER() OVER (
            PARTITION BY s.HK_CUSTOMER
            ORDER BY s.Process_Date DESC
        ) AS rn
    FROM [raw].[SAT_CUSTOMER_DETAILS] AS s
    WHERE s.Process_Date > '1900-01-01'  -- Exclude ghost records
)
SELECT
    h.CUSTOMER_ID,
    ls.FIRST_NAME, ls.LAST_NAME, ls.EMAIL,
    ls.Process_Date AS last_updated
FROM [raw].[HUB_CUSTOMER] AS h
INNER JOIN LatestSat AS ls
    ON h.HK_CUSTOMER = ls.HK_CUSTOMER
    AND ls.rn = 1;
```

## Multi-Satellite Join on Same Hub (Current State)

When a Hub has multiple satellites, use separate CTEs with `ROW_NUMBER` for each:

```sql
WITH Latest_Details AS (
    SELECT d.*, ROW_NUMBER() OVER (PARTITION BY d.HK_CUSTOMER ORDER BY d.Process_Date DESC) AS rn
    FROM [raw].[SAT_CUSTOMER_DETAILS] AS d
    WHERE d.Process_Date > '1900-01-01'
),
Latest_Address AS (
    SELECT a.*, ROW_NUMBER() OVER (PARTITION BY a.HK_CUSTOMER ORDER BY a.Process_Date DESC) AS rn
    FROM [raw].[SAT_CUSTOMER_ADDRESS] AS a
    WHERE a.Process_Date > '1900-01-01'
)
SELECT
    h.CUSTOMER_ID,
    d.FIRST_NAME, d.LAST_NAME,
    a.CITY, a.POSTAL_CODE
FROM [raw].[HUB_CUSTOMER] AS h
LEFT JOIN Latest_Details AS d
    ON d.HK_CUSTOMER = h.HK_CUSTOMER AND d.rn = 1
LEFT JOIN Latest_Address AS a
    ON a.HK_CUSTOMER = h.HK_CUSTOMER AND a.rn = 1;
```

## Hub + Link + Hub (Relationship Query)

```sql
WITH Latest_Customer AS (
    SELECT cs.*, ROW_NUMBER() OVER (PARTITION BY cs.HK_CUSTOMER ORDER BY cs.Process_Date DESC) AS rn
    FROM [raw].[SAT_CUSTOMER_DETAILS] AS cs
    WHERE cs.Process_Date > '1900-01-01'
),
Latest_Order AS (
    SELECT os.*, ROW_NUMBER() OVER (PARTITION BY os.HK_ORDER ORDER BY os.Process_Date DESC) AS rn
    FROM [raw].[SAT_ORDER_DETAILS] AS os
    WHERE os.Process_Date > '1900-01-01'
)
SELECT
    hc.CUSTOMER_ID,
    cs.FIRST_NAME, cs.LAST_NAME,
    ho.ORDER_ID,
    os.ORDER_DATE, os.ORDER_TOTAL, os.ORDER_STATUS
FROM [raw].[LNK_CUSTOMER_ORDER] AS lco
INNER JOIN [raw].[HUB_CUSTOMER] AS hc ON lco.HK_CUSTOMER = hc.HK_CUSTOMER
INNER JOIN [raw].[HUB_ORDER] AS ho ON lco.HK_ORDER = ho.HK_ORDER
LEFT JOIN Latest_Customer AS cs
    ON hc.HK_CUSTOMER = cs.HK_CUSTOMER AND cs.rn = 1
LEFT JOIN Latest_Order AS os
    ON ho.HK_ORDER = os.HK_ORDER AND os.rn = 1;
```

## Point-in-Time (PIT) Table Query

PIT tables pre-materialize the correct `Process_Date` per satellite per snapshot. **Always prefer PIT when available**:

```sql
SELECT
    h.CUSTOMER_ID,
    det.FIRST_NAME, det.LAST_NAME,
    addr.CITY, addr.POSTAL_CODE
FROM [biz].[PIT_CUSTOMER] AS pit
INNER JOIN [raw].[HUB_CUSTOMER] AS h
    ON h.HK_CUSTOMER = pit.HK_CUSTOMER
LEFT JOIN [raw].[SAT_CUSTOMER_DETAILS] AS det
    ON det.HK_CUSTOMER = pit.HK_CUSTOMER_DET
    AND det.Process_Date = pit.LDTS_CUSTOMER_DET
LEFT JOIN [raw].[SAT_CUSTOMER_ADDRESS] AS addr
    ON addr.HK_CUSTOMER = pit.HK_CUSTOMER_ADDR
    AND addr.Process_Date = pit.LDTS_CUSTOMER_ADDR
WHERE pit.PIT_DATE = @AsOfDate
  AND det.Process_Date > '1900-01-01';
```

## Bridge Table Query

```sql
WITH Latest_Financials AS (
    SELECT os.*, ROW_NUMBER() OVER (PARTITION BY os.HK_ORDER_PRODUCT ORDER BY os.Process_Date DESC) AS rn
    FROM [raw].[SAT_ORDER_PRODUCT_FINANCIALS] AS os
    WHERE os.Process_Date > '1900-01-01'
)
SELECT
    hc.CUSTOMER_ID,
    hp.PRODUCT_ID,
    os.QUANTITY, os.UNIT_PRICE,
    os.QUANTITY * os.UNIT_PRICE AS EXTENDED_AMOUNT
FROM [biz].[BRG_ORDER] AS br
INNER JOIN [raw].[HUB_CUSTOMER] AS hc ON br.HK_CUSTOMER = hc.HK_CUSTOMER
INNER JOIN [raw].[HUB_PRODUCT] AS hp ON br.HK_PRODUCT = hp.HK_PRODUCT
LEFT JOIN Latest_Financials AS os
    ON br.HK_ORDER_PRODUCT = os.HK_ORDER_PRODUCT AND os.rn = 1;
```

## Historical Query - Point-in-Time (Time Travel)

```sql
WITH SatAsOf AS (
    SELECT
        HK_CUSTOMER, FIRST_NAME, LAST_NAME, Process_Date,
        ROW_NUMBER() OVER (
            PARTITION BY HK_CUSTOMER
            ORDER BY Process_Date DESC
        ) AS rn
    FROM [raw].[SAT_CUSTOMER_DETAILS]
    WHERE Process_Date <= @AsOfDate
      AND Process_Date > '1900-01-01'
)
SELECT
    h.CUSTOMER_ID,
    s.FIRST_NAME, s.LAST_NAME,
    s.Process_Date AS effective_date
FROM [raw].[HUB_CUSTOMER] AS h
INNER JOIN SatAsOf AS s
    ON h.HK_CUSTOMER = s.HK_CUSTOMER AND s.rn = 1;
```

## Change History (All Versions)

```sql
SELECT
    h.CUSTOMER_ID,
    s.FIRST_NAME, s.LAST_NAME, s.EMAIL,
    s.Process_Date AS version_date,
    s.Record_Source
FROM [raw].[HUB_CUSTOMER] AS h
INNER JOIN [raw].[SAT_CUSTOMER_DETAILS] AS s
    ON h.HK_CUSTOMER = s.HK_CUSTOMER
WHERE s.Process_Date > '1900-01-01'
ORDER BY h.CUSTOMER_ID, s.Process_Date;
```

## Effectivity Satellite Query (Insert-Only Pattern)

EffSats live on **Links** (never Hubs). Our EffSats use an **insert-only** pattern:

- Relationship columns are named `<Link_Name>_Relationship_Begin` / `<Link_Name>_Relationship_End`
- `Relationship_End` is never null; `9999-12-31 23:59:59.000` means still active
- Use a **self-join with `MAX(Load_Date)` subquery** + `BETWEEN` on relationship dates

```sql
-- Relationships active as of @AsOfDate (insert-only pattern)
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

**How this pattern works:**

1. Inner subquery: `MAX(Load_Date)` per hash key where `Process_Date <= @AsOfDate` finds the latest physical record.
2. Outer join retrieves the full row at that `Load_Date`.
3. `BETWEEN Relationship_Begin AND Relationship_End` checks business-time validity.
4. `MAX(Relationship_Begin)` + `GROUP BY` resolves ties.
5. For currently active: `Relationship_End = '9999-12-31 23:59:59.000'` passes the `BETWEEN`.
6. For expired: `@AsOfDate` falls outside the validity window, naturally excluding them.

```sql
-- Concrete example: Coverage_Plan relationships active as of 2025-05-02
SELECT
    [target].Coverage_Plan_Hash_Key,
    [target].Load_Date,
    [target].Record_Source,
    [target].System_Source,
    MAX([target].Coverage_Plan_Relationship_Begin) AS Coverage_Plan_Relationship_Begin,
    [target].Coverage_Plan_Relationship_End,
    [target].Process_Date
FROM DV.EffSat_Coverage_Plan AS [target]
INNER JOIN (
    SELECT
        [t2].Coverage_Plan_Hash_Key,
        MAX([t2].Load_Date) AS Load_Date
    FROM DV.EffSat_Coverage_Plan AS [t2]
    WHERE [t2].Process_Date <= '2025-05-02 23:59:59.000'
    GROUP BY [t2].Coverage_Plan_Hash_Key
) AS [max_target]
    ON  [target].Coverage_Plan_Hash_Key = [max_target].Coverage_Plan_Hash_Key
    AND [target].Load_Date = [max_target].Load_Date
WHERE
    '2025-05-02 23:59:59.000' BETWEEN [target].Coverage_Plan_Relationship_Begin
                                  AND [target].Coverage_Plan_Relationship_End
    AND [target].Process_Date <= '2025-05-02 23:59:59.000'
GROUP BY
    [target].Coverage_Plan_Hash_Key,
    [target].Load_Date,
    [target].Record_Source,
    [target].System_Source,
    [target].Coverage_Plan_Relationship_End,
    [target].Process_Date
ORDER BY
    [target].Coverage_Plan_Hash_Key;
```

## Information Mart Queries (Preferred for Reporting)

```sql
-- SCD1 dimension (current state only)
SELECT DIM_CUSTOMER_KEY, CUSTOMER_ID, FIRST_NAME, LAST_NAME, CITY
FROM [mart].[DIM_CUSTOMER]
WHERE CUSTOMER_ID = @CustomerId;

-- SCD2 dimension (historical)
SELECT *
FROM [mart].[DIM_CUSTOMER]
WHERE CUSTOMER_ID = @CustomerId
  AND IS_CURRENT = 1;

-- Fact + Dimension join (star schema pattern)
SELECT
    dc.CUSTOMER_ID, dc.FIRST_NAME,
    dp.PRODUCT_NAME,
    f.QUANTITY, f.UNIT_PRICE, f.EXTENDED_AMOUNT,
    dd.CALENDAR_DATE AS ORDER_DATE
FROM [mart].[FCT_SALES] AS f
INNER JOIN [mart].[DIM_CUSTOMER] AS dc ON f.FK_CUSTOMER = dc.DIM_CUSTOMER_KEY
INNER JOIN [mart].[DIM_PRODUCT] AS dp ON f.FK_PRODUCT = dp.DIM_PRODUCT_KEY
INNER JOIN [mart].[DIM_DATE] AS dd ON f.FK_DATE = dd.DIM_DATE_KEY
WHERE dc.IS_CURRENT = 1;
```


