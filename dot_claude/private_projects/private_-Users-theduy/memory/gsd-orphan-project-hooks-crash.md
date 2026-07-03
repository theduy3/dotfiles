---
name: gsd-orphan-project-hooks-crash
description: GSD uninstall from a project leaves a dead hooks block in settings.local.json that crashes every hook event with MODULE_NOT_FOUND
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5fd932c7-9ff7-486b-861a-1d85a23452b0
---

When GSD is removed from a project but reinstalled globally, the project-local `hooks` block in `.claude/settings.local.json` (pointing at `$CLAUDE_PROJECT_DIR/.claude/hooks/gsd-*.js`) becomes an orphan — the dir is gone, so every Stop/PostToolUse/PreToolUse/etc. fires `MODULE_NOT_FOUND` / `posix_spawn ENOENT`.

**Why:** Claude Code merges global + project hooks. Global `~/.claude/settings.json` already wires all GSD hooks from `~/.claude/hooks/`, so the project block is a pure duplicate against a deleted path. Worktrees under `.claude/worktrees/*/.claude/settings.local.json` carry the same dead block (latent crashes).

**How to apply:** strip the whole `hooks` key — `jq --indent 2 'del(.hooks)' f > tmp && node -e "JSON.parse(...)" && mv`. Do it for the main checkout AND every worktree settings file. Keep the `Bash(npx gsd-core *)` permission entry (not a hook). Hit on salonx 2026-06-19. Related: [[gsd-reinstall-global]], [[consolidation-into-s-star]].
