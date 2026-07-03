---
name: gsd-phase-worktree-guard
description: Global PreToolUse hook forces GSD phase execution into worktrees; GSD_ALLOW_INLINE=1 is the escape hatch
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fee6f349-c849-4cdb-abd1-ca10560245af
---

Global PreToolUse hook `~/.claude/hooks/gsd-phase-worktree-guard.js` (matcher `Write|Edit|MultiEdit`) **blocks source-file writes to the MAIN checkout while `.planning/STATE.md` frontmatter reports `status: executing`**. Exempts `.planning/` and `tasks/`; passes when cwd is inside a linked worktree. Fail-open on any error.

**Why:** `/gsd-execute-phase` only attaches `isolation="worktree"` to *spawned* `gsd-executor` subagents, and an Opus orchestrator can (and did, on salonx) deliberately run inline on the main checkout instead — config alone (`use_worktrees`, `parallelization`, `inline_plan_threshold:0`) can't force it because the dispatch is model-instructed, not hook-enforced. This hook is the hard backstop the user wanted.

**How to apply:**
- If a write is denied mid-phase with "GSD worktree required", spawn `Agent(subagent_type="gsd-executor", isolation="worktree")` or `EnterWorktree` — do NOT just retry.
- For a LEGIT inline plan (Decision-checkpoint Pattern C, or a gap-closure with no PLAN — these can't run in a worktree by design), set `export GSD_ALLOW_INLINE=1` for the session, then unset to re-arm.
- Self-disarms when GSD flips `status` off `executing` (→ `phase-complete`/`verifying`). If a crashed run leaves `status: executing` stale, the hook stays armed → fix STATE.md or use the env hatch.

**Wiring is template-owned:** lives in `settings.json.tmpl` (after `worktree-path-guard`), NOT a manual edit to live `settings.json` — `chezmoi apply` reverts live edits (see [[claude-config-chezmoi-sync]]). Hook file is chezmoi-managed as `executable_gsd-phase-worktree-guard.js`. Pushed to theduy3/dotfiles `5ee8c63`.

Related: [[claude-config-chezmoi-sync]] (edit .tmpl not live), [[gsd-orphan-project-hooks-crash]] (fail-open is load-bearing), [[feedback_worktree_branch_safety]]. Distinct from `/s*`'s `worktree-required-guard.js` (armed by `tasks/todo-*.md` status); this one is GSD-armed by STATE.md.
