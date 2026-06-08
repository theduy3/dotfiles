Clean up after PR merge:

> **CWD SAFETY PRECONDITION:** If this command is invoked from a subagent (e.g. during `/deploy-agents` cascade), the **parent orchestrator's CWD** must already be OUTSIDE the worktree being removed. The parent must have called `ExitWorktree` (or `cd` to main repo root) BEFORE dispatching this cleanup agent. If the parent's CWD is still inside the worktree when `git worktree remove` runs here, the parent session becomes unusable: every subsequent tool call fails with `ENOENT: posix_spawn '/bin/sh'` because Node cannot spawn children from an unlinked CWD, and Claude must be restarted. This command cannot fix that from inside a subagent — `ExitWorktree` called in a subagent does not change the parent's CWD.

1. Run `git worktree list` to see active worktrees
2. Get the current worktree path and branch name
3. Call `ExitWorktree` to cleanly exit the current worktree before navigation (affects current session only — see precondition above)
4. Navigate to the main worktree (first entry in `git worktree list`)
5. Remove the worktree: `git worktree remove <path>`
6. Delete the local branch if it still exists: `git branch -d <branch-name>`
7. Delete the remote branch if it still exists: `git push origin --delete <branch-name>` (ignore errors if already deleted)
8. Resolve the repo's default branch, then sync it:
   - `DEFAULT=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')` — falls back to `main` if unset
   - `git checkout "$DEFAULT" && git pull origin "$DEFAULT"` (handles `master`/`develop`/`trunk`, not just `main`)
9. Clean up task files:
   - Derive `<task-name>` from the branch name, stripping any `feature/`, `fix/`, or `chore/` prefix (the slug `/s1-plan` used). Prefer the `worktree:` field in `tasks/todo-*.md` if present — it is the authoritative slug.
   - Delete `tasks/spec-<task-name>.md` and `tasks/todo-<task-name>.md` if they exist
   - If any files were deleted, commit: `git add -u tasks/ && git commit -m "chore: clean up task files for <task-name>"`
10. Confirm with `git log --oneline -3`
11. Run `git worktree list` to show remaining worktrees
