---
name: Worktree CWD ENOENT root cause
description: When hooks fail with ENOENT posix_spawn '/bin/sh' after a worktree was removed, the cause is the parent session's CWD became unlinked — not a missing shell binary. Cannot recover; must restart Claude.
type: feedback
originSessionId: a87211e0-542b-4c5d-ab39-d0b320fcf0e4
---
Symptom: every PreToolUse / PostToolUse / Stop / UserPromptSubmit hook fails with `ENOENT: no such file or directory, posix_spawn '/bin/sh'` after `/auto-ship` or `/deploy-agents` cleans up a worktree.

**Why:** macOS `posix_spawn(2)` returns ENOENT when the calling process's CWD is missing, even if the executable path is valid. `/bin/sh` exists; the dead CWD is the real cause. Bash tool has built-in CWD recovery (chdir to $HOME on detection); hooks do not — they're spawned by the harness inheriting the original (now unlinked) CWD.

**Trigger:** A subagent runs `git worktree remove` while the parent session's CWD is still inside that worktree. `ExitWorktree`/`cd` from a subagent never changes the parent's CWD.

**How to apply:**
- If you see this error, recovery is impossible from inside the session — tell the user to restart Claude.
- Prevention lives in `~/.claude/commands/auto-ship.md` (Phase 2 Pre-step) and `~/.claude/commands/deploy-agents.md` (top-level Pre-flight — Parent CWD Safety). Both call `ExitWorktree` in the parent before dispatching cleanup. Don't remove or weaken those sections.
- When designing any orchestrator that spawns cleanup subagents, make the parent ExitWorktree step run *before* any subagent dispatch, in the top-level session.
