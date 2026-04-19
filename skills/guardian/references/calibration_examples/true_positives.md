# True Positives: Bugs Guardian MUST Catch

> Annotated examples of real issues that should always be flagged. Each example includes the buggy code, why it matters, the correct severity, and the remediation.
>
> Use these to calibrate judgment: if Guardian skips any of these patterns, the review is incomplete.

---

## Phase 1 (Critical)  -  Merge Blockers

### TP-01: SQL Injection via String Interpolation

```python
# BAD  -  Guardian MUST flag this as Critical
def get_user(name: str) -> dict:
    query = f"SELECT * FROM users WHERE name = '{name}'"
    return db.execute(query).fetchone()
```

**Why**: Direct string interpolation in SQL allows injection. Attacker sends `'; DROP TABLE users; --` as `name`.

**Severity**: Critical (A03: Injection)

**Remediation**:

```python
def get_user(name: str) -> dict:
    query = "SELECT * FROM users WHERE name = :name"
    return db.execute(query, {"name": name}).fetchone()
```

---

### TP-02: Missing Authorization Check (IDOR)

```python
# BAD  -  Guardian MUST flag this as Critical
@app.get("/api/documents/{doc_id}")
async def get_document(doc_id: int, db: Session = Depends(get_db)):
    doc = db.query(Document).get(doc_id)
    if not doc:
        raise HTTPException(404)
    return doc  # No ownership check!
```

**Why**: Any authenticated user can access any document by guessing IDs. Classic Insecure Direct Object Reference.

**Severity**: Critical (A01: Broken Access Control)

**Remediation**:

```python
@app.get("/api/documents/{doc_id}")
async def get_document(
    doc_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    doc = db.query(Document).filter_by(id=doc_id, owner_id=current_user.id).first()
    if not doc:
        raise HTTPException(404)
    return doc
```

---

### TP-03: LLM Output Used in Shell Command Without Sanitization

```python
# BAD  -  Guardian MUST flag this as Critical
def run_llm_suggested_command(user_request: str) -> str:
    command = llm.generate(f"Suggest a shell command for: {user_request}")
    result = subprocess.run(command, shell=True, capture_output=True)
    return result.stdout.decode()
```

**Why**: LLM output is untrusted. The model could generate `rm -rf /` or exfiltrate data via curl. Using `shell=True` with unvalidated input is command injection.

**Severity**: Critical (LLM Trust Boundary + A03: Injection)

**Remediation**: Never execute LLM output as shell commands. If command execution is required, use an allowlist of permitted commands and validate arguments against a strict schema.

---

### TP-04: Race Condition in Balance Check

```python
# BAD  -  Guardian MUST flag this as High
def transfer(from_id: int, to_id: int, amount: Decimal):
    sender = db.query(Account).get(from_id)
    if sender.balance >= amount:       # Check
        sender.balance -= amount       # Act
        receiver = db.query(Account).get(to_id)
        receiver.balance += amount
        db.commit()
```

**Why**: Two concurrent transfers can both pass the balance check before either commits, resulting in a negative balance. Classic TOCTOU (time-of-check-to-time-of-use).

**Severity**: High (Race Condition)

**Remediation**: Use `SELECT ... FOR UPDATE` or database-level constraints (`CHECK (balance >= 0)`) to make the operation atomic.

---

### TP-05: Hardcoded Secret in Source

```python
# BAD  -  Guardian MUST flag this as Critical
class PaymentGateway:
    API_KEY = "sk_live_4eC39HqLyjWDarjtT1zdp7dc"  # production key!

    def charge(self, amount: int):
        return stripe.Charge.create(amount=amount, api_key=self.API_KEY)
```

**Why**: Secret committed to version control. Anyone with repo access has the production Stripe key. Credential rotation required.

**Severity**: Critical (A02: Cryptographic Failures)

**Remediation**: Move to environment variable or vault. Use `os.environ["STRIPE_API_KEY"]`.

---

### TP-06: XSS via Unescaped LLM Output

```python
# BAD  -  Guardian MUST flag this as Critical
@app.get("/summary")
async def summary(request: Request):
    text = llm.generate("Summarize the latest news")
    return HTMLResponse(f"<div>{text}</div>")  # LLM output rendered as raw HTML
```

**Why**: LLM output could contain `<script>` tags (via prompt injection or training data). Rendering it as raw HTML enables stored XSS.

**Severity**: Critical (LLM Trust Boundary + A03: Injection)

**Remediation**: Escape output with `html.escape(text)` or use a template engine with auto-escaping.

---

## Phase 1 (High)  -  Correctness Issues

### TP-07: N+1 Query in Loop

```python
# BAD  -  Guardian MUST flag this as High
def get_orders_with_items(user_id: int) -> list[dict]:
    orders = db.query(Order).filter_by(user_id=user_id).all()
    result = []
    for order in orders:
        items = db.query(OrderItem).filter_by(order_id=order.id).all()  # N+1!
        result.append({"order": order, "items": items})
    return result
```

**Why**: If user has 100 orders, this executes 101 queries. Causes latency spikes under load.

**Severity**: High (Performance + SQL Safety)

**Remediation**: Use `joinedload` or `selectinload`:

```python
orders = (
    db.query(Order)
    .options(selectinload(Order.items))
    .filter_by(user_id=user_id)
    .all()
)
```

---

### TP-08: Unvalidated LLM Structured Output Written to DB

```python
# BAD  -  Guardian MUST flag this as High
def save_llm_extraction(doc_text: str):
    result = llm.generate_json(f"Extract entities from: {doc_text}")
    # result could be anything  -  no schema validation
    for entity in result["entities"]:
        db.execute(
            "INSERT INTO entities (name, type) VALUES (:name, :type)",
            {"name": entity["name"], "type": entity["type"]},
        )
    db.commit()
```

**Why**: LLM JSON output is untrusted. Missing keys cause KeyError; unexpected types cause DB constraint violations; oversized arrays cause resource exhaustion.

**Severity**: High (LLM Trust Boundary)

**Remediation**: Validate with Pydantic model before writing:

```python
class Entity(BaseModel):
    name: str = Field(max_length=255)
    type: str = Field(pattern=r"^(person|org|location)$")

class Extraction(BaseModel):
    entities: list[Entity] = Field(max_length=100)

validated = Extraction.model_validate(result)
```


