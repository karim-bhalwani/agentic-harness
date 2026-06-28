---
name: "TypeScript / JavaScript Coding Standards"
description: "TypeScript-first conventions: strict mode, explicit types at boundaries, ES modules, async/await, and Node 20+ targets."
applyTo: "**/*.{ts,tsx,js,jsx,mjs,cjs}"
version: "9.0"
updated: "01-July-2026"
---

# TypeScript / JavaScript Coding Standards

## Language & Tooling

- Default to TypeScript. New `.js` files only when interop or tooling requires it.
- Target Node 20+ / modern evergreen browsers. Use ES modules (`import`/`export`).
- Enable `strict: true`, `noUncheckedIndexedAccess: true`, and `noImplicitOverride: true` in `tsconfig.json`.
- Use the project's formatter and linter (Prettier + ESLint typically). Never hand-format.

## Types

- Explicit types at module boundaries (exported functions, public class methods, API handlers).
- Infer locally - do not annotate obvious `const x = 1`.
- Prefer `type` for unions/aliases, `interface` for object shapes that may be extended.
- Avoid `any`. Use `unknown` and narrow. Avoid non-null assertions (`!`); narrow with checks or throw.
- Use discriminated unions for state machines; do not use string status fields without a tag literal.

## Async & Errors

- Always `async`/`await`. Do not chain `.then()` except in trivial cases.
- Wrap external I/O in try/catch; rethrow domain errors, never swallow.
- Use typed error classes (`class FooError extends Error`) over string codes.

## Style

- 2-space indentation, single quotes, trailing commas (multiline).
- `camelCase` for variables and functions, `PascalCase` for types and components, `UPPER_SNAKE` for constants.
- Prefer `const`. Use `let` only when reassignment is required. Never `var`.
- Arrow functions for callbacks; `function` declarations for exported top-level utilities.

## React / TSX (when applicable)

- Function components with hooks. No class components in new code.
- Co-locate component, styles, and tests in the same folder.
- Props typed via `interface` or `type`; no `React.FC` wrapper.

## Testing

- Vitest or Jest. Test files: `*.test.ts` / `*.spec.ts` next to source.
- AAA pattern: arrange, act, assert. One logical assertion per test.
