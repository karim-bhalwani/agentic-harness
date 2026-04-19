# Data Vault 2.0 - Navigation Protocol

> Deep-dive reference. Loaded on demand when queries target a Data Vault warehouse.

## Step 0: Discover the DV Layout

DV warehouses vary in schema organization. Run schema discovery first - never assume a layout.

| Common Schema Names       | Layer               | Contents                                                      |
| ------------------------- | ------------------- | ------------------------------------------------------------- |
| `raw`, `rdv`, `DV`, `dbo` | Raw Data Vault      | Hubs, Links, Satellites, Effectivity Satellites               |
| `biz`, `bdv`, `bv`        | Business Data Vault | PIT tables, Bridge tables, Computed Satellites, Same-As Links |
| `mart`, `im`, `br`, `rpt` | Information Mart    | Dimensions (SCD1/SCD2), Fact tables, Star Schema views        |
| `staging`, `stg`, `psa`   | Staging / PSA       | Landing tables with pre-computed hash keys                    |
| `Admin`, `meta`, `ctrl`   | Metadata            | ETL metadata, batch control, DV metadata catalogs             |

**Action**: Run the DV detection query from [schema-exploration-reference.md](./schema-exploration-reference.md) to map the actual layout.

## Step 1: Identify DV Entity Types

Detect both naming conventions (case-insensitive matching):

| Entity           | Prefix Variants                                        | Example Names                                           |
| ---------------- | ------------------------------------------------------ | ------------------------------------------------------- |
| Hub              | `Hub_`, `HUB_`, `hub_`, `h_`                           | `Hub_Customer`, `HUB_CUSTOMER`, `hub_customer`          |
| Link             | `Link_`, `LNK_`, `lnk_`, `link_`, `l_`                 | `Link_Policy_Client`, `LNK_ORDER_PRODUCT`               |
| Satellite (Hub)  | `Sat_`, `SAT_`, `sat_`, `s_`                           | `Sat_Customer_Details`, `SAT_CUSTOMER_DETAILS`          |
| Satellite (Link) | `Sat_`, `SAT_`, `LSAT_`, `lsat_`                       | `Sat_Order_Product_Status`                              |
| Effectivity Sat  | `Eff_Sat_`, `EFF_SAT_`, `ESAT_`, `eff_sat_`, `EffSat_` | `Eff_Sat_Customer_Subscription`, `EffSat_Coverage_Plan` |
| PIT              | `PIT_`, `pit_`                                         | `PIT_Customer`, `pit_customer`                          |
| Bridge           | `Bridge_`, `BRG_`, `brg_`, `br_`                       | `Bridge_Order`, `BRG_ORDER`                             |
| Reference        | `Ref_`, `REF_`, `ref_`                                 | `Ref_Country`, `REF_COUNTRY`                            |
| Dimension        | `Dim_`, `DIM_`, `dim_`                                 | `Dim_Customer`, `DIM_CUSTOMER`                          |
| Fact             | `Fact_`, `FCT_`, `fct_`, `fact_`                       | `Fact_Sales`, `FCT_SALES`                               |

## Step 2: Check for Metadata Catalogs

Some DV warehouses maintain metadata tables that describe the model. Check for these:

```sql
-- Check for DV metadata catalog tables
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.name LIKE '%Meta_Data%'
   OR t.name LIKE '%metadata%'
   OR t.name LIKE '%meta_config%'
   OR t.name LIKE '%batch_control%'
ORDER BY s.name, t.name;
```

If found (e.g., `Admin.DV_Hub_Link_Meta_Data`, `Admin.DV_Satellite_Meta_Data`), query them to understand source-to-target mappings before writing joins.

## Step 3: Choose the Right Query Layer

**Decision order** (prefer the highest available layer):

1. **Information Mart views/tables** (`Dim_*`, `Fact_*`, `FCT_*`) - if they exist and answer the question, use them. They are pre-joined, business-friendly, and fastest.
2. **PIT / Bridge tables** - if the question requires multi-satellite joins on a single Hub, check for a PIT table first. If the question traverses multiple Links, check for a Bridge.
3. **Business Vault computed satellites** - pre-calculated business rules, aggregations.
4. **Raw Data Vault** (Hub + Link + Satellite joins) - the universal fallback. Always works, but requires temporal filtering.

## Step 4: Understand DV Column Anatomy

> **Team standard**: Our warehouse uses `Process_Date` (reporting date) for time determination, not `LOAD_DATE`.
> There is **no `LOAD_END_DATE`** column. Satellites and EffSats are insert-only.

| Column Pattern                   | Type                       | Found In         | Purpose                                                     |
| -------------------------------- | -------------------------- | ---------------- | ----------------------------------------------------------- |
| `HK_*`, `*_hk`, `*_HK`           | `BINARY(32)` or `CHAR(64)` | All DV entities  | SHA-256 hash key (PK or FK)                                 |
| `Hash_Difference`                | `BINARY(32)` or `CHAR(64)` | Satellites       | Change detection hash of all attributes                     |
| `Process_Date`                   | `DATETIME2(7)`             | All DV entities  | Reporting date the record is for (use for time queries)     |
| `Load_Date`                      | `DATETIME2(7)`             | All DV entities  | Warehouse insert timestamp (never null, can shift on fixes) |
| `Record_Source`                  | `NVARCHAR(100-200)`        | All DV entities  | Source system identifier                                    |
| `System_Source`                  | `NVARCHAR(100-200)`        | All DV entities  | Originating system identifier                               |
| `*_bk`, `*_BK`, `*_ID` (in Hub)  | Varies                     | Hubs             | Natural business key                                        |
| `<Link_Name>_Relationship_Begin` | `DATETIME2(7)`             | Effectivity Sats | Business-time validity start                                |
| `<Link_Name>_Relationship_End`   | `DATETIME2(7)`             | Effectivity Sats | `9999-12-31 23:59:59.000` = still active (never null)       |
| `PIT_DATE`, `snapshot_dts`       | `DATETIME2(7)`             | PIT tables       | Pre-computed snapshot timestamp                             |
| `LDTS_*`, `sat_*_load_dts`       | `DATETIME2(7)`             | PIT tables       | Satellite Process_Date coordinate for equi-join             |

## Ghost Record Awareness

DV warehouses may contain ghost records - placeholder rows inserted at table creation to enable pure equi-joins in PIT tables. **Always filter them out** in query results:

- Ghost `Process_Date`: `'1900-01-01'`
- Ghost hash keys: all-zero bytes (`0x0000...`)
- Ghost `Record_Source`: `'SYSTEM_GHOST'` or `'GHOST'`

```sql
-- Filter ghost records from satellite results
WHERE s.Process_Date > '1900-01-01'
-- Or equivalently:
WHERE s.Record_Source <> 'GHOST'
```


