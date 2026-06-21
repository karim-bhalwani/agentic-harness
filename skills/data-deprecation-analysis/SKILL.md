---
name: data-deprecation-analysis
description: "Specialist in analyzing access logs to identify unused data structures, technical debt, and legacy patterns. Use when auditing data warehouses for deprecation candidates, detecting stale tables/views, identifying legacy application dependencies, or planning safe data asset retirement. DO NOT USE FOR: writing SQL queries (use data-analyst), building pipelines (use data-engineering), or data architecture (use architect)."
argument-hint: "[data warehouse or database to audit]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "9.0"
  updated: "01-July-2026"
  dependencies: ["data-engineering", "data-analyst", "guardian"]
---

# Data Deprecation Analysis

> Version: 9.0 | Updated: 01-July-2026 | Architect: Karim Bhalwani | Deps: data-engineering, data-analyst, guardian

## Dependencies

Load the following via `read_file` before using this skill:

- `skills/data-engineering/SKILL.md` - pipeline patterns, schema conventions, and Delta/dbt patterns referenced throughout deprecation analysis
- `skills/data-analyst/SKILL.md` - T-SQL and Data Vault querying patterns used to probe access logs and dependency graphs
- `skills/guardian/SKILL.md` - security and quality checks applied to deprecated object removal plans

## When to Use This Skill

Use when:

- Auditing data warehouses for unused tables, views, or stored procedures
- Planning data platform modernization or migration projects
- Identifying legacy application dependencies on data assets
- Detecting stale data structures that can be safely deprecated
- Analyzing access patterns to prioritize modernization efforts
- Building technical debt reports for leadership
- Identifying security risks from legacy or orphaned data objects

---

## Core Capabilities

1. **Dead Data Detection** - Analyze access logs to tier data objects by recency (Ghost/Cold/Cool/Active)
2. **Legacy Pattern Recognition** - Identify deprecated technologies (old ODBC drivers, legacy Excel, Access databases)
3. **Dependency Mapping** - Trace which applications, users, and service accounts access which objects
4. **Risk Assessment** - Flag security concerns (orphaned objects, stale service accounts, unoptimized queries)
5. **Deprecation Planning** - Generate actionable reports for safe data asset retirement
6. **Query Pattern Analysis** - Detect anti-patterns (SELECT \*, unfiltered scans, legacy joins)

---

## Workflow / Process

### Phase 1: Data Collection

1. Identify access log sources (SQL Server Audit, Splunk, application logs, ODBC traces)
2. Define key variables: Timestamp, Application_Name, Database_Object, User_Account, Query_Text
3. Establish analysis time window (typically 6-24 months)
4. Extract and normalize log data into analysis-ready format

### Phase 2: Dead Data Detection

1. Group access records by Database_Object
2. Calculate Max_Access_Date (last access) for each object
3. Assign tier based on access recency:
   - **Ghost Tier**: No access in >18 months
   - **Cold Tier**: No access in >12 months
   - **Cool Tier**: No access in >6 months
   - **Active**: Accessed within last 6 months
4. Prioritize false negatives: Any access in 6 months = Active

### Phase 3: Legacy Pattern Recognition

1. Filter for legacy Application_Name indicators:
   - Keywords: "Access", "Excel 2013", "ODBC 3.0", "Python Script", ".Net App"
2. Identify high-frequency queries from legacy applications
3. Flag anti-patterns: `SELECT *`, unfiltered table scans, deprecated syntax
4. Map legacy dependencies to data objects

### Phase 4: Risk Assessment & Reporting

1. Cross-reference Ghost/Cold objects with User_Account for contact information
2. Identify orphaned objects (no recent access, no known owner)
3. Flag security risks (stale service accounts, excessive permissions)
4. Generate tiered deprecation report with recommendations

---

## Outputs & Deliverables

- **Primary Output**: Tiered deprecation report (Ghost/Cold/Cool/Active counts with object details)
- **Secondary Output**: Legacy dependency map, contact list for last-known users, SQL/Python analysis scripts
- **Success Criteria**: All objects categorized, Ghost tier objects have owner contact info, actionable deprecation timeline
- **Quality Gate**: Zero false negatives (any recent access = Active), verified with stakeholders before deprecation

---

## Analysis Patterns

### Tiering Thresholds

| Tier   | Last Access | Risk Level              | Action                          |
| :----- | :---------- | :---------------------- | :------------------------------ |
| Ghost  | >18 months  | Low (safe to deprecate) | Archive and remove              |
| Cold   | >12 months  | Medium                  | Flag for review, contact owners |
| Cool   | >6 months   | Medium-High             | Monitor, investigate usage      |
| Active | <6 months   | N/A                     | Keep, optimize if needed        |

