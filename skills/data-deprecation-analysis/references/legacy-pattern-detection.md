# Legacy Pattern Detection

Detection rules and regex patterns for identifying legacy applications and query anti-patterns.

---

## Legacy Application Indicators

### Application Name Patterns

Use these regex patterns to identify legacy technologies in access logs:

```python
LEGACY_APPLICATION_PATTERNS = {
    # Microsoft Office Legacy
    'excel_legacy': r'Excel\s*(200[0-9]|201[0-3])',
    'access_any': r'Microsoft\s*Access|MS\s*Access|\.mdb|\.accdb',
    'office_legacy': r'Office\s*(200[0-9]|201[0-3])',
    
    # ODBC Driver Versions
    'odbc_legacy': r'ODBC\s*[1-3]\.[0-9]',
    'odbc_generic': r'ODBC\s*Driver',
    
    # Generic/Unknown Applications
    'python_generic': r'^Python\s*Script$|^Python$',
    'dotnet_generic': r'\.Net\s*App|\.NET\s*Application|Unknown.*\.Net',
    'unknown_app': r'^Unknown$|^<unknown>$|^NULL$',
    
    # Legacy Database Tools
    'sql_server_2008': r'SQL\s*Server\s*200[0-8]',
    'bcp_utility': r'^bcp$|bulk\s*copy',
    'dts_package': r'DTS|Data\s*Transformation\s*Services',
    
    # Legacy BI Tools
    'crystal_reports': r'Crystal\s*Reports',
    'cognos_legacy': r'Cognos\s*[7-9]|Cognos\s*10',
    'ssrs_legacy': r'SSRS\s*200[0-8]|Reporting\s*Services\s*200[0-8]'
}
```

### Risk Classification

| Pattern Category | Risk Level | Recommended Action |
|-----------------|------------|-------------------|
| Microsoft Access | Critical | Immediate migration plan |
| Excel 2013 or older | High | Upgrade or migrate to Power BI |
| ODBC 3.0 or older | High | Update connection strings |
| Unknown/Generic apps | Medium | Identify and document |
| Legacy BI tools | Medium | Plan tool upgrade |
| DTS packages | Critical | Migrate to SSIS |

---

## Query Anti-Patterns

### SELECT * Detection

```python
import re

def detect_select_star(query_text: str) -> bool:
    """Detect SELECT * anti-pattern."""
    pattern = r'SELECT\s+\*\s+FROM'
    return bool(re.search(pattern, query_text, re.IGNORECASE))

def detect_select_star_with_table(query_text: str) -> list:
    """Extract tables accessed with SELECT *."""
    pattern = r'SELECT\s+\*\s+FROM\s+(\[?[\w\.]+\]?)'
    matches = re.findall(pattern, query_text, re.IGNORECASE)
    return [m.strip('[]') for m in matches]
```

### Full Table Scan Detection

```python
def detect_no_where_clause(query_text: str) -> bool:
    """Detect queries without WHERE clause (potential full scans)."""
    # Check if SELECT without WHERE
    has_select = re.search(r'\bSELECT\b', query_text, re.IGNORECASE)
    has_where = re.search(r'\bWHERE\b', query_text, re.IGNORECASE)
    has_join_condition = re.search(r'\bON\b', query_text, re.IGNORECASE)
    
    # SELECT without WHERE and not just a JOIN
    return has_select and not has_where and not has_join_condition
```

### Deprecated Syntax Detection

```python
DEPRECATED_PATTERNS = {
    'old_outer_join': r'\*=|\=\*',  # Old-style outer join syntax
    'non_ansi_join': r'FROM\s+\w+\s*,\s*\w+\s+WHERE',  # Comma joins
    'nolock_hint': r'WITH\s*\(\s*NOLOCK\s*\)',  # Often misused
    'cross_apply_without_filter': r'CROSS\s+APPLY(?!.*WHERE)',
}

def detect_deprecated_syntax(query_text: str) -> dict:
    """Detect deprecated SQL syntax patterns."""
    findings = {}
    for pattern_name, pattern in DEPRECATED_PATTERNS.items():
        if re.search(pattern, query_text, re.IGNORECASE):
            findings[pattern_name] = True
    return findings
```

---

## User Account Analysis

### Service Account Patterns

```python
SERVICE_ACCOUNT_PATTERNS = {
    'sql_agent': r'SQLAgent|SQL\s*Server\s*Agent',
    'service_account': r'svc_|_svc|service_|_service',
    'app_account': r'app_|_app|application_',
    'etl_account': r'etl_|_etl|ssis_|_ssis',
    'reporting': r'report_|_report|ssrs_|_ssrs',
    'generic_system': r'^sa$|^system$|^admin$'
}

def classify_user_account(user_account: str) -> str:
    """Classify user account type."""
    for account_type, pattern in SERVICE_ACCOUNT_PATTERNS.items():
        if re.search(pattern, user_account, re.IGNORECASE):
            return account_type
    return 'interactive_user'
```

### Orphaned Account Detection

```python
def identify_orphaned_accounts(
    access_df: pd.DataFrame, 
    active_directory_users: list,
    last_activity_threshold_days: int = 180
) -> pd.DataFrame:
    """Identify potentially orphaned accounts."""
    
    # Accounts not in AD
    unknown_accounts = access_df[
        ~access_df['User_Account'].isin(active_directory_users)
    ]['User_Account'].unique()
    
    # Accounts with old last activity
    account_activity = access_df.groupby('User_Account')['Timestamp'].max()
    stale_accounts = account_activity[
        account_activity < (datetime.now() - timedelta(days=last_activity_threshold_days))
    ].index.tolist()
    
    return {
        'not_in_ad': list(unknown_accounts),
        'stale_activity': stale_accounts
    }
```

