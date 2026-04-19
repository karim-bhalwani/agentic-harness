# Access Log Analysis Scripts

SQL and Python scripts for analyzing ODBC access logs to identify unused data structures.

## SQL Server Analysis Query

Use this query against SQL Server audit tables or Query Store:

```sql
-- Dead Data Detection: Tier objects by last access date
WITH ObjectAccess AS (
    SELECT 
        database_name,
        object_name AS Database_Object,
        MAX(event_time) AS Max_Access_Date,
        COUNT(*) AS Access_Count,
        COUNT(DISTINCT session_server_principal_name) AS Unique_Users,
        MAX(session_server_principal_name) AS Last_User_Account,
        MAX(application_name) AS Last_Application
    FROM sys.fn_get_audit_file('path_to_audit_files/*.sqlaudit', DEFAULT, DEFAULT)
    WHERE object_name IS NOT NULL
      AND event_time >= DATEADD(MONTH, -24, GETDATE())  -- 24-month window
    GROUP BY database_name, object_name
),
TieredObjects AS (
    SELECT 
        *,
        CASE 
            WHEN Max_Access_Date >= DATEADD(MONTH, -6, GETDATE()) THEN 'Active'
            WHEN Max_Access_Date >= DATEADD(MONTH, -12, GETDATE()) THEN 'Cool'
            WHEN Max_Access_Date >= DATEADD(MONTH, -18, GETDATE()) THEN 'Cold'
            ELSE 'Ghost'
        END AS Access_Tier,
        DATEDIFF(DAY, Max_Access_Date, GETDATE()) AS Days_Since_Access
    FROM ObjectAccess
)
SELECT 
    Access_Tier,
    Database_Object,
    Max_Access_Date,
    Days_Since_Access,
    Access_Count,
    Unique_Users,
    Last_User_Account,
    Last_Application
FROM TieredObjects
ORDER BY 
    CASE Access_Tier 
        WHEN 'Ghost' THEN 1 
        WHEN 'Cold' THEN 2 
        WHEN 'Cool' THEN 3 
        ELSE 4 
    END,
    Days_Since_Access DESC;
```

## Tier Summary Query

```sql
-- Summary counts by tier
WITH ObjectAccess AS (
    SELECT 
        object_name AS Database_Object,
        MAX(event_time) AS Max_Access_Date
    FROM sys.fn_get_audit_file('path_to_audit_files/*.sqlaudit', DEFAULT, DEFAULT)
    WHERE object_name IS NOT NULL
      AND event_time >= DATEADD(MONTH, -24, GETDATE())
    GROUP BY object_name
),
TieredObjects AS (
    SELECT 
        CASE 
            WHEN Max_Access_Date >= DATEADD(MONTH, -6, GETDATE()) THEN 'Active'
            WHEN Max_Access_Date >= DATEADD(MONTH, -12, GETDATE()) THEN 'Cool'
            WHEN Max_Access_Date >= DATEADD(MONTH, -18, GETDATE()) THEN 'Cold'
            ELSE 'Ghost'
        END AS Access_Tier
    FROM ObjectAccess
)
SELECT 
    Access_Tier,
    COUNT(*) AS Object_Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM TieredObjects
GROUP BY Access_Tier
ORDER BY 
    CASE Access_Tier 
        WHEN 'Ghost' THEN 1 
        WHEN 'Cold' THEN 2 
        WHEN 'Cool' THEN 3 
        ELSE 4 
    END;
```

## Python Pandas Analysis Script

