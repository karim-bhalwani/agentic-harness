# Severity Calibration: Grading Findings Correctly

> Annotated examples showing the correct severity for real findings. Each example includes a finding that is commonly mis-graded, the wrong severity, the correct severity, and the reasoning.
>
> Use these to calibrate: consistent severity grading is what makes Guardian reviews actionable. Over-grading erodes trust; under-grading lets real issues slip.

---

## Severity Reference

| Severity     | Meaning                                    | Blocks Merge? |
| ------------ | ------------------------------------------ | ------------- |
| **Critical** | Security vulnerability or data loss risk   | Yes           |
| **High**     | Correctness issue or major quality gap     | Yes           |
| **Medium**   | Should fix before next release             | No            |
| **Low**      | Improve when convenient                    | No            |
| **Nit**      | Style or preference                        | No            |

**Decision rule**: A finding blocks merge (Critical/High) only if shipping it would cause harm to users, data, or system integrity. Everything else is advisory.

---

## Commonly Over-Graded (Should Be Lower)

### SC-01: Missing Type Hint on Internal Function

```python
def _calculate_discount(price, quantity):
    return price * quantity * 0.1
```

| | Grade | Reason |
|---|---|---|
| **Wrong** | High | "Missing type hints on function signature" |
| **Correct** | Low | Private function (`_` prefix), simple logic, no public API surface. Type hints improve readability but this isn't a correctness or security issue. |

**Rule**: Missing type hints are **Low** on private functions, **Medium** on public APIs, and never Critical/High.

---

### SC-02: Commented-Out Code Block

```python
def process_order(order: Order):
    # validate_inventory(order)  # TODO: re-enable after inventory service migration
    charge_payment(order)
    send_confirmation(order)
```

| | Grade | Reason |
|---|---|---|
| **Wrong** | High | "Dead code / commented-out block" |
| **Correct** | Medium | The comment explains why it's disabled (active migration). This should be tracked and re-enabled, but it's not a merge blocker. It would be **High** only if the commented-out code was a security check (like auth validation) with no replacement. |

**Rule**: Commented-out code is **Medium** by default. Escalate to **High** only if the disabled code is a security or data integrity check.

---

### SC-03: No Integration Test for New Endpoint

```python
@app.post("/api/reports/generate")
async def generate_report(params: ReportParams):
    data = await fetch_data(params)
    return build_report(data)
```

| | Grade | Reason |
|---|---|---|
| **Wrong** | Critical | "No integration test for new endpoint" |
| **Correct** | Medium | Missing tests are a quality gap, not a security vulnerability or data loss risk. Unit tests for `fetch_data` and `build_report` may exist. Recommend adding integration test, but don't block the merge. |

**Rule**: Missing tests are **Medium** for regular endpoints. Escalate to **High** only for security-critical paths (auth, payment, data deletion) where the enforcement behavior itself needs verification.

---

### SC-04: Inconsistent Logging Pattern

```python
# Module A uses structured logging
logger.info("order_created", extra={"order_id": order.id, "total": total})

# Module B uses f-string logging
logger.info(f"Order {order.id} created with total {total}")
```

| | Grade | Reason |
|---|---|---|
| **Wrong** | High | "Inconsistent logging pattern" |
| **Correct** | Low | Both approaches work. Structured logging is better for observability, but the inconsistency doesn't cause bugs or security issues. Recommend consolidation in a follow-up PR. |

**Rule**: Style inconsistencies are **Low**. Pattern rot (many inconsistencies compounding) can be escalated to **Medium** with a consolidation recommendation.

---

## Commonly Under-Graded (Should Be Higher)

### SC-05: Missing Rate Limiting on Auth Endpoint

```python
@app.post("/api/auth/login")
async def login(credentials: LoginRequest):
    user = authenticate(credentials.email, credentials.password)
    if not user:
        raise HTTPException(401, "Invalid credentials")
    return create_token(user)
```

| | Grade | Reason |
|---|---|---|
| **Wrong** | Medium | "Consider adding rate limiting" |
| **Correct** | High | Authentication endpoints without rate limiting enable brute-force attacks. This is a concrete security gap (A04: Insecure Design), not a nice-to-have. |

**Rule**: Missing security controls on auth endpoints are **High**, not Medium. Rate limiting, lockout, and logging are required, not recommended.

---

### SC-06: Error Message Leaking Internal Details

```python
except DatabaseError as e:
    raise HTTPException(500, detail=str(e))  # Exposes DB schema, query, table names
```

