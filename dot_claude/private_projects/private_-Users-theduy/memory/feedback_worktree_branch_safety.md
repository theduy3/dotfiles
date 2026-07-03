---
name: Worktree Branch Safety
description: NEVER commit to main when working in a worktree — always verify you're on the feature branch before any git write operation
type: feedback
---

NEVER accidentally commit to main instead of the feature branch when working in a worktree.

**Why:** Worktrees can create confusion about which branch is checked out. Committing to main instead of the feature branch contaminates the main branch with in-progress work, which is very hard to undo safely (especially if pushed) and defeats the entire purpose of branch isolation.

**How to apply:**
- Before ANY git write operation (commit, stash, reset, etc.) in a worktree, run `git branch --show-current` to confirm you're on the correct feature branch
- If the current branch is `main` or `master`, STOP immediately and switch to the correct branch or navigate to the correct worktree directory
- When entering a worktree via `EnterWorktree`, verify the branch name in the output before proceeding
- After `ExitWorktree`, remember you're back on main — do NOT continue committing implementation work