```python
"""
Data Deprecation Analysis Script
Analyzes ODBC access logs to identify unused data structures.
"""

import pandas as pd
from datetime import datetime, timedelta
from typing import Literal

# Configuration
ANALYSIS_DATE = datetime.now()
GHOST_THRESHOLD = 18  # months
COLD_THRESHOLD = 12   # months
COOL_THRESHOLD = 6    # months

# Legacy application patterns
LEGACY_PATTERNS = [
    'Microsoft Access',
    'Excel 2013', 'Excel 2010', 'Excel 2007',
    'ODBC 3.0', 'ODBC 2.0',
    'Python Script',
    '.Net App',
    'Unknown'
]


def load_access_logs(file_path: str) -> pd.DataFrame:
    """Load and normalize access log data."""
    df = pd.read_csv(file_path, parse_dates=['Timestamp'])
    
    # Normalize column names
    df.columns = df.columns.str.strip().str.replace(' ', '_')
    
    # Ensure required columns exist
    required_cols = ['Timestamp', 'Application_Name', 'Database_Object', 
                     'User_Account', 'Query_Text']
    missing = set(required_cols) - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {missing}")
    
    return df


def assign_access_tier(last_access: datetime) -> Literal['Ghost', 'Cold', 'Cool', 'Active']:
    """Assign tier based on last access date."""
    months_since_access = (ANALYSIS_DATE - last_access).days / 30
    
    if months_since_access > GHOST_THRESHOLD:
        return 'Ghost'
    elif months_since_access > COLD_THRESHOLD:
        return 'Cold'
    elif months_since_access > COOL_THRESHOLD:
        return 'Cool'
    else:
        return 'Active'


def detect_dead_data(df: pd.DataFrame) -> pd.DataFrame:
    """Part 1: Dead Data Detection - Group by object and assign tiers."""
    
    # Aggregate by database object
    object_summary = df.groupby('Database_Object').agg(
        Max_Access_Date=('Timestamp', 'max'),
        Access_Count=('Timestamp', 'count'),
        Unique_Users=('User_Account', 'nunique'),
        Last_User_Account=('User_Account', 'last'),
        Last_Application=('Application_Name', 'last')
    ).reset_index()
    
    # Assign tiers
    object_summary['Access_Tier'] = object_summary['Max_Access_Date'].apply(assign_access_tier)
    object_summary['Days_Since_Access'] = (ANALYSIS_DATE - object_summary['Max_Access_Date']).dt.days
    
    # Sort by tier priority
    tier_order = {'Ghost': 0, 'Cold': 1, 'Cool': 2, 'Active': 3}
    object_summary['Tier_Sort'] = object_summary['Access_Tier'].map(tier_order)
    object_summary = object_summary.sort_values(['Tier_Sort', 'Days_Since_Access'], 
                                                  ascending=[True, False])
    
    return object_summary.drop('Tier_Sort', axis=1)


def detect_legacy_patterns(df: pd.DataFrame) -> pd.DataFrame:
    """Part 2: Legacy Pattern Recognition."""
    
    # Filter for legacy applications
    legacy_mask = df['Application_Name'].str.contains(
        '|'.join(LEGACY_PATTERNS), 
        case=False, 
        na=False
    )
    legacy_df = df[legacy_mask].copy()
    
    # Identify SELECT * anti-pattern
    legacy_df['Has_Select_Star'] = legacy_df['Query_Text'].str.contains(
        r'SELECT\s+\*', 
        case=False, 
        regex=True, 
        na=False
    )
    
    # Aggregate by application and object
    legacy_summary = legacy_df.groupby(['Application_Name', 'Database_Object']).agg(
        Query_Count=('Timestamp', 'count'),
        Select_Star_Count=('Has_Select_Star', 'sum'),
        Last_Access=('Timestamp', 'max'),
        Sample_User=('User_Account', 'first')
    ).reset_index()
    
    # Sort by frequency
    legacy_summary = legacy_summary.sort_values('Query_Count', ascending=False)
    
    return legacy_summary


def generate_tier_summary(object_summary: pd.DataFrame) -> pd.DataFrame:
    """Generate summary counts by tier."""
    summary = object_summary.groupby('Access_Tier').agg(
        Object_Count=('Database_Object', 'count')
    ).reset_index()
    
    summary['Percentage'] = (summary['Object_Count'] / summary['Object_Count'].sum() * 100).round(2)
    
    # Sort by tier priority
    tier_order = {'Ghost': 0, 'Cold': 1, 'Cool': 2, 'Active': 3}
    summary['Tier_Sort'] = summary['Access_Tier'].map(tier_order)
    summary = summary.sort_values('Tier_Sort').drop('Tier_Sort', axis=1)
    
    return summary


def main(input_file: str, output_prefix: str = 'deprecation_analysis'):
    """Main analysis workflow."""
    
    print(f"Loading access logs from {input_file}...")
    df = load_access_logs(input_file)
    print(f"Loaded {len(df):,} access records")
    
    # Part 1: Dead Data Detection
    print("\nPart 1: Dead Data Detection...")
    object_summary = detect_dead_data(df)
    object_summary.to_csv(f'{output_prefix}_object_tiers.csv', index=False)
    
    # Tier Summary
    tier_summary = generate_tier_summary(object_summary)
    print("\nTier Summary:")
    print(tier_summary.to_string(index=False))
    tier_summary.to_csv(f'{output_prefix}_tier_summary.csv', index=False)
    
    # Part 2: Legacy Pattern Recognition
    print("\nPart 2: Legacy Pattern Recognition...")
    legacy_summary = detect_legacy_patterns(df)
    legacy_summary.to_csv(f'{output_prefix}_legacy_patterns.csv', index=False)
    print(f"Found {len(legacy_summary):,} legacy access patterns")
    
    # Ghost tier details for follow-up
    ghost_objects = object_summary[object_summary['Access_Tier'] == 'Ghost']
    ghost_objects.to_csv(f'{output_prefix}_ghost_tier.csv', index=False)
    print(f"\nGhost Tier: {len(ghost_objects):,} objects ready for deprecation review")
    
    print(f"\nAnalysis complete. Files saved with prefix: {output_prefix}_")


if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        print("Usage: python access_log_analysis.py <input_file.csv> [output_prefix]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_prefix = sys.argv[2] if len(sys.argv) > 2 else 'deprecation_analysis'
    main(input_file, output_prefix)
```

## Query Store Analysis (SQL Server 2016+)

```sql
-- Analyze Query Store for object access patterns
SELECT 
    OBJECT_NAME(qsq.object_id) AS Database_Object,
    MAX(qsrs.last_execution_time) AS Max_Access_Date,
    COUNT(DISTINCT qsrs.plan_id) AS Execution_Plans,
    SUM(qsrs.count_executions) AS Total_Executions,
    AVG(qsrs.avg_duration / 1000000.0) AS Avg_Duration_Seconds
FROM sys.query_store_query qsq
JOIN sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
JOIN sys.query_store_runtime_stats qsrs ON qsp.plan_id = qsrs.plan_id
WHERE qsq.object_id IS NOT NULL
  AND qsq.object_id > 0
GROUP BY OBJECT_NAME(qsq.object_id)
ORDER BY Max_Access_Date ASC;
```

## Extended Events Setup

To capture comprehensive access logs:

```sql
-- Create Extended Events session for access tracking
CREATE EVENT SESSION [ObjectAccessTracking] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.client_app_name, sqlserver.username, sqlserver.database_name)
    WHERE ([object_type]=(8272) OR [object_type]=(20549) OR [object_type]=(21075))
),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_app_name, sqlserver.username, sqlserver.database_name)
)
ADD TARGET package0.event_file(SET filename=N'ObjectAccessTracking.xel', max_file_size=(100))
WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, 
      MAX_DISPATCH_LATENCY=30 SECONDS, STARTUP_STATE=ON);

-- Start the session
ALTER EVENT SESSION [ObjectAccessTracking] ON SERVER STATE = START;
```


