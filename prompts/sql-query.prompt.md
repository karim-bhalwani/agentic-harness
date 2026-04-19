---
agent: data-analyst
description: Translate a natural language question into a production-safe, copy-ready T-SQL query. Uses the data-analyst skill with Data Vault 2.0 awareness, schema exploration, and SARGable query hygiene. Use when you want SQL generated from plain English with proper Azure SQL conventions.
argument-hint: "[natural language question about your data]"
tools:
  - read
  - search
version: "7.0"
updated: "2026-04-12"
---

Answer this data question in T-SQL: **${input:question}**

**Database context** (fill in what you know):

- Database/schema: ${input:schema_or_context}
- Key tables involved (if known): ${input:tables}

**Requirements**:

- Produce copy-ready T-SQL that runs on Azure SQL Server without modification
- If the schema is unknown, start with schema exploration queries first, then the answer query
- Apply all checklist items from the data-analyst skill:
  - Explicit column list (no `SELECT *`)
  - `TOP` clause on exploratory queries
  - Header comment block with description, database, date, assumptions
  - SARGable WHERE clauses
  - PII columns flagged or masked
- If Data Vault patterns apply (Hubs, Links, Satellites), use the `data-vault-querying-cheatsheet.md` temporal patterns
- Document any assumptions about schema, nullability, or business logic

**Output format**:

1. Assumptions stated upfront (if any)
2. Schema exploration query (if schema is unknown)
3. Final answer query with header comment block
4. Brief explanation of what the query does (2-3 sentences)

