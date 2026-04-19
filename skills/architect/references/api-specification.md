# Example: REST API Specification (spec.md)

**Architecture Pattern**: RESTful API with domain-driven design

---

## Feature: User Authentication & Authorization

### Overview

Secure authentication system using JWT tokens with role-based access control (RBAC).

### Identified Primitives

- `User`: Entity with identity, credentials, roles
- `Token`: JWT bearer token with expiration
- `Role`: Permission container (admin, user, guest)
- `Session`: Active authenticated connection

---

## File Structure

```text
src/
├── auth/
│   ├── models.py          # User, Role, Token entities
│   ├── service.py         # Authentication business logic
│   ├── routes.py          # FastAPI endpoints
│   └── security.py        # JWT, hashing, validation
├── middleware/
│   └── auth_middleware.py # Token extraction & validation
└── tests/
    └── test_auth.py       # Integration tests
```

---

## Data Models

### User Entity

```python
from datetime import datetime
from enum import Enum
from typing import List
from pydantic import BaseModel, EmailStr

class RoleEnum(str, Enum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

class User(BaseModel):
    """User domain model"""
    id: str  # UUID
    email: EmailStr  # Unique
    username: str    # Unique, alphanumeric
    password_hash: str
    roles: List[RoleEnum] = [RoleEnum.USER]
    is_active: bool = True
    created_at: datetime
    updated_at: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "user@example.com",
                "username": "john_doe",
                "password_hash": "$2b$12$...",
                "roles": ["user"],
                "is_active": True,
                "created_at": "2026-01-24T10:00:00Z",
                "updated_at": "2026-01-24T10:00:00Z"
            }
        }

class Token(BaseModel):
    """JWT token response"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds

    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "expires_in": 3600
            }
        }
```

---

## API Contracts

### POST /auth/register

**Purpose**: Create new user account

**Request**:

```http
POST /auth/register HTTP/1.1
Content-Type: application/json

{
  "email": "newuser@example.com",
  "username": "newuser",
  "password": "SecurePass123!"
}
```

**Success Response (201)**:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "newuser@example.com",
  "username": "newuser",
  "roles": ["user"],
  "is_active": true,
  "created_at": "2026-01-24T10:00:00Z"
}
```

**Error Response (400 - Validation)**:

```json
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "Email already exists",
  "instance": "/auth/register",
  "errors": [
    {
      "field": "email",
      "message": "Email must be unique"
    }
  ]
}
```

**Error Response (409 - Conflict)**:

```json
{
  "type": "https://api.example.com/errors/conflict",
  "title": "Conflict",
  "status": 409,
  "detail": "Username already taken",
  "instance": "/auth/register"
}
```

### POST /auth/login

**Purpose**: Authenticate and get JWT token

**Request**:

```http
POST /auth/login HTTP/1.1
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Success Response (200)**:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

**Error Response (401 - Unauthorized)**:

```json
{
  "type": "https://api.example.com/errors/authentication-error",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Invalid email or password",
  "instance": "/auth/login"
}
```

### GET /auth/me

**Purpose**: Get current authenticated user

**Request**:

```http
GET /auth/me HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200)**:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "username": "john_doe",
  "roles": ["user"],
  "is_active": true,
  "created_at": "2026-01-24T10:00:00Z",
  "updated_at": "2026-01-24T10:00:00Z"
}
```

**Error Response (401 - Unauthorized)**:

```json
{
  "type": "https://api.example.com/errors/authentication-error",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Invalid or expired token",
  "instance": "/auth/me"
}
```

---

## Architecture Diagrams

### Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API as FastAPI Server
    participant Auth as Auth Service
    participant DB as Database
    participant JWT as JWT Handler

    Client->>API: POST /auth/login (email, password)
    API->>Auth: authenticate(email, password)
    Auth->>DB: find_user(email)
    DB-->>Auth: User object
    Auth->>Auth: verify_password(password, hash)
    alt Valid Credentials
        Auth->>JWT: generate_token(user_id, roles)
        JWT-->>Auth: access_token
        Auth-->>API: success
        API-->>Client: 200 Token Response
    else Invalid Credentials
        Auth-->>API: AuthenticationError
        API-->>Client: 401 Unauthorized
    end
```

### Module Dependencies

```text
┌─────────────────────┐
│   FastAPI Routes    │
│  (routes.py)        │
└──────────┬──────────┘
           │ depends on
┌──────────▼──────────┐
│  Auth Service       │
│  (service.py)       │
└──────────┬──────────┘
           │ depends on
┌──────────┼──────────┐
│  Security │ Database│
│  (JWT)    │ (ORM)   │
└───────────┴─────────┘
```

---

## Dependency Map

| Component  | Depends On  | Reason               | Risk                       |
| ---------- | ----------- | -------------------- | -------------------------- |
| routes.py  | service.py  | Delegates auth logic | Low - clear interface      |
| service.py | security.py | Token generation     | Medium - crypto dependency |
| service.py | database    | User persistence     | Low - standard ORM         |
| middleware | security.py | Token validation     | Medium - on every request  |

---

## Replaceability Assessment

✅ **routes.py**: Replaceable - interface: `AuthService`  
✅ **service.py**: Replaceable - interface: Auth operations, Token generation  
✅ **security.py**: Replaceable - interface: JWT encode/decode, password hash/verify  
✅ **middleware**: Replaceable - interface: Token validation function

---

## Security Considerations

- Passwords hashed with bcrypt (min cost 12)
- JWT tokens signed with RS256 (asymmetric)
- Token expiration: 1 hour (short-lived)
- Refresh token mechanism (separate endpoint)
- No passwords in logs or error messages
- HTTPS enforced in production
- CORS properly configured

---

## Testing Strategy

```python
# tests/test_auth.py

def test_user_registration_success():
    """Happy path: New user registers successfully"""
    response = client.post("/auth/register", json={
        "email": "new@example.com",
        "username": "newuser",
        "password": "SecurePass123!"
    })
    assert response.status_code == 201
    assert response.json()["email"] == "new@example.com"

def test_user_registration_duplicate_email():
    """Edge case: Email already exists"""
    # Setup: Create user first
    create_user("existing@example.com")
    # Test: Try to register with same email
    response = client.post("/auth/register", json={
        "email": "existing@example.com",
        "username": "different",
        "password": "Pass123!"
    })
    assert response.status_code == 409
    assert "already exists" in response.json()["detail"]

def test_login_success():
    """Happy path: Valid credentials return token"""
    response = client.post("/auth/login", json={
        "email": "user@example.com",
        "password": "SecurePass123!"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_login_invalid_password():
    """Edge case: Wrong password rejected"""
    response = client.post("/auth/login", json={
        "email": "user@example.com",
        "password": "WrongPassword"
    })
    assert response.status_code == 401
```

---

**Next Step**: Hand off to `implementer` skill for build & testing


