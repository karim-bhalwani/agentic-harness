"""
Authentication Service Implementation

Following: Architect spec.md, Clean Architecture, TDD principles
Language: Python 3.11+
Type Safety: Full Pydantic + type hints
Testing: pytest with 85%+ coverage
"""

from datetime import datetime, timedelta, timezone
from typing import Optional
from enum import Enum
import jwt  # ty:ignore[unresolved-import]
import bcrypt  # type: ignore[import-not-found]
from fastapi import FastAPI, HTTPException, Depends, status  # ty:ignore[unresolved-import]
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials  # ty:ignore[unresolved-import]
from pydantic import BaseModel, EmailStr, Field, validator  # ty:ignore[unresolved-import]

# ============================================================================
# DOMAIN MODELS
# ============================================================================


class RoleEnum(str, Enum):
    """User roles for RBAC"""

    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"


class User(BaseModel):
    """Domain model: User entity"""

    id: str
    email: EmailStr
    username: str
    password_hash: str
    roles: list[RoleEnum] = [RoleEnum.USER]
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
                "updated_at": "2026-01-24T10:00:00Z",
            }
        }


class UserResponse(BaseModel):
    """API response: User (without password)"""

    id: str
    email: EmailStr
    username: str
    roles: list[RoleEnum]
    is_active: bool
    created_at: datetime
    updated_at: datetime


class TokenResponse(BaseModel):
    """API response: Authentication token"""

    access_token: str
    token_type: str = "bearer"
    expires_in: int


# ============================================================================
# REQUEST/RESPONSE DTOs
# ============================================================================


class RegisterRequest(BaseModel):
    """Request DTO: User registration"""

    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50, pattern="^[a-zA-Z0-9_-]+$")
    password: str = Field(..., min_length=8)

    @validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        """Ensure password meets strength requirements"""
        has_upper = any(c.isupper() for c in v)
        has_lower = any(c.islower() for c in v)
        has_digit = any(c.isdigit() for c in v)
        has_special = any(c in "!@#$%^&*" for c in v)

        if not (has_upper and has_lower and has_digit and has_special):
            raise ValueError("Password must contain uppercase, lowercase, digit, and special character")
        return v


class LoginRequest(BaseModel):
    """Request DTO: User login"""

    email: EmailStr
    password: str


# ============================================================================
# CUSTOM EXCEPTIONS
# ============================================================================


class AuthenticationError(Exception):
    """Base authentication error"""


class InvalidCredentialsError(AuthenticationError):
    """Wrong email or password"""


class UserNotFoundError(AuthenticationError):
    """User does not exist"""


class UserAlreadyExistsError(AuthenticationError):
    """User already registered"""


class InvalidTokenError(AuthenticationError):
    """Token is invalid or expired"""


# ============================================================================
# SECURITY LAYER
# ============================================================================


class PasswordHasher:
    """Password hashing and verification using bcrypt"""

    COST = 12  # bcrypt cost factor (higher = slower but more secure)

    @staticmethod
    def hash_password(password: str) -> str:
        """Hash password with bcrypt"""
        salt = bcrypt.gensalt(rounds=PasswordHasher.COST)
        return bcrypt.hashpw(password.encode(), salt).decode()

    @staticmethod
    def verify_password(password: str, hashed: str) -> bool:
        """Verify password against hash"""
        return bcrypt.checkpw(password.encode(), hashed.encode())


class JWTHandler:
    """JWT token generation and validation"""

    def __init__(self, secret_key: str, algorithm: str = "HS256", expiry_minutes: int = 60):
        self.secret_key = secret_key
        self.algorithm = algorithm
        self.expiry_minutes = expiry_minutes

    def generate_token(self, user_id: str, roles: list[RoleEnum]) -> str:
        """Generate JWT token"""
        payload = {
            "sub": user_id,
            "roles": [role.value for role in roles],
            "iat": datetime.now(timezone.utc),
            "exp": datetime.now(timezone.utc) + timedelta(minutes=self.expiry_minutes),
        }
        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)

    def validate_token(self, token: str) -> dict:
        """Validate and decode JWT token"""
        try:
            return jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
        except jwt.ExpiredSignatureError as exc:
            raise InvalidTokenError("Token has expired") from exc
        except jwt.InvalidTokenError as exc:
            raise InvalidTokenError("Invalid token") from exc


