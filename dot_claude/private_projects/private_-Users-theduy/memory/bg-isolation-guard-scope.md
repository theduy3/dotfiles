---
name: bg-isolation-guard-scope
description: "bgIsolation=none in a repo's .claude/settings.json only exempts sessions whose PROJECT DIR is that repo; cd-ing in from elsewhere arms the guard"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b6390a64-69af-4b35-a46a-84f174324c44
  modified: 2026-07-25T16:58:34.701Z
---

A background session's worktree-isolation guard resolves `worktree.bgIsolation` from the
**session's project directory**, not from the git repo containing the file being written.
So `~/tasks/.claude/settings.json` with `bgIsolation: none` exempts a session rooted at
`~/tasks` — and does nothing for a session rooted at `~` that merely `cd`s in.

**Why:** Bash cwd persists across calls. A session rooted at `~` (not a git repo) writes
into `~/tasks` freely; one `cd ~/tasks/...` later the identical Write is refused with
"This background session hasn't isolated its changes yet." Verified in both directions on
2026-07-25: blocked twice with cwd inside `~/tasks`, succeeded immediately after returning
cwd to `~`. EnterWorktree is not the fix when the session root isn't a repo at all.

**How to apply:** In background jobs, use `(cd X && cmd)` subshells so cwd never migrates
into a guarded repo. If Write starts failing mid-session after it was working, check `pwd`
before concluding the guard is misconfigured. Recorded as a durable Lesson node at
`~/theduyvault/Notes/Claude-Context/lessons/bg-isolation-guard-uses-session-project-dir.md`
— see [[graph-engineering-lesson-store]].
