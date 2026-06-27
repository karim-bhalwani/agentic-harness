---
name: data-analyst
description: "Azure SQL Server and T-SQL query specialist covering natural language to SQL conversion, schema exploration, Data Vault 2.0 querying patterns, query optimization, and SSMS workflows. Use when writing SQL queries from natural language requests, exploring database schemas, navigating Data Vault warehouses (Hubs, Links, Satellites, PIT, Bridge, EffSats), optimizing T-SQL performance, or generating copy-ready SQL scripts for Azure SQL or SQL Server databases. DO NOT USE FOR: building ETL/ELT pipelines (use data-engineering), PySpark or dbt transformations (use data-engineering), deprecation audits (use data-deprecation-analysis), or non-SQL database work."
argument-hint: "[natural language query or database task]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: []
---

# Data Analyst Skill

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani | Tiered: core (~150 lines) + on-demand references

Translates natural language requests into optimized, production-safe T-SQL against Azure SQL / SQL Server. For detailed patterns, load the appropriate deep-dive reference.

## Natural Language to SQL Workflow

### Intent Parsing

1. **Identify entities**: map nouns to tables/views
2. **Identify attributes**: map adjectives/descriptors to columns
3. **Identify operations**: map verbs to SQL operations (`SUM`, `COUNT`, `AVG`)
4. **Identify filters**: map conditions to `WHERE`/`HAVING` clauses
5. **Identify grouping**: map "by" phrases to `GROUP BY`
6. **Identify ordering**: map "top", "highest", "sorted by" to `ORDER BY` / `TOP`

### Ambiguity Resolution

- If a term maps to multiple tables, list candidates and ask
- If no schema context has been provided and the query references specific table or column names that cannot be verified, state explicitly: "I do not have schema information for this database. The following query is based on assumed naming conventions - validate table and column names before executing." Then generate the best-guess query using standard naming conventions.
- If the user's intent is unclear, propose 2-3 interpretations as SQL queries
- Always state assumptions
- For Data Vault: prefer Information Mart views over raw vault joins when they answer the question

### Output Format

Every SQL response MUST include:

```sql
-- ============================================================
-- Query: {brief description}
-- Database: {database name or "Confirm target database"}
-- Author: AI-Generated | Review before execution
-- Date: {current date}
-- Notes: {assumptions, caveats}
-- ============================================================
{SQL query}
```

## Query Strategy Decision Tree (Data Vault)

### Step 1: Check for Pre-Built Views

Before applying any temporal pattern, check whether a pre-built `Dim*`/`Fact*` or Information Mart view answers the question. If yes, query it directly and skip Steps 2-3.

- **"report", "dashboard", "summary"** → Query Dim*/Fact* (Information Mart) tables first

### Step 2: Identify Temporal Intent

- **"current", "latest", "active"** → Current state query
- **"as of [date]", "historical snapshot"** → Point-in-time query
- **"all changes", "history", "audit trail"** → Full history scan

### Step 3: Select Pattern by Intent

#### Current State

Use `ROW_NUMBER() OVER (PARTITION BY HK ORDER BY Process_Date DESC) = 1` to isolate latest record per entity.

#### Point-in-Time

Use PIT table if available, else apply `WHERE Process_Date <= @AsOfDate` + ROW_NUMBER.

#### Full History

Select all rows ordered by `Process_Date` (no filtering).

### Step 4: Handle Relationships

- **"relationship", "linked to"** → Join Hub → Link → Hub
- **"active relationship", "current subscription"** → Filter EffSat with `MAX(Load_Date)` + `BETWEEN`

**For full DV navigation protocol**: load [data-vault-navigation.md](./references/data-vault-navigation.md)

## Security Rules

- **NEVER** generate `DROP`, `DELETE`, `TRUNCATE`, `UPDATE`, or `INSERT` unless explicitly requested
- **Default to SELECT** (read-only) queries
- **Declare all filter values, date literals, and string constants as T-SQL variables** (e.g., `DECLARE @CustomerID INT = <value>`) at the top of the script so the query contains no inline literals
- **Warn** if a query might return PII and suggest masking
- **Add `TOP 100`** to any query where the user has not specified a row limit and the query does not aggregate to a summary result (i.e., no `GROUP BY` reducing to a small set). Annotate with: `-- Safety limit: remove if full result set is required`

### When DML Is Explicitly Requested

If the user explicitly requests `INSERT`, `UPDATE`, `DELETE`, or `TRUNCATE`:

1. Wrap the DML in `BEGIN TRANSACTION` / `ROLLBACK TRAN` with a comment instructing the user to change `ROLLBACK` to `COMMIT` after review
2. Add a `SELECT` preview query showing affected rows before the DML statement
3. Include a header warning at the top of the script:

```sql
-- WARNING: This script modifies data. Execute in a test environment first.
```

## Common Pitfalls

- **Implicit conversions**: matching types on joins prevents silent index kills
- **SELECT \***: never in production queries
- **Non-SARGable predicates**: no functions on indexed columns
- **DV: Forgetting temporal filtering**: every satellite query MUST use ROW_NUMBER for current state
- **DV: Joining EffSat to Hub**: EffSats attach to Links, never Hubs
- **DV: Ignoring ghost records**: always filter `WHERE Process_Date > '1900-01-01'`
- **DV: Ignoring PIT/Bridge**: check for pre-joined tables before writing ROW_NUMBER
- **DV: Using LOAD_DATE for time**: use `Process_Date` (reporting date)

## Constraints

- Does NOT build data pipelines (use `data-engineer`)
- Does NOT design schemas (use `architect`)
- Does NOT execute queries against production (generates scripts only)

## Definition of Done

- [ ] Syntactically valid T-SQL with explicit column names
- [ ] Filter values, date literals, and string constants declared as T-SQL variables at the top of the script
- [ ] Header comment block included
- [ ] DV queries use correct temporal patterns and filter ghost records
- [ ] PIT/Bridge/Mart tables preferred when available
- [ ] No `DROP`, `DELETE`, `TRUNCATE`, `UPDATE`, or `INSERT` unless explicitly requested
- [ ] PII columns flagged or masked

## References

Load on demand for specific sub-tasks:

- [data-vault-navigation.md](./references/data-vault-navigation.md) - DV layout discovery, entity types, column anatomy, ghost records. **Load when query targets a Data Vault warehouse.**
- [data-vault-querying-patterns.md](./references/data-vault-querying-patterns.md) - Full DV query patterns: ROW_NUMBER, PIT, Bridge, EffSat, Hub-Link-Hub, change history. **Load when writing DV joins.**
- [data-vault-querying-cheatsheet.md](./references/data-vault-querying-cheatsheet.md) - Quick-reference cheatsheet for DV patterns.
- [tsql-optimization-reference.md](./references/tsql-optimization-reference.md) - Schema exploration queries, index analysis, execution plans, SSMS tips, CTE patterns. **Load when optimizing queries or exploring schemas.**
- [schema-exploration-reference.md](./references/schema-exploration-reference.md) - sys.tables, sys.columns, FK relationships, index catalog.
