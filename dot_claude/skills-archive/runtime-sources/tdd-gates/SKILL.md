---
name: tdd-gates
description: Implement an approved plan test-first, in a worktree, against the repo's real blocking gates rather than a guessed subset. Use when a tasks/todo-*.md sits at status plan-approved, or when implementing test-first in any repo. Composes the `tdd` skill for RED/GREEN doctrine. Stops at green gates; never commits, never opens a PR.
---

# `/tdd-gates` — test-first implementation against real gates

Consumes a `tasks/todo-<topic>.md` at `status: plan-approved`. Stops when the
repo's gates are green. **Never commits, never opens a PR, never deploys.**

Shipping is a separate decision made by a human looking at green gates.

## What this skill is, and is not

**The loop belongs to the `tdd` skill.** Invoke it for what a good test is, seams,
anti-patterns, red-before-green, vertical slices. It is upstream-managed and
updates independently. Do not restate its doctrine — read it.

**The repo's facts belong to the repo.** Gate ladders, guard hooks, and which
oracle can fail for a given change are per-project knowledge. If the repo defines
a project-scoped companion skill — `tdd-<project>` under `<repo>/.claude/skills/`
— **invoke that too**, and let it override anything below.

This skill contributes only the discipline that holds in every repo: work in
isolation, prove green before you start, run what CI runs, verify your test can
actually run and actually fail.

## 0. Isolate the work

Implement in a git worktree, not the shared checkout. A checkout has one `HEAD`;
two sessions editing it fight over that `HEAD`, and one `git checkout` silently
discards the other's uncommitted work.

```
EnterWorktree   ← name from the plan's `worktree:` metadata key
```

Budget **exactly one** `EnterWorktree` per task, and no `ExitWorktree` until the
task is done. Each switch regenerates CWD-dependent system-prompt sections and
busts the prompt-cache prefix. Do not bounce.

Some repos enforce this with a `PreToolUse` guard. **Do not rely on it.** Such
guards are fail-open by design — they exit 0 on any internal error, and they
guard only the repos they name. A guard is a safety net, not an invariant. Enter
the worktree because it is correct.

Then flip the plan's metadata to `status: implementing`, so a concurrent session
knows the plan is claimed.

## 1. Baseline — prove green *before* you touch anything

Find the repo's gate command and run it. In order of preference:

1. A single aggregate script — `bun run gates`, `make check`, `just ci`.
2. Failing that, **read the CI workflow** and run exactly what it runs.

Never invent a gate. Never skip one because it is slow. A fresh worktree has no
`node_modules` — install per the lockfile first.

A red baseline means you are inheriting someone else's failure. **Stop.** Fixing
it is a different task, and conflating the two makes both unreviewable.

## 2. The loop

Run the `tdd` skill's red → green loop, one vertical slice at a time. Two
obligations layer on top, and both have shipped bugs when skipped:

**Confirm the runner will execute your test file.** Test configs frequently use an
explicit `include` **allowlist**, not a repo-wide glob. A file outside it passes
when you invoke it by path and never runs in CI. *Green CI cannot distinguish
"tests passed" from "tests never ran."* Read the runner's config, choose a path
inside it, then confirm your file appears in a full test run.

**Watch it fail.** A test you never saw red proves nothing. This is not
ceremony — it is the only evidence that the test is wired to the behavior.

## 3. Pick an oracle that can actually fail

RED does not mean "a unit test." It means **whichever oracle can fail for the
thing you are changing.** The generic rule:

| Changing | RED lives where |
|---|---|
| a module, hook, component | the unit runner, at the public interface |
| a database function | a DB-level test that **calls** it, not one that inspects it |
| a constraint, trigger, or access policy | a test asserting the **deny** path, run as the untrusted role |
| a user-visible string | the i18n/parity check, not the render test |
| an HTTP handler | a boundary-shape test on the response |

Two of these rows exist because the obvious test proves nothing:

- **A database function that compiles is not a function that runs.** Many engines
  bind function bodies lazily, so `CREATE OR REPLACE` succeeds and CI passes while
  the function raises at *call* time. Only a test that calls it can go RED.
- **Asserting a grant proves nothing about a lock.** If the schema grants broadly
  by default, the privilege you think you withheld was never withheld. The test
  that must go RED is a probe *as the untrusted role*, expecting denial.

The project-scoped skill, if one exists, names the concrete commands.

## 4. Gates — green, all of them

Run the full ladder. Read its output, do not infer it.

Traps that are near-universal:

- **The lint script may not include every lint.** Architecture, import, or
  dependency rules are often a separate command.
- **A build is not a test run.** A green build says nothing about behavior.
- **Diff three-dot against the *remote* main, never the local branch name.** A
  squash-merged branch's SHA is not an ancestor of `main`, so `git diff main
  <branch>` reports phantom changes.
- **The committed diff does not see your working tree.** Anything that selects
  work by `origin/main...HEAD` is blind to uncommitted files — which is the only
  state a pre-commit gate ever runs in.

Skipped gates must print *why*. A ladder that silently omits the tiers it did not
run reads as "everything passed."

Fix red at the tier it fires. Do not weaken a linter config, loosen type-checker
strictness, or quarantine a test to reach green — that converts a caught bug into
an uncaught one.

## 5. Verify, then stop

Invoke `superpowers:verification-before-completion`. Evidence before assertions:
paste the command and its output. "Tests pass" is a lie if any were skipped —
name the skips. "Done" is a lie if anything was silently deferred.

Then **stop.** Report what is green, what is red, what you skipped and why.

Committing, pushing, opening a PR, merging, deploying — none of these belong to
this skill.

## Consumed from

`/plan`, which leaves `tasks/todo-<topic>.md` at `status: plan-approved`.
Alternative consumers of the same artifact: `gsd-execute-phase`, or
`superpowers:subagent-driven-development` when `scope: medium | large`.
