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
- Use YAML anchors (`&anchor`) and aliases (`*anchor`) to reduce duplication in repeated config blocks. Only use anchors and aliases within the same YAML document. Do not use alias chains deeper than one level (i.e., an alias must not itself resolve to another alias). Prefer explicit duplication over aliases when the repeated block spans fewer than 3 keys.
- Every .yaml/.yml file that is a complete, self-contained document must begin with a `---` document marker. Files that are intentionally embedded as partial fragments (e.g., included via a merge tool) are exempt.
  - If a complete, self-contained YAML file does not start with a `---` document marker, reject the file and provide an error message specifying the issue.

---

## Type Safety

- **Quote ambiguous scalars**: strings that look like other YAML types must be quoted or they will be silently misinterpreted.
  - Booleans: `"true"`, `"false"`, `"yes"`, `"no"`, `"on"`, `"off"`
  - Strings that spell `null` or `~`: use `"null"` or `"~"` (quoted) when the intended value is the string, not a null.
  - Version numbers and numeric strings: `"1.0"`, `"08"` (leading zero = octal in some parsers)
- Use bare `null` (unquoted) for explicit null values; this is a genuine YAML null, not a string. The use of `~` as a null token is not allowed to ensure consistency and parser compatibility. If the intended value is the string `"null"`, quote it.

---

## Multi-line Strings

- Use `|` (literal block scalar) to preserve newlines - for scripts, SQL, or structured text.
- Use `>` (folded block scalar) to collapse newlines into spaces - for long prose descriptions.
