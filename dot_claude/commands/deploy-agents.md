Agent-orchestrated batch deploy. Collects open PRs, checks for file overlaps, merges in parallel, cleans up worktrees, watches CI:

## Pre-flight — Parent CWD Safety (CRITICAL — orchestrator only, NOT a subagent)
Before dispatching ANY agent (merge, cleanup, watch CI):
1. Run `pwd` and `git worktree list`.
2. If `pwd` is inside any worktree, call `ExitWorktree` to return to the main repo root.
3. Verify `pwd` is the main repo root (first entry in `git worktree list`).

Why: `ExitWorktree` and `cd` only change CWD in the context where they run. If invoked by a subagent, the parent's CWD is unchanged. When a later Round 2 subagent runs `git worktree remove`, the parent is left pointing at a deleted directory. All subsequent tool calls fail with `ENOENT: posix_spawn '/bin/sh'` because Node cannot spawn any child process when parent CWD is unlinked — the session is effectively dead until restart. Doing this once in Pre-flight eliminates the timing window before Round 2.

## Pre-flight — Collect PRs
Run: `gh pr list --state open --json number,headRefName,title`
Capture all open PRs targeting main from feature branches.

If none found → stop: "No open PRs to deploy."

## Pre-flight — Overlap Check
For each PR, fetch changed files:
  `gh pr diff <number> --name-only`

Compare all file lists for intersections.

If overlaps found:
  - List the overlapping files and which PRs share them
  - Warn: "⚠️ File conflicts detected — these PRs may interact. Batch deploy is risky."
  - If CLAUDE_REMOTE=1 → stop (do not proceed without human review)
  - Otherwise → ask user to confirm before continuing

If no overlaps → proceed automatically.

## Round 1 — Merge (parallel, haiku)
Dispatch one Agent per PR in a single message:
  Agent(model: haiku): `gh pr merge <number> --merge --delete-branch`
  Confirm each PR merged successfully before Round 2.

## Round 2 — Cleanup (parallel, haiku)

Parent CWD already validated in Pre-flight — Parent CWD Safety. Do NOT dispatch any cleanup agent if that step was skipped; abort and run it first.

### Dispatch cleanup agents
Dispatch one Agent per merged worktree in a single message:
  Agent(model: haiku): Run s9-cleanup for worktree associated with PR branch.

## Round 3 — Watch CI (haiku, background)
Dispatch Agent(model: haiku, run_in_background: true):
  Poll `gh run list --branch main --limit 1` every 60s.
  Notify when status = completed.
  Report: ✅ Deploy succeeded or ❌ Deploy failed with run URL.
