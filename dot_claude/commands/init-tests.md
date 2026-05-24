---
context: fork
---

You are a test infrastructure bootstrapper. Set up vitest + testing-library in a Vite + React + TypeScript project.

## Step 1: Detect & Validate Project

1. Read `package.json` from the current working directory. If it doesn't exist, print `❌ No package.json found` and stop.
2. Check if `bun.lock` exists → use `bun`, otherwise use `npm`. Assign to `$PM`.
3. Validate project type:
   - Check `devDependencies` or `dependencies` for `vite` → required
   - Check `dependencies` for `react` → required
   - Check `devDependencies` for `typescript` → required
   - If any are missing, print `❌ This command requires a Vite + React + TypeScript project` and stop.

## Step 2: Check Existing Setup

1. If `devDependencies` already contains `vitest`, print `⏭️ vitest is already installed — nothing to do` and stop.
2. If `scripts.test` already exists in package.json, print `⏭️ Test script already configured — nothing to do` and stop.

## Step 3: Install Dependencies

Run:
```bash
$PM add -d vitest @testing-library/react @testing-library/jest-dom jsdom
```

If exit code is non-zero, print `❌ Dependency installation failed` and stop.

## Step 4: Add Test Scripts

Add these scripts to `package.json` (preserve all existing scripts):

```json
"test": "vitest run",
"test:watch": "vitest",
"test:file": "vitest run"
```

Use the Edit tool to add them after the last existing script entry.

## Step 5: Configure Vitest

Modify the project's `vite.config.ts`:

1. Add `/// <reference types="vitest" />` as the very first line of the file (before any imports).
2. Add a `test` block inside `defineConfig({})`, after the last existing top-level property:

```ts
test: {
  globals: true,
  environment: "jsdom",
  setupFiles: "./src/test/setup.ts",
  include: ["src/**/*.test.{ts,tsx}"],
},
```

## Step 6: Create Setup File

Create `src/test/setup.ts`:

```ts
import '@testing-library/jest-dom/vitest'
```

## Step 7: Create Smoke Test

Create `src/test/smoke.test.ts`:

```ts
import { describe, it, expect } from 'vitest'

describe('test infrastructure', () => {
  it('works', () => {
    expect(true).toBe(true)
  })
})
```

## Step 8: Verify

Run `$PM run test`. If exit code is 0 and the smoke test passes, print:

```
✅ Test infrastructure initialized

  Installed: vitest, @testing-library/react, @testing-library/jest-dom, jsdom
  Scripts:   test, test:watch, test:file
  Config:    vite.config.ts (test block added)
  Setup:     src/test/setup.ts
  Smoke:     src/test/smoke.test.ts (1 test passed)

  Next steps:
  - Write tests in src/**/*.test.{ts,tsx}
  - Run tests:        $PM run test
  - Watch mode:       $PM run test:watch
  - Single file:      $PM run test:file -- "src/path/to/file"
```

If the test fails, print `❌ Smoke test failed` with the error output.

## Important Rules

- Use `bun` if `bun.lock` exists, otherwise `npm`. Never hardcode the package manager.
- Never overwrite existing test configuration — always check first.
- Keep the vitest config minimal. The project's existing Vite plugins and aliases are inherited automatically.
- Use the Edit tool (not Write) when modifying existing files like `package.json` and `vite.config.ts`.
