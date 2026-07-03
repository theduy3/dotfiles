---
name: salonx-worktree-guard
description: Hard PreToolUse hook blocking all Write/Edit into the salonx MAIN checkout — forces parallel sessions into worktrees
metadata: 
  node_type: memory
  type: project
  originSessionId: 756d6320-eaf6-4015-bc43-cbf678fd9d7f
---

`~/.claude/hooks/salonx-worktree-guard.js` (PreToolUse, matcher `Write|Edit|MultiEdit`, wired in `~/.claude/settings.json` right after `worktree-path-guard.js`). Added 2026-07-03.

**Why:** Two Claude sessions sharing `/Users/theduy/Repo/salonx` fought over its single HEAD — one `git checkout` silently stomped the other's uncommitted tree (phantom `en.ts +138`, repurposed `feat/fetch-seam-cluster-1` branch, vanishing files). A worktree = (working dir + index + HEAD); the main checkout has ONE HEAD, so concurrent writers collide. User chose the hard-hook fix (vs doc-only).

**How to apply:** Guard BLOCKS (exit 2) any Write/Edit/MultiEdit whose repo root is in `GUARDED_ROOTS` (default `/Users/theduy/Repo/salonx`, override via env `SALONX_GUARD_ROOTS=/a:/b`) AND cwd is the main checkout (not a `.git/worktrees/` linked worktree). Exempts: linked worktrees, non-salonx repos, files outside the repo, edits under `tasks/`. Fail-open (exit 0) on any error. Differs from [[gsd-phase-worktree-guard]] / worktree-required-guard.js by having NO `/s*`-task-state gate — presence in salonx main is itself the block. To work in salonx: `EnterWorktree` or `git worktree add ../salonx-wt/<task> -b feat/<task> origin/main` then cd in. Parallel writer subagents: pass `isolation:"worktree"` to Agent / `opts.isolation:'worktree'` in Workflow. Cleanup honors [[feedback_worktree_cwd_enoent]] (exit worktree in parent before `git worktree remove`). Verified all 5 logic branches 2026-07-03.

**Recovery COMPLETE 2026-07-03:** incident fully recovered per `tasks/recovery-checklist.md` (audit: no meaningful work lost; `en.ts +138` was duplicate-key corruption, discarded). 4 PRs merged same day: #1049 (fetch-seam C1 + drift-recovery test), #1050 (client-portal Auth M1), #1051 (CLAUDE.md worktree rule — the doc half of this guard, was uncommitted and nearly lost), #1052 (fetch-seam spec re-scope). km JSONs pushed on `feat/i18n-translate-km`; `gsd/v0.1.0-phase-12` pushed to origin (phase-12 planning docs existed ONLY there — checklist wrongly said delete). Rescue stash dropped; main checkout clean. Ops notes: repo's `BLOCKED` mergeStateStatus (required-signatures rule) is advisory — API squash-merge works, GitHub signs the squash commit; `src/**` tests can't import `node:*` (tsconfig.app lacks node types) — node-dependent tests go in `tests/unit/`.