# ============================================================================
# PERSISTENCE LAYER (Mock for example)
# ============================================================================


class UserRepository:
    """Mock user repository (replace with real DB)"""

    def __init__(self):
        self._users: dict[str, User] = {}

    def find_by_email(self, email: str) -> Optional[User]:
        """Find user by email"""
        for user in self._users.values():
            if user.email.lower() == email.lower():
                return user
        return None

    def find_by_id(self, user_id: str) -> Optional[User]:
        """Find user by ID"""
        return self._users.get(user_id)

    def create(self, user: User) -> User:
        """Create new user"""
        if self.find_by_email(user.email):
            raise UserAlreadyExistsError(f"Email {user.email} already exists")
        self._users[user.id] = user
        return user


# ============================================================================
# BUSINESS LOGIC LAYER
# ============================================================================


class AuthenticationService:
    """Authentication business logic"""

    def __init__(self, repository: UserRepository, jwt_handler: JWTHandler):
        self.repository = repository
        self.jwt_handler = jwt_handler
        self.password_hasher = PasswordHasher()

    def register(self, request: RegisterRequest) -> UserResponse:
        """Register new user"""
        # Validate email not already in use
        if self.repository.find_by_email(request.email):
            raise UserAlreadyExistsError(f"Email {request.email} already registered")

        # Create user with hashed password
        user = User(
            id=self._generate_user_id(),
            email=request.email,
            username=request.username,
            password_hash=self.password_hasher.hash_password(request.password),
            roles=[RoleEnum.USER],
            is_active=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )

        # Persist
        created_user = self.repository.create(user)
        return UserResponse(**created_user.dict())

    def login(self, request: LoginRequest) -> TokenResponse:
        """Authenticate user and return token"""
        # Find user
        user = self.repository.find_by_email(request.email)
        if not user:
            raise InvalidCredentialsError("Invalid email or password")

        # Verify password
        if not self.password_hasher.verify_password(request.password, user.password_hash):
            raise InvalidCredentialsError("Invalid email or password")

        # Check if active
        if not user.is_active:
            raise InvalidCredentialsError("User account is inactive")

        # Generate token
        token = self.jwt_handler.generate_token(user.id, user.roles)
        return TokenResponse(
            access_token=token,
            token_type="bearer",
            expires_in=self.jwt_handler.expiry_minutes * 60,
        )

    def get_current_user(self, token: str) -> UserResponse:
        """Get authenticated user from token"""
        payload = self.jwt_handler.validate_token(token)
        user_id = payload.get("sub")

        if not user_id:
            raise UserNotFoundError("No user ID in token")
        user = self.repository.find_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"User {user_id} not found")

        return UserResponse(**user.dict())

    @staticmethod
    def _generate_user_id() -> str:
        """Generate unique user ID (UUID in production)"""
        import uuid

        return str(uuid.uuid4())


# ============================================================================
# PRESENTATION LAYER (FastAPI)
# ============================================================================

app = FastAPI(title="Auth API", version="1.0.0")

# Initialize dependencies
_user_repository = UserRepository()
_jwt_handler = JWTHandler(secret_key="your-secret-key-here")
auth_service = AuthenticationService(_user_repository, _jwt_handler)
security = HTTPBearer()


@app.post("/auth/register", response_model=UserResponse, status_code=201)
async def register(request: RegisterRequest) -> UserResponse:
    """Register new user account"""
    try:
        return auth_service.register(request)
    except UserAlreadyExistsError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e)) from e


@app.post("/auth/login", response_model=TokenResponse)
async def login(request: LoginRequest) -> TokenResponse:
    """Authenticate and get JWT token"""
    try:
        return auth_service.login(request)
    except InvalidCredentialsError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e)) from e


@app.get("/auth/me", response_model=UserResponse)
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> UserResponse:
    """Get current authenticated user"""
    try:
        return auth_service.get_current_user(credentials.credentials)
    except InvalidTokenError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e)) from e


# ============================================================================
# TESTING
# ============================================================================

if __name__ == "__main__":
    import pytest

    pytest.main([__file__, "-v", "--cov=."])
