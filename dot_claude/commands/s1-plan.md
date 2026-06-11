Create a scope-aware implementation plan from the /s0-brainstorm spec:

Parse task name from: `$ARGUMENTS`
- If provided → use as task name, derive kebab slug
- If empty → scan tasks/spec-*.md, ask user to pick

## Step 1 — Load Spec (or derive the contract)
Load tasks/spec-<task-name>.md if it exists (the `/s0` path, used for bigger work).
If none found, do NOT proceed on the task description alone — **derive the Must-Haves contract
inline in Step 3** from the task description. Every plan ends up with a Must-Haves block, spec or
not. This keeps small direct-`/s1` jobs spec-driven without forcing `/s0`.

## Step 2 — Scope Detection
Analyze the spec or task description and classify:

| Scope | Signals |
|-------|---------|
| **small** | 1-3 files, no design decisions, clear implementation path |
| **medium** | 4-10 files, some design choices, may introduce new patterns |
| **large** | 10+ files, architectural decisions, cross-cutting concerns |

If repo is indexed (code-review-graph `list_graph_stats`): run `query_graph` + `get_impact_radius` MCP tools to gauge blast radius. Factor into classification.
User can override: "this is small" or "treat this as large".

## Step 3 — Write Plan
Enter plan mode. Invoke `writing-plans` with spec as context.

Write plan to `tasks/todo-<task-name>.md`:

```
<!-- s1 metadata
task-name: <name>
worktree: <name>
speckit: false
scope: small|medium|large
status: planning
repo: <absolute-repo-root>
created-at: <today's date, YYYY-MM-DD>
-->

## Must-Haves (goal-backward verification anchors)
<!-- Derived from the spec's GOAL, not from the task list. /s3-verify checks these, not just "tasks done". -->
- **Truths**: observable facts that must hold when the goal is achieved (e.g. "user can log in with email+password")
- **Artifacts**: files/modules that must exist and be substantive (not stubs)
- **Key links**: wiring that must connect (export X imported by Y; endpoint Z actually called)

## Implementation Plan

- [ ] Step 1: ...
- [ ] Step 2: ...
```

> The Must-Haves block is the contract `/s3-verify-app`'s goal-backward check reads. Keep it concrete and falsifiable.
> **Each Truth becomes a FAILING test first in Step 5 (TDD)** — write truths so each maps cleanly to one test.
> For deep plan authoring on large scope, the `planner` agent (harvested from GSD) can draft this block — invoke it with the spec path.

Present plan for user approval.

## Step 4 — After Approval (ExitPlanMode)

> **Invariant — worktree is unconditional.** EVERY task enters a worktree here, regardless of
> scope. Scope (small/medium/large) selects implementation STYLE in Step 5 only — it NEVER decides
> whether a worktree is used. Never announce or imply "no worktree" for any scope. No matter how
> small the task, it runs in a worktree.

1. Update metadata: `status: planning` → `status: plan-approved`
2. Safety check: verify `.gitignore` includes worktree directory pattern
3. Call `EnterWorktree` with task-name — **mandatory for all scopes, no exceptions**
4. Run baseline tests to confirm clean starting point

## Step 5 — Execute Skill Handoff (test-first, mandatory)

**Precondition — a test runner must exist.** If `package.json` has no `test` script / no test
framework configured (or the stack has no runner), bootstrap it BEFORE any implementation:
Vite+React+TS → invoke `/init-tests`; otherwise set up the stack's standard test runner. TDD
cannot run without a runner.

**Every scope is test-first.** Each Must-Have *truth* becomes a FAILING test first (RED → verify it
fails for the right reason → minimal GREEN), per the `test-driven-development` Iron Law: no
production code without a failing test first.

Branch on scope (all paths run **inside the Step 4 worktree** — scope picks STYLE, not isolation):

### scope: small
Implement directly (single-context TDD) **inside the Step 4 worktree** — invoke the
`test-driven-development` skill. No prompt (fast loop). Drive the truths→tests→code cycle.
"Directly" here = one context, no subagents — it does NOT mean "in the main repo." You are already
in the worktree from Step 4.

### scope: medium | large
**PROMPT user via `AskUserQuestion`:**

Question: `"Plan approved and baseline tests pass. Start implementation with subagent-driven-development (test-first)?"`

Options:
- **Yes, start now** → invoke `subagent-driven-development` (model: opus) — embeds per-task TDD.
- **Yes, single-agent TDD** → invoke `test-driven-development` (single-agent RED→GREEN loop).
- **Pause — I'll run execute later** → stay in worktree, status already `plan-approved`, exit. Next session auto-resumes per `~/.claude/rules/common/session-resume.md`.

(No non-TDD executor — test-first is mandatory on every path.)

For `large` scope: before dispatching subagents, confirm plan contains granular self-contained tasks (each task = one subagent, independent, testable). If not, return to Step 3 and refine.

After implementation: stay in worktree. Run `/auto-ship` or `/ship-agents` when ready to ship.
