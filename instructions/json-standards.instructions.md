---
name: "JSON / JSONC Standards"
description: "JSON formatting and schema conventions: 2-space indent, double quotes, deterministic key ordering, schema URIs, and JSONC comment rules."
applyTo: "**/*.{json,jsonc}"
version: "9.0"
updated: "01-July-2026"
---

# JSON / JSONC Standards

## Formatting

- 2-space indentation. No tabs.
- Double quotes only. Never single quotes (invalid JSON).
- One key-value pair per line in objects with more than two keys.
- No trailing commas in strict `.json`. JSONC may use them only when the consumer documents support.
- Terminal newline at EOF.

## Schemas

- Hand-edited config files (e.g., `hooks.json`, VS Code settings, `mcp.json`) SHOULD declare a `$schema` when one exists.
- Generated artifacts (manifests, logs) MUST validate against a schema in `schemas/` or `references/`.
- Use stable, ordered keys; avoid object-property reordering on save (configure your formatter).

## Comments

- `.json`: no comments allowed. Use a sibling `.md` file for documentation.
- `.jsonc`: line (`//`) and block (`/* */`) comments allowed. Prefer line comments above the key they describe.

## Values

- Numbers without leading zeros (`0.5` not `.5`, never `01`).
- Booleans and `null` lowercase.
- Dates as ISO-8601 strings (`"2026-07-01T12:00:00Z"`); do not invent custom formats.
- File paths use forward slashes (`/`) even on Windows for cross-platform compatibility.

## JSONL (structured logs)

- One complete JSON object per line, compact (no internal whitespace), no trailing newline inside the object.
- Required base fields for hook logs: `timestamp`, `hook`, `event`, `decision`, plus hook-specific context.
- Never embed multi-line strings; escape `\n` or move to a side file.

## Security

- Never commit secrets, tokens, or API keys in JSON. Use env-var references (`"${VAR_NAME}"`) and document required vars in the adjacent README.
