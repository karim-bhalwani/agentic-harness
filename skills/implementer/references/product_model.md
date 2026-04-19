# Example: Product Model Implementation

## Overview

Implementation of the Product model from the architectural specification, following TDD principles and clean code standards.

## Test-First Approach

### Unit Tests (tests/test_product.py)

```python
import pytest
from decimal import Decimal
from datetime import datetime
from pydantic import ValidationError

from src.models.product import Product, ProductStatus

class TestProduct:
    def test_valid_product_creation(self):
        """Test creating a valid product with all required fields."""
        product_data = {
            "id": "prod_123",
            "name": "Wireless Headphones",
            "price": Decimal("99.99"),
            "category_id": "cat_456",
            "inventory_count": 50,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }

        product = Product(**product_data)

        assert product.id == "prod_123"
        assert product.name == "Wireless Headphones"
        assert product.price == Decimal("99.99")
        assert product.inventory_count == 50

    def test_product_validation_negative_price(self):
        """Test that negative prices are rejected."""
        with pytest.raises(ValidationError):
            Product(
                id="prod_123",
                name="Test Product",
                price=Decimal("-10.00"),
                category_id="cat_456",
                inventory_count=50,
                created_at=datetime.now(),
                updated_at=datetime.now()
            )

    def test_product_validation_missing_required_field(self):
        """Test that missing required fields raise validation errors."""
        with pytest.raises(ValidationError):
            Product(
                name="Test Product",
                price=Decimal("99.99"),
                category_id="cat_456",
                inventory_count=50,
                created_at=datetime.now(),
                updated_at=datetime.now()
                # Missing 'id' field
            )
```

## Implementation (src/models/product.py)

```python
"""Product model with comprehensive validation and business rules."""

from decimal import Decimal
from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field, validator


class ProductStatus(str, Enum):
    """Enumeration of possible product statuses."""
    ACTIVE = "active"
    INACTIVE = "inactive"
    DISCONTINUED = "discontinued"


class Product(BaseModel):
    """Product entity representing items in the e-commerce catalog.

    This model enforces business rules and data integrity for product management.
    """

    id: str = Field(..., description="Unique product identifier")
    name: str = Field(..., min_length=1, max_length=200, description="Product name")
    description: Optional[str] = Field(None, max_length=1000, description="Product description")
    price: Decimal = Field(..., gt=0, description="Product price in USD")
    category_id: str = Field(..., description="Reference to product category")
    inventory_count: int = Field(..., ge=0, description="Current inventory count")
    status: ProductStatus = Field(default=ProductStatus.ACTIVE, description="Product status")
    created_at: datetime = Field(..., description="Record creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")

    @validator("updated_at")
    def updated_at_must_be_after_created_at(cls, v, values):
        """Ensure updated_at is not before created_at."""
        if "created_at" in values and v < values["created_at"]:
            raise ValueError("updated_at must not be before created_at")
        return v

    @validator("name")
    def name_must_not_be_empty_after_strip(cls, v):
        """Ensure name is not empty after stripping whitespace."""
        if not v.strip():
            raise ValueError("name cannot be empty or whitespace only")
        return v.strip()

    class Config:
        """Pydantic configuration."""
        json_encoders = {
            Decimal: lambda v: float(v),
            datetime: lambda v: v.isoformat()
        }
```

## Code Quality Validation

### Type Checking

```bash
mypy src/models/product.py --strict
# Expected: No errors
```

### Linting

```bash
flake8 src/models/product.py --max-line-length=88
# Expected: No violations
```

### Test Coverage

```bash
pytest tests/test_product.py --cov=src.models.product --cov-report=term-missing
# Expected: 100% coverage
```

## Integration Points

This Product model integrates with:

- **Category Service**: Validates category_id exists
- **Inventory Service**: Updates inventory_count
- **Pricing Service**: Applies discounts and promotions


