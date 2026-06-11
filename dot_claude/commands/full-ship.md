---
description: End-to-end worktree pipeline — brainstorm, plan, implement, ship, deploy.
argument-hint: [topic]
---

Drive the full worktree workflow from spec to successful deployment in one command.

> **Recommended session**: opus. Phases 0–1 require reasoning (brainstorm Q&A, plan design). Sub-commands route to sonnet/haiku internally where appropriate.
> **Remote mode caveat**: in `CLAUDE_REMOTE=1`, `ExitPlanMode` auto-approves but `AskUserQuestion` and `/emergency-pr-revert`'s YES prompt still block. Phase 5 revert flow will hang in remote mode — handle manually.

## Argument parsing

Parse topic from `$ARGUMENTS`.
- If provided (e.g. `/full-ship add user authentication`) → use as topic.
- If empty → ask the user: "Describe the task you want to ship end-to-end."

Derive `<task-name>` slug from topic (lowercase kebab-case). This slug is reused across all phases.

---

## Phase 0 — Brainstorm

Invoke `/s0-brainstorm <topic>`. This runs the `brainstorming` skill, writes `tasks/spec-<task-name>.md`, and waits for user approval.

**Stop conditions**:
- User rejects spec → stop. No worktree exists; nothing to clean.
- Spec already exists and user opts to keep it → continue to Phase 1.

After s0 commits the spec, do NOT invoke `/s1-plan` automatically (s0's default handoff). Instead, proceed directly to Phase 1 below.

---

## Phase 1 — Plan

Invoke `/s1-plan <task-name>`. This loads the spec, classifies scope, writes `tasks/todo-<task-name>.md`, enters plan mode, and waits for `ExitPlanMode` approval. After approval, s1 calls `EnterWorktree`.

**Stop conditions**:
- User rejects plan → stop. Still in main repo; no worktree to clean.

After `EnterWorktree`, read `tasks/todo-<task-name>.md` metadata block and extract `scope:` field. Capture for Phase 2 routing. If field missing → default `medium`.

IMPORTANT: At this point you are inside the worktree. Do NOT `git checkout main` or navigate out until Phase 4's CWD pre-step.

---

## Phase 2 — Implement (scope-routed)

Branch on the captured `scope:`:

### scope: small
Implement the plan steps directly with TDD discipline (`test-driven-development`). Single-file or 1-3 file changes don't justify the subagent overhead.

### scope: medium | large
Invoke `subagent-driven-development` (model: opus). The plan from `/s1-plan` should already contain granular self-contained tasks (each = one subagent, independent, testable) per s1's large-scope guard. If not, return to `/s1-plan` to refine before proceeding.

### After implementation completes
- Run baseline tests one more time to confirm green state.
- Surface a brief summary (3-5 bullets) of what was built.
- STAY in the worktree. Proceed to Phase 3.

**Stop condition**: tests fail and `build-error-resolver` cannot recover after one pass. Stop in worktree. Tell user to fix manually and re-run `/auto-ship` to resume from Phase 3 onward.

---

## Phase 3 — Ship

Invoke `/ship-agents`. This runs:
- Round 1: verify (haiku) — typecheck, lint, test, build, security scan.
- Round 2: techdebt + claude-md (parallel; Round 2A skipped if scope=small).
- Round 3: commit, push, create PR (sonnet).

Capture the PR URL/number from Round 3 output.

**Stop condition**: Round 1 returns NEEDS FIXES → stop. Surface errors. User fixes manually and re-runs `/auto-ship`.

---

## Phase 4 — Deploy (Rounds 1–2)

### CWD pre-step (CRITICAL — orchestrator runs this, NOT a subagent)

Before dispatching any deploy-agents subagents:

1. Run `git worktree list` to enumerate active worktrees.
2. If parent (this session's) `pwd` is inside ANY worktree that Round 2 will remove → call `ExitWorktree` to return CWD to main repo root.
3. Verify `pwd` is the main repo root (first entry in `git worktree list`).

Skipping this step bricks the session: Node `posix_spawn` fails with `ENOENT: posix_spawn '/bin/sh'` when parent CWD points at a deleted directory. `ExitWorktree` called inside a subagent does NOT fix the parent's CWD.

### Invoke `/deploy-agents` Rounds 1–2

- Pre-flight: collect open PRs (will find the one from Phase 3).
- Overlap check: single PR → skip.
- Round 1: merge PR (haiku). Requires `gh pr merge` permission — confirm allowed before dispatch.
- Round 2: cleanup worktree (haiku) via `/s9-cleanup`.

**Stop condition**: overlap conflicts in `CLAUDE_REMOTE=1` → stop. Surface conflicting PRs.

---

## Phase 5 — CI watch (background)

Dispatch `/deploy-agents` Round 3 (background haiku agent). It polls `gh run list --branch main --limit 1` every 60s and notifies on completion.

### On green
Report: `✅ Deploy succeeded — <run-url>`. End of pipeline.

### On red
1. Surface failure with run URL.
2. Invoke `/emergency-pr-revert`. NOTE: that command requires the user to type `YES` to confirm — `/full-ship` cannot auto-confirm. Surface the prompt and wait.
3. After revert, report final state.

---

## Final report

End with a one-screen summary:

```
✅ Full-ship complete: <task-name>
  Spec:    tasks/spec-<task-name>.md (committed: <sha>)
  Plan:    tasks/todo-<task-name>.md (scope: <scope>)
  PR:      <url>
  Merge:   <merge-sha>
  Deploy:  <run-url> ✅
```

Or, if pipeline aborted mid-flow, report which phase stopped and the next manual command to resume from.