| | Grade | Reason |
|---|---|---|
| **Wrong** | Low | "Consider using a generic error message" |
| **Correct** | High | `str(e)` on a DatabaseError exposes table names, column names, query structure, and potentially connection strings. This is information disclosure (A09) that aids further attacks. |

**Rule**: Error messages that leak internal structure to external users are **High**. Internal-only error messages (logged, not returned) are fine.

---

### SC-07: Pickle Deserialization of User-Uploaded File

```python
@app.post("/api/upload/model")
async def upload_model(file: UploadFile):
    model = pickle.loads(await file.read())  # RCE!
    return {"accuracy": model.score(test_data)}
```

| | Grade | Reason |
|---|---|---|
| **Wrong** | Medium | "Consider using a safer serialization format" |
| **Correct** | Critical | `pickle.loads` on untrusted input is Remote Code Execution. An attacker uploads a crafted pickle that executes arbitrary code on the server. This is not a suggestion, it's a showstopper (A08: Data Integrity Failures). |

**Rule**: Deserialization of untrusted input (`pickle`, `eval`, `exec`, `yaml.load` without SafeLoader) is always **Critical**.

---

### SC-08: Unvalidated Redirect URL

```python
@app.get("/redirect")
async def redirect(url: str):
    return RedirectResponse(url)  # Open redirect
```

| | Grade | Reason |
|---|---|---|
| **Wrong** | Low | "Consider validating the redirect URL" |
| **Correct** | High | Open redirects enable phishing attacks. Attacker crafts `https://yourapp.com/redirect?url=https://evil.com/login` which looks legitimate. Validate against an allowlist of permitted domains. |

**Rule**: Open redirects are **High**. They may seem low-impact alone, but they're a standard phishing vector and often appear in bug bounty scopes.

---

## Edge Cases: Severity Depends on Context

### SC-09: Missing Input Validation

```python
# Context A: Internal admin tool, behind VPN and auth
@admin_router.post("/config/update")
async def update_config(key: str, value: str):
    config_store.set(key, value)

# Context B: Public API endpoint
@app.post("/api/profile/update")
async def update_profile(bio: str):
    current_user.bio = bio  # No length limit, no sanitization
    db.commit()
```

| Context | Grade | Reason |
|---|---|---|
| Context A | **Medium** | Internal tool behind auth and VPN. Input validation is good practice but the attack surface is limited. |
| Context B | **High** | Public endpoint. Unbounded `bio` field enables stored XSS (if rendered) and DB storage abuse (no length limit). |

**Rule**: Same pattern, different severity based on exposure. Public-facing = higher severity. Internal-only with auth = lower severity. Always state the context in the finding.

---

### SC-10: Dependency with Known CVE

| CVE Severity | CVSS Score | Our Grade | Reason |
|---|---|---|---|
| Critical (RCE) | 9.0+ | **Critical** | Remote code execution, must update immediately. |
| High (data leak) | 7.0-8.9 | **High** | Data exposure risk, blocks merge for new code. |
| Medium (DoS) | 4.0-6.9 | **Medium** | Denial of service, fix before next release. |
| Low (info disclosure) | < 4.0 | **Low** | Minor info leak, fix when convenient. |

**Rule**: Mirror the CVE severity. Don't uniformly flag all CVEs as Critical; that teaches developers to ignore dependency alerts.

---

## Calibration Principles

1. **Severity tracks impact, not effort.** A one-line fix can be Critical (hardcoded secret). A 200-line refactor can be Low (naming consistency).

2. **Context determines severity, not pattern alone.** SQL in a migration is fine; SQL with user input is Critical. Same syntax, different risk.

3. **The "shipped tomorrow" test.** If this code ships tomorrow exactly as-is, what's the worst realistic outcome?
   - Data breach, RCE, data loss → **Critical**
   - Incorrect behavior, security gap → **High**
   - Degraded quality, future risk → **Medium**
   - Suboptimal but functional → **Low**
   - Prefer X over Y → **Nit**

4. **Don't hedge with Medium.** Medium is the most overused severity. If you're unsure between High and Medium, apply the "shipped tomorrow" test. If you're unsure between Medium and Low, it's probably Low.

5. **One Critical finding dominates.** If a review has one Critical and ten Lows, the gate status is FAIL. Don't let volume of Low findings mask the Critical one, and don't let a mass of Lows create a "FAIL" impression when no individual finding warrants it.


