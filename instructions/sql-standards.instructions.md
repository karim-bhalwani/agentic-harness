---
name: "SQL Coding Standards"
description: "T-SQL and SQL coding conventions: uppercase keywords, CTEs over nested subqueries, and aliasing rules for Azure SQL and SQL Server."
applyTo: "**/*.sql"
version: "8.0"
updated: "2026-05-03"
---

# SQL Coding Standards

---

## SQL Style

- Uppercase all SQL keywords (`SELECT`, `FROM`, `WHERE`, `JOIN`, `GROUP BY`, `ORDER BY`, etc.).
- Prefer CTEs (`WITH` clauses) over nested subqueries for readability and debuggability.
- Alias all tables and columns in multi-table queries. Fully qualify ambiguous column references.
- Always include schema prefix: write `dbo.TableName`, never bare `TableName`. Prevents ambiguity when multiple schemas exist.

---

## Correctness Rules

- **`IS NULL` / `IS NOT NULL`** - never `= NULL` or `<> NULL`. NULL comparisons with `=` always return `UNKNOWN`, silently dropping rows.
- **ISO 8601 date literals**: always use `'YYYY-MM-DD'` format (e.g., `'2024-01-15'`). Locale-specific formats like `'01/15/2024'` behave differently across SQL Server collations and regional settings.
- **Avoid implicit conversions**: explicitly `CAST` or `CONVERT` when comparing columns of different types. Implicit conversions silently disable index seeks.
