# SQL Optimization Reference

> Deep-dive reference. Loaded on demand for query tuning, index design, and EXPLAIN analysis tasks.

## Index Strategy

- B-tree for equality + range queries (default)
- Hash for equality-only lookups
- Composite indexes: most selective column first
- Covering indexes to avoid table lookups

### Composite Index Design

```sql
-- Good: selective column first, supports both equality and range
CREATE INDEX idx_orders_customer_date
ON orders (customer_id, order_date);

-- Covers queries:
--   WHERE customer_id = 'X'
--   WHERE customer_id = 'X' AND order_date > '2026-01-01'
-- Does NOT cover:
--   WHERE order_date > '2026-01-01'  (skips leading column)
```

### Covering Index Example

```sql
-- Avoids table lookup for common query pattern
CREATE INDEX idx_orders_covering
ON orders (customer_id, order_date)
INCLUDE (amount, status);
```

## Query Patterns

- **CTEs over subqueries**: readable, optimizable
- **EXISTS over IN** for correlated checks
- **Window functions** over self-joins for running totals/ranks
- **UNION ALL over UNION** when duplicates are impossible

### Window Function Example

```sql
-- Running total (replaces self-join)
SELECT
    order_id,
    order_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders;
```

### EXISTS vs IN

```sql
-- Prefer EXISTS for correlated checks (stops at first match)
SELECT c.customer_id, c.name
FROM customers AS c
WHERE EXISTS (
    SELECT 1 FROM orders AS o
    WHERE o.customer_id = c.customer_id
      AND o.order_date > '2026-01-01'
);

-- Avoid IN with large subqueries
-- WHERE customer_id IN (SELECT customer_id FROM orders WHERE ...)
```

## EXPLAIN Analysis

1. Run `EXPLAIN ANALYZE` on slow queries
2. Look for: Seq Scan (missing index), Nested Loop (need hash join), Sort (add index)
3. Check actual vs. estimated rows; large gaps = stale statistics
4. `ANALYZE` tables after bulk loads

### Reading EXPLAIN Output

| Indicator | Problem | Fix |
|---|---|---|
| Seq Scan on large table | Missing index | Add index on filter/join columns |
| Nested Loop with high row count | Wrong join strategy | Ensure statistics are current; consider hash join hints |
| Sort with high cost | Missing index for ORDER BY | Add index matching sort order |
| Actual rows >> Estimated rows | Stale statistics | Run `ANALYZE` on the table |
| Hash Join with large build side | Memory pressure | Ensure smaller table is on build side |

## Anti-Patterns to Avoid

- `SELECT *` in production queries
- Functions on indexed columns in WHERE (`WHERE UPPER(name) = 'X'`)
- Implicit type conversions in joins
- Correlated subqueries that execute per-row
- Missing `LIMIT` on exploratory queries
- `ORDER BY` without `LIMIT` on large result sets
- `DISTINCT` as a band-aid for duplicate joins (fix the join instead)
