---
name: data-analyst
description: "Azure SQL Server and T-SQL query specialist covering natural language to SQL conversion, schema exploration, Data Vault 2.0 querying patterns, query optimization, and SSMS workflows. Use when writing SQL queries from natural language requests, exploring database schemas, navigating Data Vault warehouses (Hubs, Links, Satellites, PIT, Bridge, EffSats), optimizing T-SQL performance, or generating copy-ready SQL scripts for Azure SQL or SQL Server databases. DO NOT USE FOR: building ETL/ELT pipelines (use data-engineering), PySpark or dbt transformations (use data-engineering), deprecation audits (use data-deprecation-analysis), or non-SQL database work."
argument-hint: "[natural language query or database task]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: []
---

# Data Analyst Skill

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani | Tiered: core (~150 lines) + on-demand references

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

| User Says                                     | Strategy                     | Pattern                                                              |
| --------------------------------------------- | ---------------------------- | -------------------------------------------------------------------- |
| "current", "latest", "active"                 | Current state via ROW_NUMBER | `ROW_NUMBER() OVER (PARTITION BY HK ORDER BY Process_Date DESC) = 1` |
| "as of [date]", "historical snapshot"         | Point-in-time query          | PIT table or `WHERE Process_Date <= @AsOfDate` + ROW_NUMBER          |
| "all changes", "history", "audit trail"       | Full satellite scan          | All rows ordered by Process_Date                                     |
| "relationship", "linked to"                   | Hub-Link-Hub traversal       | Join through Link table                                              |
| "active relationship", "current subscription" | Effectivity Sat filter       | Self-join with `MAX(Load_Date)` + `BETWEEN`                          |
| "report", "dashboard", "summary"              | Information Mart first       | Check for Dim*/Fact* tables                                          |

**For full DV navigation protocol**: load [data-vault-navigation.md](./references/data-vault-navigation.md)

## Security Rules

- **NEVER** generate `DROP`, `DELETE`, `TRUNCATE`, `UPDATE`, or `INSERT` unless explicitly requested
- **Default to SELECT** (read-only) queries
- **Always parameterize** user-supplied values
- **Warn** if a query might return PII and suggest masking
- **Add `TOP 100`** to exploratory queries

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
- [ ] Parameterized values for user-supplied inputs
- [ ] Header comment block included
- [ ] DV queries use correct temporal patterns and filter ghost records
- [ ] PIT/Bridge/Mart tables preferred when available
- [ ] No destructive operations unless explicitly requested
- [ ] PII columns flagged or masked

## References

Load on demand for specific sub-tasks:

- [data-vault-navigation.md](./references/data-vault-navigation.md) - DV layout discovery, entity types, column anatomy, ghost records. **Load when query targets a Data Vault warehouse.**
- [data-vault-querying-patterns.md](./references/data-vault-querying-patterns.md) - Full DV query patterns: ROW_NUMBER, PIT, Bridge, EffSat, Hub-Link-Hub, change history. **Load when writing DV joins.**
- [data-vault-querying-cheatsheet.md](./references/data-vault-querying-cheatsheet.md) - Quick-reference cheatsheet for DV patterns.
- [tsql-optimization-reference.md](./references/tsql-optimization-reference.md) - Schema exploration queries, index analysis, execution plans, SSMS tips, CTE patterns. **Load when optimizing queries or exploring schemas.**
- [schema-exploration-reference.md](./references/schema-exploration-reference.md) - sys.tables, sys.columns, FK relationships, index catalog.
