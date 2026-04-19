# False Positives: Things Guardian Should NOT Flag

> Annotated examples of patterns that look suspicious but are actually correct. Each example explains why the pattern is valid and what Guardian should do instead of flagging it.
>
> Use these to calibrate judgment: if Guardian flags any of these, the review is noisy. The Suppressions section in review-checklist.md covers categorical suppressions; this file covers judgment calls that require understanding context.

---

## FP-01: Intentional `shell=True` with Hardcoded Command

```python
# OK  -  Guardian should NOT flag this
def get_git_hash() -> str:
    result = subprocess.run(
        "git rev-parse HEAD",
        shell=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()
```

**Why it looks bad**: `shell=True` is a common injection vector.

**Why it's fine**: The command string is hardcoded (no user input). No variable interpolation. This is a safe, common pattern for simple shell commands.

**What Guardian should do**: Skip. Only flag `shell=True` when the command includes user input, environment variables from untrusted sources, or string interpolation.

---

## FP-02: Broad Exception Handler with Logging and Re-raise

```python
# OK  -  Guardian should NOT flag this
def process_payment(order: Order) -> PaymentResult:
    try:
        result = gateway.charge(order.total)
        return result
    except Exception:
        logger.exception("Payment failed for order %s", order.id)
        raise  # re-raises the original exception
```

**Why it looks bad**: Bare `except Exception` appears to swallow errors.

**Why it's fine**: The handler logs the error with full traceback (`logger.exception`) and re-raises. This is the standard pattern for adding observability at boundary points without changing error behavior.

**What Guardian should do**: Skip. Only flag `except Exception` when the exception is silently swallowed (no `raise`, no meaningful recovery).

---

## FP-03: `# type: ignore` with Specific Error Code

```python
# OK  -  Guardian should NOT flag this
from untyped_vendor_lib import Client  # type: ignore[import-untyped]

client = Client(api_key=settings.API_KEY)
```

**Why it looks bad**: `type: ignore` comments suppress type checking.

**Why it's fine**: The comment targets a specific error code (`import-untyped`) for a third-party library that doesn't ship type stubs. The developer can't fix this; the library maintainer must.

**What Guardian should do**: Skip specific `type: ignore[code]` on third-party imports. Flag bare `type: ignore` without error codes (those suppress all errors on the line) or `type: ignore` on first-party code (those usually mask real bugs).

---

## FP-04: Large Function That Is Actually a State Machine

```python
# OK  -  Guardian should NOT flag cognitive complexity here
async def handle_webhook(event: WebhookEvent) -> Response:
    match event.type:
        case "checkout.session.completed":
            order = await activate_order(event.data)
            await send_confirmation(order)
            return Response(200)
        case "invoice.payment_failed":
            subscription = await pause_subscription(event.data)
            await notify_billing_failure(subscription)
            return Response(200)
        case "customer.subscription.deleted":
            await deactivate_subscription(event.data)
            return Response(200)
        # ... 8 more cases
        case _:
            logger.warning("Unhandled event type: %s", event.type)
            return Response(200)
```

**Why it looks bad**: Function exceeds cognitive complexity threshold (many branches).

**Why it's fine**: This is a webhook dispatcher. Each `case` is independent and delegates to a focused handler. Extracting to a dict-dispatch or class hierarchy adds indirection without reducing actual complexity. The function reads linearly.

**What Guardian should do**: Skip if each branch is a thin delegation (1-3 lines) to focused functions. Flag if branches contain inline business logic (10+ lines per case).

---

## FP-05: Test File with Hardcoded Credentials

```python
# OK  -  Guardian should NOT flag this in test files
class TestAuthFlow:
    TEST_USER = "test@example.com"
    TEST_PASSWORD = "correcthorsebatterystaple"
    TEST_API_KEY = "sk_test_fake_key_for_testing_only"

    def test_login_success(self):
        response = client.post("/login", json={
            "email": self.TEST_USER,
            "password": self.TEST_PASSWORD,
        })
        assert response.status_code == 200
```

**Why it looks bad**: Hardcoded credentials in source code.

