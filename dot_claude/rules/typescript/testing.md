---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Testing

> This file extends [common/testing.md](../common/testing.md) with TypeScript/JavaScript specific content.

## E2E Testing

Use **Playwright** as the E2E testing framework for critical user flows.

## Agent Support

No E2E-specific agent is installed. The former `e2e-runner` was removed 2026-08-04 (it did not
resolve); run Playwright directly, or via CI. Restorable from
`~/.claude/plugins/cache/ecc/ecc/2.0.0-rc.1/agents/e2e-runner.md` if an agent is ever wanted.

- **tdd-guide** — write-tests-first enforcement (see [common/agents.md](../common/agents.md))