---

## SQL Server Detection Queries

### Legacy Application Detection

```sql
-- Identify legacy applications in audit logs
SELECT 
    application_name,
    COUNT(*) AS Query_Count,
    COUNT(DISTINCT session_server_principal_name) AS Unique_Users,
    MIN(event_time) AS First_Seen,
    MAX(event_time) AS Last_Seen,
    CASE 
        WHEN application_name LIKE '%Access%' THEN 'CRITICAL - Microsoft Access'
        WHEN application_name LIKE '%Excel 201[0-3]%' THEN 'HIGH - Legacy Excel'
        WHEN application_name LIKE '%ODBC%' THEN 'MEDIUM - ODBC Driver'
        WHEN application_name LIKE '%Python%' THEN 'MEDIUM - Generic Python'
        WHEN application_name LIKE '%.Net%' THEN 'MEDIUM - Generic .NET'
        ELSE 'LOW - Standard Application'
    END AS Risk_Level
FROM sys.fn_get_audit_file('*.sqlaudit', DEFAULT, DEFAULT)
WHERE application_name IS NOT NULL
GROUP BY application_name
ORDER BY 
    CASE 
        WHEN application_name LIKE '%Access%' THEN 1
        WHEN application_name LIKE '%Excel 201[0-3]%' THEN 2
        WHEN application_name LIKE '%ODBC%' THEN 3
        ELSE 4
    END,
    Query_Count DESC;
```

### SELECT * Detection

```sql
-- Find queries using SELECT *
SELECT 
    object_name AS Database_Object,
    session_server_principal_name AS User_Account,
    application_name AS Application,
    statement AS Query_Text,
    event_time AS Execution_Time
FROM sys.fn_get_audit_file('*.sqlaudit', DEFAULT, DEFAULT)
WHERE statement LIKE '%SELECT%*%FROM%'
  AND statement NOT LIKE '%COUNT(*)%'  -- Exclude COUNT(*)
ORDER BY event_time DESC;
```

### Service Account Analysis

```sql
-- Analyze service account activity
SELECT 
    session_server_principal_name AS User_Account,
    CASE 
        WHEN session_server_principal_name LIKE 'svc_%' THEN 'Service Account'
        WHEN session_server_principal_name LIKE 'app_%' THEN 'Application Account'
        WHEN session_server_principal_name LIKE 'etl_%' THEN 'ETL Account'
        ELSE 'Interactive User'
    END AS Account_Type,
    COUNT(DISTINCT object_name) AS Objects_Accessed,
    COUNT(*) AS Total_Queries,
    MAX(event_time) AS Last_Activity
FROM sys.fn_get_audit_file('*.sqlaudit', DEFAULT, DEFAULT)
GROUP BY session_server_principal_name
ORDER BY Last_Activity DESC;
```

---

## Comprehensive Detection Pipeline

```python
class LegacyPatternDetector:
    """Complete legacy pattern detection for access logs."""
    
    def __init__(self, df: pd.DataFrame):
        self.df = df
        self.findings = {}
    
    def detect_all(self) -> dict:
        """Run all detection patterns."""
        self.findings = {
            'legacy_applications': self._detect_legacy_apps(),
            'query_antipatterns': self._detect_antipatterns(),
            'service_accounts': self._analyze_accounts(),
            'risk_summary': self._calculate_risk()
        }
        return self.findings
    
    def _detect_legacy_apps(self) -> pd.DataFrame:
        """Detect legacy application usage."""
        pattern = '|'.join(LEGACY_APPLICATION_PATTERNS.values())
        legacy_mask = self.df['Application_Name'].str.contains(
            pattern, case=False, regex=True, na=False
        )
        return self.df[legacy_mask].groupby('Application_Name').agg(
            Query_Count=('Timestamp', 'count'),
            Objects_Accessed=('Database_Object', 'nunique'),
            Last_Access=('Timestamp', 'max')
        ).reset_index()
    
    def _detect_antipatterns(self) -> dict:
        """Detect query anti-patterns."""
        return {
            'select_star_count': self.df['Query_Text'].apply(
                detect_select_star
            ).sum(),
            'no_where_clause_count': self.df['Query_Text'].apply(
                detect_no_where_clause
            ).sum()
        }
    
    def _analyze_accounts(self) -> pd.DataFrame:
        """Classify and analyze user accounts."""
        account_summary = self.df.groupby('User_Account').agg(
            Query_Count=('Timestamp', 'count'),
            Last_Activity=('Timestamp', 'max')
        ).reset_index()
        
        account_summary['Account_Type'] = account_summary['User_Account'].apply(
            classify_user_account
        )
        return account_summary
    
    def _calculate_risk(self) -> dict:
        """Calculate overall risk score."""
        legacy_count = len(self._detect_legacy_apps())
        antipattern_count = sum(self._detect_antipatterns().values())
        
        return {
            'legacy_app_risk': 'HIGH' if legacy_count > 5 else 'MEDIUM' if legacy_count > 0 else 'LOW',
            'antipattern_risk': 'HIGH' if antipattern_count > 100 else 'MEDIUM' if antipattern_count > 10 else 'LOW'
        }
```