**Why it's fine**: These are test fixtures, not production secrets. The values are obviously fake (`test@example.com`, `sk_test_fake_key_for_testing_only`). They exist to exercise auth flows in isolated test environments.

**What Guardian should do**: Skip when in test files (`test_*.py`, `*_test.py`, `conftest.py`) AND the values are obviously non-production (test prefixes, example.com domains, known placeholder patterns). Flag if: (a) the credential looks real (long random strings, production prefixes like `sk_live_`), or (b) it's not in a test file.

---

## FP-06: Direct SQL in Migration Files

```python
# OK  -  Guardian should NOT flag this in migrations
# alembic/versions/001_add_audit_table.py
def upgrade():
    op.execute("""
        CREATE TABLE audit_log (
            id BIGSERIAL PRIMARY KEY,
            event_type VARCHAR(50) NOT NULL,
            payload JSONB,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
        CREATE INDEX idx_audit_created ON audit_log (created_at);
    """)
```

**Why it looks bad**: Raw SQL without parameterization.

**Why it's fine**: Migration files contain DDL statements (schema changes), not DML with user input. There's no injection risk because the SQL is a developer-authored schema definition, not a query that accepts external parameters.

**What Guardian should do**: Skip raw SQL in migration directories (`alembic/`, `migrations/`, `**/migrate/`). Flag raw SQL in application code (routes, services, repositories).

---

## FP-07: `Any` Type in Protocol/Interface Boundaries

```python
# OK  -  Guardian should NOT flag this
from typing import Any, Protocol

class EventHandler(Protocol):
    def handle(self, event_type: str, payload: Any) -> None: ...
```

**Why it looks bad**: `Any` disables type checking for the payload.

**Why it's fine**: Protocol boundaries that accept plugin-style implementations legitimately need `Any` for the payload type. The concrete implementations type-narrow internally. Forcing a specific type here would break the protocol's extensibility.

**What Guardian should do**: Skip `Any` in Protocol definitions and abstract base classes where concrete implementations handle type narrowing. Flag `Any` in concrete function signatures, return types, or variable annotations where a specific type is known.

---

## FP-08: No Tests for Private Helper Functions

```python
# OK  -  Guardian should NOT flag missing tests for these
def _normalize_phone(raw: str) -> str:
    """Strip non-digit characters and prepend country code."""
    digits = re.sub(r"\D", "", raw)
    return f"+1{digits}" if len(digits) == 10 else f"+{digits}"

def _format_currency(cents: int) -> str:
    return f"${cents / 100:.2f}"
```

**Why it looks bad**: No dedicated unit tests for `_normalize_phone` or `_format_currency`.

**Why it's fine**: Private helpers (prefixed with `_`) are implementation details tested indirectly through their public callers. Requiring direct tests for every private function leads to brittle tests coupled to implementation.

**What Guardian should do**: Verify the public functions that call these helpers have tests covering the relevant edge cases. Only flag missing tests for private functions if they contain non-trivial business logic (50+ lines, multiple branches) that is hard to reach through public callers.

---

## FP-09: `sleep()` in Retry Logic (Not Tests)

```python
# OK  -  Guardian should NOT flag this in production retry logic
async def call_with_retry(url: str, max_attempts: int = 3) -> Response:
    for attempt in range(max_attempts):
        try:
            return await httpx.get(url, timeout=10)
        except httpx.TimeoutError:
            if attempt == max_attempts - 1:
                raise
            await asyncio.sleep(2 ** attempt)  # Exponential backoff
```

**Why it looks bad**: `sleep()` is flagged in test code as a flaky pattern.

**Why it's fine**: This is production retry logic with exponential backoff, not a test. The sleep prevents hammering a failing service. The bounded `max_attempts` prevents infinite loops.

**What Guardian should do**: Skip `sleep()` in production retry/backoff patterns with bounded attempts. Flag `sleep()` in test code (use polling with timeout instead) or unbounded retry loops.

---

## Calibration Principle

> **When in doubt, ask: "Does this pattern create a real risk in production, or does it just look like a pattern that usually creates risk?"**
>
> If the answer is "looks like but isn't," suppress the finding. Guardian's credibility depends on signal-to-noise ratio. Every false positive trains developers to ignore the review.


