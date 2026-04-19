# Pipeline Orchestration Reference

> Deep-dive reference. Loaded on demand for Airflow DAG design, error handling, and retry pattern tasks.

## Airflow Best Practices

- Idempotent tasks: re-runnable without side effects
- `execution_date` for time partitioned processing
- XCom for small metadata only; use external storage for data
- Sensor timeouts: always set `poke_interval` and `timeout`
- Task granularity: one logical unit per task

### Idempotent Task Pattern

```python
from airflow.decorators import task

@task
def load_silver_orders(execution_date: str) -> dict:
    """Idempotent: overwrites the target partition for the given date."""
    partition = execution_date[:10]  # YYYY-MM-DD
    df = spark.read.table("bronze.orders").filter(f"_ingested_date = '{partition}'")
    (
        df.write
        .format("delta")
        .mode("overwrite")
        .option("replaceWhere", f"order_date = '{partition}'")
        .saveAsTable("silver.orders")
    )
    return {"partition": partition, "row_count": df.count()}
```

### Sensor Configuration

```python
from airflow.sensors.external_task import ExternalTaskSensor

wait_for_upstream = ExternalTaskSensor(
    task_id="wait_for_bronze_load",
    external_dag_id="bronze_ingestion",
    external_task_id="load_complete",
    poke_interval=300,      # check every 5 minutes
    timeout=3600,           # fail after 1 hour
    mode="reschedule",      # free up worker slot between pokes
)
```

## Error Handling

- Retry with exponential backoff for transient failures
- Dead-letter queues for poison messages
- Circuit breakers for external API calls
- Alerting: PagerDuty/Slack on task failure, not just DAG failure

### Retry Configuration

```python
default_args = {
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
    "max_retry_delay": timedelta(minutes=60),
}
```

### Circuit Breaker Pattern

```python
from tenacity import retry, stop_after_attempt, wait_exponential, CircuitBreaker

breaker = CircuitBreaker(fail_max=5, reset_timeout=300)

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=60),
)
@breaker
def call_external_api(endpoint: str) -> dict:
    response = requests.get(endpoint, timeout=30)
    response.raise_for_status()
    return response.json()
```

## DAG Design Patterns

### Fan-Out / Fan-In

```text
extract_sources
├── transform_orders
├── transform_customers
├── transform_products
└── join_all  (depends on all three)
```

### Conditional Branching

```python
from airflow.operators.python import BranchPythonOperator

def choose_path(**context):
    row_count = context["ti"].xcom_pull(task_ids="count_rows")
    return "full_refresh" if row_count == 0 else "incremental_load"

branch = BranchPythonOperator(
    task_id="choose_load_strategy",
    python_callable=choose_path,
)
```

## Task Dependencies Anti-Patterns

- Avoid chains longer than 10 tasks (use task groups)
- Never use `trigger_rule="all_done"` without understanding failure propagation
- Don't use `depends_on_past=True` on the first task (blocks entire DAG on failure)
