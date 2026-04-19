# Deprecation Report Template

Standard format for presenting data deprecation analysis to stakeholders.

---

## Executive Summary

**Analysis Period**: [Start Date] to [End Date]  
**Total Objects Analyzed**: [Count]  
**Recommendation**: [Summary statement on deprecation readiness]

### Tier Distribution

| Tier | Count | Percentage | Recommendation |
|------|-------|------------|----------------|
| Ghost (>18mo) | [X] | [X%] | Ready for deprecation |
| Cold (>12mo) | [X] | [X%] | Review with owners |
| Cool (>6mo) | [X] | [X%] | Monitor closely |
| Active (<6mo) | [X] | [X%] | No action needed |

### Key Findings

1. **[Finding 1]**: Brief description of significant discovery
2. **[Finding 2]**: Brief description of significant discovery
3. **[Finding 3]**: Brief description of significant discovery

---

## Ghost Tier Objects (Deprecation Candidates)

Objects with no access in 18+ months. These are safe deprecation candidates pending owner verification.

| Object Name | Last Access | Days Inactive | Last User | Last Application | Owner Contact |
|-------------|-------------|---------------|-----------|------------------|---------------|
| [table_name] | [date] | [X] | [user] | [app] | [email/team] |

### Recommended Actions

- [ ] Contact listed owners for deprecation approval
- [ ] Archive data to cold storage before removal
- [ ] Set deprecation notice period (30 days recommended)
- [ ] Schedule removal after grace period

---

## Cold Tier Objects (Review Required)

Objects with no access in 12-18 months. Require investigation before deprecation.

| Object Name | Last Access | Days Inactive | Last User | Last Application | Notes |
|-------------|-------------|---------------|-----------|------------------|-------|
| [table_name] | [date] | [X] | [user] | [app] | [context] |

### Investigation Checklist

- [ ] Verify object is not accessed via dynamic SQL
- [ ] Check for view/procedure dependencies
- [ ] Confirm no scheduled jobs reference this object
- [ ] Contact last known user for business context

---

## Cool Tier Objects (Monitor)

Objects with access in 6-12 months. May be seasonal or low-frequency usage.

| Object Name | Last Access | Access Count (12mo) | Primary Users | Primary Applications |
|-------------|-------------|---------------------|---------------|---------------------|
| [table_name] | [date] | [X] | [users] | [apps] |

### Recommended Actions

- Continue monitoring for 6 months
- Investigate if access count is declining
- Document business purpose if unknown

---

## Legacy Application Dependencies

Applications using deprecated technologies that access the data warehouse.

| Application | Technology | Objects Accessed | Query Count | Risk Level | Recommended Action |
|-------------|------------|------------------|-------------|------------|-------------------|
| [app_name] | [tech] | [count] | [X] | High/Medium/Low | [action] |

### Anti-Patterns Detected

| Pattern | Occurrences | Objects Affected | Performance Impact |
|---------|-------------|------------------|-------------------|
| SELECT * | [X] | [list] | High - retrieves unnecessary data |
| No WHERE clause | [X] | [list] | High - full table scans |
| Deprecated joins | [X] | [list] | Medium - compatibility risk |

---

## Security Concerns

### Orphaned Objects

Objects with no recent access and no identifiable owner.

| Object Name | Last Access | Last User (if known) | Contains PII | Recommendation |
|-------------|-------------|---------------------|--------------|----------------|
| [table_name] | [date] | [user] | Yes/No | [action] |

### Stale Service Accounts

Service accounts accessing data that may need review.

| Service Account | Objects Accessed | Last Activity | Owner Team | Status |
|-----------------|------------------|---------------|------------|--------|
| [account] | [X] | [date] | [team] | Active/Review/Disable |

---

## Deprecation Timeline

### Phase 1: Ghost Tier (Weeks 1-4)

| Week | Action | Objects | Owner |
|------|--------|---------|-------|
| 1 | Send deprecation notices | [X] objects | Data Platform Team |
| 2 | Collect approvals | - | Object Owners |
| 3 | Archive to cold storage | Approved objects | Data Platform Team |
| 4 | Remove from production | Archived objects | Data Platform Team |

### Phase 2: Cold Tier Investigation (Weeks 5-8)

| Week | Action | Objects | Owner |
|------|--------|---------|-------|
| 5-6 | Owner interviews | [X] objects | Data Platform Team |
| 7 | Dependency analysis | Confirmed unused | Data Platform Team |
| 8 | Move to Ghost tier or reactivate | Investigated objects | Data Platform Team |

---

## Appendix

### Methodology

- **Data Source**: [SQL Server Audit / Query Store / Extended Events / Splunk]
- **Analysis Window**: [X] months of access logs
- **Tiering Logic**: Based on MAX(access_timestamp) per object
- **False Negative Prevention**: Any access in 6 months = Active tier

### Assumptions & Limitations

1. Dynamic SQL executed via EXEC/sp_executesql may not be fully captured
2. Objects accessed only via views appear as view access, not table access
3. Service account access may mask true user identity
4. Seasonal objects (quarterly/annual reports) may appear inactive

### Data Sources

| Source | Date Range | Record Count | Coverage |
|--------|------------|--------------|----------|
| [source] | [dates] | [X] | [description] |

---

## Approval Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Data Platform Lead | | | |
| Security Officer | | | |
| Business Stakeholder | | | |


