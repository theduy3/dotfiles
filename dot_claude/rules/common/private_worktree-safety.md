---
paths:
  - ".claude/**"
  - "**/CLAUDE.md"
  - "**/settings*.json"
---

# Worktree Safety

> Single source of truth for worktree safety. The worktree guard hooks defer here.
> Load on demand (worktree ops).

## The CWD-ENOENT restart trap (the #1 footgun)

If the parent session's CWD is inside a worktree when `git worktree remove` runs,
**every subsequent tool call dies** with `ENOENT: posix_spawn '/bin/sh'` — Node cannot
spawn children from an unlinked directory. Claude must be restarted. This cannot be
hook-enforced from the parent, because a hook (or `ExitWorktree`) running inside a
**subagent does not change the parent orchestrator's CWD**.

**Ordering contract — the parent MUST do this before any worktree removal:**
1. `git worktree list` — enumerate worktrees.
2. If the parent's `pwd` is inside ANY worktree about to be removed → call `ExitWorktree`
   (or `cd` to the main repo root) **in the parent**, not in a subagent.
3. Verify `pwd` == main repo root (first entry of `git worktree list`).
4. Only then dispatch `git worktree remove`.

Never remove a worktree from a subagent while the parent CWD is still inside it.

## Enforced guards (PreToolUse — zero token/cache cost)

- **`worktree-path-guard.js`** (`Write|Edit|MultiEdit`) — blocks absolute-path writes that
  resolve outside the active worktree (catches paths derived from the main checkout).
- **`worktree-branch-guard.js`** (`Bash`) — blocks `git commit` when CWD is inside a linked
  worktree AND the branch is the repo default (main/master/…). Commit from the feature
  branch, or from the main checkout if intentional.
- ~~`gsd-phase-worktree-guard.js`~~ — **DELETED 2026-08-07** with the rest of GSD.

All fail-open (exit 0 on any error) — they never block valid work due to hook failure.

⚠️ **Fail-open means a timing-out guard is not a guard.** The 2026-08-07 hook audit found
`worktree-branch-guard.js` exceeded its 5s timeout on **2 of 2** observed runs — so it had never
once completed, and was protecting nothing while still costing 5s per `git commit`. Timeout is now
**15s**. Root cause is `spawnSync('git', …)` under parallel-session load. Re-measure before
trusting this guard; do not assume it is protecting you.

## Token: minimize Enter/Exit cycles

`EnterWorktree`/`ExitWorktree` regenerate CWD-dependent system-prompt sections → they
**bust the prompt-cache prefix**. The cost is structural and per-switch. Budget: **one
`EnterWorktree` (at task start) and one `ExitWorktree` (at cleanup) per task.**
Do not bounce in and out.
