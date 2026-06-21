---
agent: data-analyst
description: Translate a natural language question into a production-safe, copy-ready T-SQL query. Uses the data-analyst skill with Data Vault 2.0 awareness, schema exploration, and SARGable query hygiene. Use when you want SQL generated from plain English with proper Azure SQL conventions.
argument-hint: "[natural language question about your data]"
tools:
  - read
  - search
---

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani |

Answer this data question in T-SQL: **${input:question}** (e.g., "What is the total sales for last month?")

If the input question is invalid or nonsensical, respond with an error message explaining the issue and requesting clarification.

**Handling ambiguous or incomplete questions**:

- **Missing time frame**: If the question lacks temporal specificity (e.g., "What are the top customers?"), ask the user to specify a date range or period.
- **Undefined metrics**: If the question references undefined fields (e.g., "sales by region" without specifying revenue, units, or orders), ask for clarification on which metric to use.
- **Missing scope/filter**: If the question is too broad (e.g., "Show all data"), ask the user to narrow the scope by business unit, product, customer segment, or other relevant dimension.
- **Ambiguous references**: If table or column names could map to multiple database objects, list the available options and ask which one applies.

Example responses:

- "Your question lacks a time frame. Could you specify whether you mean 'this month,' 'last quarter,' or a custom date range?"
- "You asked for 'sales.' Do you mean total revenue, number of orders, or units sold?"
- "Which region(s) should I include - all regions, a specific country, or a particular sales territory?"

**Database context** (fill in what you know):

- Database/schema: ${input:schema_or_context}
- Key tables involved (if known): ${input:tables}

**Workflow**: Load `skills/data-analyst/SKILL.md` via `read_file`. The skill is the single source of truth for the production-safety checklist (explicit columns, TOP on exploratory queries, header comment block, SARGable predicates, PII handling) and for Data Vault 2.0 querying patterns (Hubs, Links, Satellites, PIT/Bridge/EffSat) via `data-vault-querying-cheatsheet.md`. Follow the skill's checklist; do not paraphrase it here.

**Required output**:

1. Assumptions stated upfront (if any)
2. Schema exploration query (if schema is unknown)
3. Final answer query with header comment block per the skill
4. Brief explanation of what the query does (2-3 sentences)

The query must run on Azure SQL Server without modification.
