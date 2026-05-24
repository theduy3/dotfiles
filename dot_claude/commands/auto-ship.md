Full end-to-end pipeline after implementation: ship then deploy, fully agent-driven.

Runs ship-agents followed immediately by deploy-agents in sequence.
Use this after implementation is complete and you want a single fire-and-forget command.

## Phase 1 — Ship (invoke ship-agents)
Run all rounds of /ship-agents (scope auto-detected from tasks/todo-*.md):
- Round 1: verify (haiku)
- Round 2: techdebt + reflect — skipped if scope=small, parallel if scope=medium|large
- Round 3: commit + PR (sonnet)

Capture the PR URL/number from Round 3 output.
If any round fails → stop. Do not proceed to Phase 2.

## Phase 2 — Deploy (invoke deploy-agents)

### Pre-step (parent session, BEFORE invoking deploy-agents)
This MUST run in the top-level auto-ship session, not delegated to a subagent.
1. Run `git worktree list` and `pwd`.
2. If `pwd` is inside any worktree that will be cleaned up in Round 2, call `ExitWorktree` now.
3. Verify `pwd` is the main repo root (first entry in `git worktree list`).
4. Only then invoke /deploy-agents.

Why: `ExitWorktree` from a subagent does not change the parent's CWD. If the parent's CWD is still inside the worktree when Round 2 cleanup runs `git worktree remove`, the parent session dies with `ENOENT: posix_spawn '/bin/sh'` for every hook spawn, requiring a Claude restart.

### Run rounds
Run all rounds of /deploy-agents:
- Pre-flight: collect open PRs (will find the PR from Phase 1)
- Overlap check: single PR → skip (no other PR to conflict with)
- Round 1: merge PR (haiku)
- Round 2: cleanup worktree (haiku)
- Round 3: watch CI (haiku, background)

Report final PR URL and CI run link when done.