### Legacy Application Indicators

| Indicator               | Concern                         | Recommended Action                  |
| :---------------------- | :------------------------------ | :---------------------------------- |
| "Microsoft Access"      | End-of-life technology          | Migrate to modern BI tool           |
| "Excel 2013" or older   | Legacy Office version           | Upgrade or migrate workflow         |
| "ODBC 3.0"              | Outdated driver                 | Update connection strings           |
| Generic "Python Script" | Unknown/undocumented automation | Document and modernize              |
| ".Net App" (unnamed)    | Untracked application           | Identify owner, document dependency |

### Query Anti-Patterns

| Pattern           | Detection                       | Risk                                   |
| :---------------- | :------------------------------ | :------------------------------------- |
| `SELECT *`        | Regex: `SELECT\s+\*`            | Unoptimized, fragile to schema changes |
| No WHERE clause   | Full table scan detection       | Performance, cost concerns             |
| Deprecated syntax | `+=` joins, non-ANSI joins      | Compatibility risk                     |
| Hardcoded dates   | Regex: date literals in queries | Maintenance debt                       |

---

## Standards & Best Practices

### Data Collection

- Collect minimum 12 months of access logs for accurate tiering
- Normalize timestamps to UTC for consistent analysis
- Include both successful and failed access attempts
- Capture full query text when possible for pattern analysis

### Analysis Integrity

- **Prioritize False Negatives**: If accessed once in 6 months, mark as Active
- **Validate Object Existence**: Cross-reference with current catalog (some logged objects may be already dropped)
- **Account for Seasonality**: Some objects accessed only quarterly (fiscal reports)
- **Consider Indirect Access**: Views/procedures may access tables not directly queried

### Deprecation Safety

- Never deprecate without contacting last-known User_Account
- Archive to cold storage before permanent deletion
- Maintain deprecation log for audit trail
- Set grace period (30-90 days) between deprecation notice and removal
- Test downstream dependencies before removal

### Security Considerations

- Flag orphaned service accounts with data access
- Identify objects accessed by terminated employees
- Review excessive permissions on Cold/Ghost objects
- Document any PII/sensitive data in deprecated objects

---

## Integration Points

| Phase       | Input From         | Output To       | Context                          |
| :---------- | :----------------- | :-------------- | :------------------------------- |
| Collection  | data-engineer, ops | -               | Log extraction and normalization |
| Analysis    | -                  | data-engineer   | Technical debt assessment        |
| Reporting   | -                  | architect       | Strategic modernization planning |
| Remediation | data-engineer      | guardian        | Security risk validation         |
| Execution   | -                  | release-manager | Archive and removal automation   |

---

## Constraints

**Technical Constraints:**

- Requires access to database audit logs or ODBC traces
- Analysis accuracy depends on log completeness and retention
- Cannot detect objects accessed via dynamic SQL not captured in logs

**Scope Constraints:**

- In Scope: Tables, views, stored procedures, functions with access logs
- Out of Scope: Application code refactoring, infrastructure changes, data migration execution

**Governance Constraints:**

- All deprecation decisions require stakeholder approval
- Maintain audit trail of deprecated objects and approval chain
- Comply with data retention policies before permanent deletion

---

## Common Pitfalls

- **Seasonal Access Missed**: Quarterly/annual reports appear inactive. _Fix_: Use 18+ month window, verify with business calendar.
- **Dynamic SQL Not Logged**: Objects accessed via EXEC/sp*executesql may not appear in logs. \_Fix*: Enable extended events or query store.
- **Service Account Mapping**: Generic service accounts hide true ownership. _Fix_: Cross-reference with application inventory, contact team leads.
- **View Dependencies Ignored**: Table appears unused but accessed via views. _Fix_: Trace view dependencies before deprecating underlying tables.
- **False Confidence in Ghost Tier**: Object not accessed but still referenced in code. _Fix_: Grep codebase for object references before deprecation.
- **No Backup Before Removal**: Data permanently lost after deprecation. _Fix_: Always archive to cold storage with 90-day retention.

---

## References

Detailed implementation guides available in `references/` folder:

- [access-log-analysis.md](references/access-log-analysis.md) - SQL and Python scripts for log analysis
- [deprecation-report-template.md](references/deprecation-report-template.md) - Standard report format for stakeholders
- [legacy-pattern-detection.md](references/legacy-pattern-detection.md) - Regex and detection rules for legacy applications
