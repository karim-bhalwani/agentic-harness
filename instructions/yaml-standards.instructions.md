---
name: "YAML Coding Standards"
description: "YAML formatting conventions: 2-space indentation, no tabs, and anchors/aliases for deduplication in config files."
applyTo: "**/*.{yaml,yml}"
version: "9.0"
updated: "01-July-2026"
---

# YAML Coding Standards

---

## YAML Style

- 2-space indentation. No tabs.
  - If a YAML file contains mixed indentation styles (tabs and spaces), reject the file and provide an error message specifying the issue.
- Use YAML anchors (`&anchor`) and aliases (`*anchor`) to reduce duplication in repeated config blocks.
- Start standalone YAML files with a `---` document marker.
  - If a standalone YAML file does not start with a `---` document marker, reject the file and provide an error message specifying the issue.

---

## Type Safety

- **Quote ambiguous scalars**: strings that look like other YAML types must be quoted or they will be silently misinterpreted.
  - Booleans: `"true"`, `"false"`, `"yes"`, `"no"`, `"on"`, `"off"`
  - Null: `"null"`, `"~"`
  - Version numbers and numeric strings: `"1.0"`, `"08"` (leading zero = octal in some parsers)
- Use `null` for explicit null values. The use of `~` is not allowed to ensure consistency and parser compatibility.

---

## Multi-line Strings

- Use `|` (literal block scalar) to preserve newlines - for scripts, SQL, or structured text.
- Use `>` (folded block scalar) to collapse newlines into spaces - for long prose descriptions.
