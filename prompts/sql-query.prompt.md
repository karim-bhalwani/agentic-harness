---
agent: data-analyst
description: Translate a natural language question into a production-safe, copy-ready T-SQL query. Uses the data-analyst skill with Data Vault 2.0 awareness, schema exploration, and SARGable query hygiene. Use when you want SQL generated from plain English with proper Azure SQL conventions.
argument-hint: "[natural language question about your data]"
tools:
  - read
  - search
---

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani |

Answer this data question in T-SQL: **${input:question}**

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
