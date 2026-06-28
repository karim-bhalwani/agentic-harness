"""
validate_schema.py
==================
Validate a PySpark DataFrame schema against an expected contract.

Usage (agent context):
    from skills.data_engineering.scripts.validate_schema import validate_schema
    errors = validate_schema(df, expected_schema)

Usage (CLI):
    python validate_schema.py --actual path/to/parquet --expected schema.json

Returns a list of SchemaError objects. An empty list means the schema is valid.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any


class ErrorKind(str, Enum):
    MISSING_COLUMN = "MISSING_COLUMN"
    EXTRA_COLUMN = "EXTRA_COLUMN"
    TYPE_MISMATCH = "TYPE_MISMATCH"
    NULLABLE_VIOLATION = "NULLABLE_VIOLATION"


@dataclass
class SchemaError:
    kind: ErrorKind
    column: str
    expected: str = ""
    actual: str = ""
    message: str = ""

    def __str__(self) -> str:
        base = f"[{self.kind.value}] column='{self.column}'"
        if self.expected and self.actual:
            base += f" expected={self.expected!r} actual={self.actual!r}"
        if self.message:
            base += f" — {self.message}"
        return base

    def as_remediation(self) -> str:
        """Return a machine-readable remediation instruction (agent-legible error)."""
        if self.kind == ErrorKind.MISSING_COLUMN:
            return (
                f"Add column '{self.column}' with type {self.expected!r} to the "
                "DataFrame before writing. Check upstream transformer or source query."
            )
        if self.kind == ErrorKind.EXTRA_COLUMN:
            return (
                f"Column '{self.column}' is not in the contract. Drop it with "
                f"`df.drop('{self.column}')` or add it to the schema contract if intentional."
            )
        if self.kind == ErrorKind.TYPE_MISMATCH:
            return (
                f"Cast column '{self.column}' from {self.actual!r} to {self.expected!r}. "
                f"Example: df.withColumn('{self.column}', F.col('{self.column}').cast('{self.expected}'))"
            )
        if self.kind == ErrorKind.NULLABLE_VIOLATION:
            return (
                f"Column '{self.column}' is declared NOT NULL but contains nulls. "
                "Add a `df.filter(F.col(...).isNotNull())` guard or fix the upstream source."
            )
        return self.message


def validate_schema(
    actual_fields: list[dict[str, Any]],
    expected_fields: list[dict[str, Any]],
    strict: bool = True,
) -> list[SchemaError]:
    """
    Compare actual vs expected schema fields.

    Parameters
    ----------
    actual_fields:
        List of dicts with keys 'name', 'dataType' (str), 'nullable' (bool).
        Matches PySpark StructField.jsonValue() output.
    expected_fields:
        Same format. Treat this as the contract.
    strict:
        When True, flag extra columns in actual that are not in expected.

    Returns
    -------
    List of SchemaError. Empty = schema is valid.
    """
    errors: list[SchemaError] = []
    actual_map: dict[str, dict[str, Any]] = {f["name"]: f for f in actual_fields}
    expected_map: dict[str, dict[str, Any]] = {f["name"]: f for f in expected_fields}

    # Missing columns
    for col_name, exp in expected_map.items():
        if col_name not in actual_map:
            errors.append(
                SchemaError(
                    kind=ErrorKind.MISSING_COLUMN,
                    column=col_name,
                    expected=exp.get("dataType", ""),
                )
            )
            continue

        act = actual_map[col_name]

        # Type mismatch
        if str(act.get("dataType", "")).lower() != str(exp.get("dataType", "")).lower():
            errors.append(
                SchemaError(
                    kind=ErrorKind.TYPE_MISMATCH,
                    column=col_name,
                    expected=str(exp.get("dataType", "")),
                    actual=str(act.get("dataType", "")),
                )
            )

        # Nullable violation (expected NOT NULL but actual is nullable)
        if not exp.get("nullable", True) and act.get("nullable", True):
            errors.append(
                SchemaError(
                    kind=ErrorKind.NULLABLE_VIOLATION,
                    column=col_name,
                    message=f"Contract requires nullable=False, actual={act.get('nullable')}",
                )
            )

    # Extra columns
    if strict:
        for col_name in actual_map:
            if col_name not in expected_map:
                errors.append(
                    SchemaError(
                        kind=ErrorKind.EXTRA_COLUMN,
                        column=col_name,
                        actual=str(actual_map[col_name].get("dataType", "")),
                    )
                )

    return errors


def _load_fields(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, list):
        return data
    # Support full PySpark schema JSON: {"type": "struct", "fields": [...]}
    return data.get("fields", data)


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Validate a DataFrame schema contract")
    parser.add_argument("--actual", required=True, type=Path)
    parser.add_argument("--expected", required=True, type=Path)
    parser.add_argument("--no-strict", dest="strict", action="store_false", default=True)
    args = parser.parse_args()

    actual_fields = _load_fields(args.actual)
    expected_fields = _load_fields(args.expected)
    errors = validate_schema(actual_fields, expected_fields, strict=args.strict)

    if not errors:
        print("✅ Schema is valid — all columns match the contract.")
        sys.exit(0)

    print(f"❌ Schema validation failed — {len(errors)} error(s):")
    for i, err in enumerate(errors, 1):
        print(f"  {i}. {err}")
        print(f"     Remediation: {err.as_remediation()}")
    sys.exit(1)


if __name__ == "__main__":
    main()
