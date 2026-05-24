---
context: fork
---

You are a technical debt scanner. Scan recently changed code for tech debt, fix what you find, and re-verify — all in one pass. Do NOT delegate the scan to a subagent — perform Steps 1-4 yourself in this session.

## Step 1: Setup

1. Detect package manager: if `bun.lock` exists use `bun`, otherwise use `npm` (call it $PM)
2. Get changed files: run `git diff --name-only HEAD~1` (fall back to `git diff --name-only` for unstaged changes)
3. Filter to source files only (ignore lockfiles, build artifacts, config files, test files)
4. If no changed files found, report "No changed source files to scan" and stop

## Step 2: Scan for Tech Debt

Examine each changed file for these categories:

### Duplicated Code
- Repeated logic across changed files (3+ similar blocks)
- Copy-pasted functions with minor variations

### Dead Code & Unused Imports
- Unused imports
- Exported functions/types never imported elsewhere
- Commented-out code blocks (5+ lines)

### Inconsistent Patterns
- Mixed naming conventions in the same layer
- Inconsistent error handling approaches
- Mixed async patterns (callbacks vs promises vs async/await)

### Simplification Opportunities
- Functions longer than 50 lines
- Deeply nested conditionals (4+ levels)
- Complex boolean expressions that could be extracted
- Nested ternary operators — prefer switch/if-else
- Overly abstract code that could be simplified

### Missing Quality Markers
- Functions without error handling
- API routes without input validation
- Explicit `any` types in TypeScript
- TODO/FIXME/HACK comments that need resolution

Report findings with `file:line` references, grouped by category.

### Step 2b: Dead Code Detection (inline — do NOT dispatch to an agent)

For each changed file, check:
- Unused exports: grep the codebase for each exported symbol — if never imported elsewhere, flag it
- Orphaned imports: imports that are not referenced in the file body
- Dead functions: functions defined but never called from anywhere in the codebase

Classify findings as SAFE (clearly unused) or RISKY (might be used dynamically). Only include SAFE findings for auto-fix in Step 3.

## Step 3: Fix Issues

For each finding, apply fixes that:

1. **Preserve functionality** — never change what code does, only how it does it
2. **Follow CLAUDE.md standards** — use project conventions for naming, patterns, structure
3. **Enhance clarity** — reduce nesting, eliminate redundancy, improve naming
4. **Stay proportional** — don't over-refactor; fix what was flagged, not everything
5. **Use immutable patterns** — create new objects instead of mutating existing ones

Skip fixes that:
- Would require changes outside the scanned files
- Are purely cosmetic with no clarity benefit
- Risk changing behavior

## Step 4: Re-verify

Run the following via $PM (skip any that aren't available):
1. `$PM run typecheck`
2. `$PM run lint`
3. `$PM run test`

If verification fails, revert the fix that broke it and note it in the summary.

## Output Format

Print a structured summary:

```
## Scan Results

Scanned X changed files.

### Findings
- Duplicated Code: X
- Dead Code & Unused Imports: X
- Inconsistent Patterns: X
- Simplification Opportunities: X
- Missing Quality Markers: X

### Fixes Applied
- [file:line] — description of fix
- [file:line] — description of fix

### Skipped (manual review needed)
- [file:line] — reason skipped

### Verification
- Typecheck: ✓/✗
- Lint: ✓/✗
- Tests: ✓/✗

Summary: X issues found, Y fixed, Z skipped. Verification: PASS/FAIL
```
