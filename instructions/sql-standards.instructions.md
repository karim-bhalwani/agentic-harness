---
name: "SQL Coding Standards"
description: "T-SQL and SQL coding conventions: uppercase keywords, CTEs over nested subqueries, aliasing rules, indexing, migrations, idempotency, and injection prevention for Azure SQL and SQL Server."
applyTo: "**/*.sql"
version: "9.0"
updated: "01-July-2026"
---

# SQL Coding Standards

**Version:** 9.0 | **Updated:** 01-July-2026

---

## SQL Style

- Uppercase all SQL keywords (`SELECT`, `FROM`, `WHERE`, `JOIN`, `GROUP BY`, `ORDER BY`, etc.).
- Prefer CTEs (`WITH` clauses) over nested subqueries for readability and debuggability. This preference applies to subqueries in `FROM` clauses. Correlated subqueries in `SELECT` lists or `WHERE EXISTS`/`IN` clauses are acceptable when a CTE rewrite would not improve clarity.
- Alias all tables and columns in multi-table queries. Always qualify table references with schema prefix (e.g., `dbo.TableName`). Always qualify column references with their table alias to eliminate ambiguity.
- Use `AS` for column and table aliases (e.g., `SELECT c.CustomerID AS ID`). Do not use `=` for aliasing.
- Indent SQL consistently: one level per clause, aligned keywords.

---

## Correctness Rules

- **`IS NULL` / `IS NOT NULL`** - never `= NULL` or `<> NULL`. NULL comparisons with `=` always return `UNKNOWN`, silently dropping rows.
- **ISO 8601 date literals**: always use `'YYYY-MM-DD'` format (e.g., `'2024-01-15'`). Locale-specific formats like `'01/15/2024'` behave differently across SQL Server collations and regional settings.
- **Avoid implicit conversions**: explicitly `CAST` or `CONVERT` when comparing columns of different types. Implicit conversions silently disable index seeks.
- **Prohibit `SELECT *`**: always enumerate columns explicitly. `SELECT *` breaks consumers when schema changes, prevents covering index usage, and wastes network bandwidth.
- **Use `SET NOCOUNT ON`** in stored procedures to suppress row-count messages and reduce network round-trips.

---

## Indexing Guidelines

- **Covering indexes**: include all columns referenced in `SELECT`, `WHERE`, `JOIN`, and `ORDER BY` clauses to enable index-only scans.
- **Avoid functions on indexed columns in WHERE**: `WHERE YEAR(CreatedDate) = 2024` disables index seeks. Use range filters instead: `WHERE CreatedDate >= '2024-01-01' AND CreatedDate < '2025-01-01'`.
- **Watch for implicit conversions in JOINs**: joining `VARCHAR` to `NVARCHAR` columns forces scans. Ensure join key types match.
- **Index foreign key columns**: foreign keys used in JOINs benefit from indexes even if not explicitly declared.

---

## Dynamic SQL and Injection Prevention

- **Parameterize all dynamic SQL**: use `sp_executesql` with typed parameters, never string concatenation.
- **Sanitize object names with `QUOTENAME()`**: when dynamically referencing table or column names, wrap them in `QUOTENAME()` to prevent injection.
- **Never concatenate user input into SQL strings**: even internal tools must use parameterized queries.
- **Validate dynamic object names against `sys.objects`/`sys.columns`**: before using a dynamically provided name, verify it exists.

---

## Transaction and Error Handling

- **Use `BEGIN TRAN` / `COMMIT` / `ROLLBACK`** for multi-statement operations that must succeed or fail atomically.
- **Wrap transactions in `TRY...CATCH`**: ensure `ROLLBACK` runs on error to prevent orphaned transactions.
- **Set `XACT_ABORT ON`**: ensures the transaction is automatically rolled back on runtime errors.
- **Keep transactions short**: long-held locks block other operations. Do not include user interaction or external calls inside transactions.

---

## Migration and Idempotency Constraints

- **All migration scripts must be idempotent**: running a script N times must produce the same result as running it once. Use `IF NOT EXISTS` guards for object creation.
- **Use `IF EXISTS` before `DROP`**: avoid errors when objects do not exist.
- **Check for column existence before `ALTER TABLE ADD`**: use `IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE ...)`.
- **Version migrations**: include a version number or timestamp comment at the top of each migration file.
- **Never modify a published migration**: if a deployed migration needs correction, create a new migration file. Modifying published migrations breaks environments that already applied the original.

---

## Query Performance

- **Avoid cursors**: set-based operations outperform row-by-row processing. Use window functions or `APPLY` instead.
- **Use `EXISTS` instead of `IN` for subqueries**: `EXISTS` short-circuits on first match; `IN` materializes the full subquery result.
- **Limit result sets**: use `TOP`, `OFFSET/FETCH`, or `WHERE` filters to avoid returning unnecessary rows.
- **Review execution plans**: for queries touching large tables, verify the plan uses seeks not scans.
