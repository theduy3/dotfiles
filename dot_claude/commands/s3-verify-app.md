---
context: fork
---
Verify the app works on the current branch:
1. Detect package manager: if `bun.lock` exists use `bun`, otherwise use `npm` (call it $PM)
2. Run `cat package.json | grep -A 20 '"scripts"'` to detect available scripts
3. Run `$PM install` if node_modules doesn't exist
4. If "typecheck" script exists → run `$PM run typecheck`
5. If "lint" script exists → run `$PM run lint`
6. If "test" script exists → run `$PM run test`
7. If "build" script exists → run `$PM run build`
8. If "test:coverage" script exists → run `$PM run test:coverage` and check line coverage >= 80%. If below, report ❌ with actual percentage. Skip with note if no script.
8b. If any of steps 4-7 failed: Launch the build-error-resolver agent (model: "sonnet") to diagnose and fix
    the errors with minimal changes. After fixes, re-run the failed steps to confirm.
    If still failing after one agent pass, report remaining errors and stop.
9. Security scan: Run the /security-scan skill to check source dirs for hardcoded secrets,
   SQL injection, XSS, command injection, and OWASP Top 10 patterns.
   Report findings with severity (CRITICAL/HIGH/MEDIUM/LOW) and file:line references.
   Treat any CRITICAL or HIGH finding as ❌ SECURITY.
9b. **Goal-backward verification** (only if `tasks/todo-<task-name>.md` exists with a Must-Haves block):
    Launch the `verifier` agent. Pass it the plan path `tasks/todo-<task-name>.md` and the changed files
    (the agent's prose assumes a different artifact layout — override by giving the `tasks/` paths explicitly).
    It checks the Must-Haves (truths hold / artifacts substantive not stubs / key links wired), confirms
    **each Truth has a corresponding test** (a truth with no test → ❌ — closes spec→truth→test→code),
    and audits test quality (no disabled tests, no circular/always-pass tests, assertions have real
    expected values).
    Treat unmet Must-Haves, an untested truth, or a failed test-quality audit as ❌.
    **If the running agent cannot spawn sub-agents (e.g. a haiku runner), do NOT skip — perform the
    Must-Haves + test-quality check inline yourself** against `tasks/todo-<task-name>.md` and the
    changed files. This step must never silently vanish just because of the runner's model tier.
    Skip only if no plan with Must-Haves exists.
10. Report results:
    ✅ or ❌ for each step
    Skip steps that don't exist
    End with: READY TO SHIP or NEEDS FIXES
