# Session Resume

On session start or after context clear, scan for `tasks/todo-*.md` files in the current repo.

If any file contains an s1-plan metadata block with `status: plan-approved`:
- If multiple such files exist, pick the one whose `worktree:` field matches the current branch (if in a worktree) or ask the user which task to resume

0. **Stale-age check.** Before anything else, determine plan age:
   - Prefer `created-at: YYYY-MM-DD` in the metadata block.
   - Fallback to filesystem mtime: `stat -f%Sm -t "%s" tasks/todo-<name>.md`.
   - If age > 14 days, STOP and warn the user: `"Plan is N days old — main may have diverged since. Reply 'resume' to continue or 'replan' to run /s1-plan fresh."` Block further action until the user replies.
1. Read the full plan from the matched `tasks/todo-<task-name>.md`
2. Follow the **Setup** section exactly:
   - If in plan mode → call `ExitPlanMode` (auto-approved by PreToolUse hook) to unblock writes
   - Check metadata for `speckit: true`:
     - **If speckit:** Check if worktree already exists (`git worktree list | grep <speckit-branch>`)
       - If exists: `cd` into it
       - If not: `git worktree add .claude/worktrees/<speckit-branch> <speckit-branch>`, then `cd` into it
     - **If not speckit:** Call `EnterWorktree` with the worktree name from the metadata block
3. Once in the worktree, run baseline tests to confirm clean starting point
4. Check the `scope` field in the metadata block (the key `/s1-plan` writes):
   - If `scope: medium` or `scope: large`: use `superpowers:subagent-driven-development` for implementation — the plan should contain granular, self-contained tasks
   - If `scope: small`: implement directly with TDD discipline
5. Proceed with the implementation steps from the plan
6. After implementation begins, update `status: plan-approved` to `status: implementing`

This enables `/s1-plan` workflows to survive context clears. New sessions start in normal mode (not plan mode), so ExitPlanMode is usually unnecessary. If in plan mode, the PreToolUse hook exists but does NOT bypass the interactive selector on Android — type "proceed" as a text message instead.
