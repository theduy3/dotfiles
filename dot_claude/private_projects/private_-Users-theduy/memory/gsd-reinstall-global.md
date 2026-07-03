---
name: gsd-reinstall-global
description: "GSD reinstalled globally 2026-06-10 — install command, manifest-idempotency gotcha, chezmoi handling"
metadata: 
  node_type: memory
  type: project
  originSessionId: ba0c5c3e-dd7c-437f-b1fc-c5fa0132b484
---

GSD ("Get Shit Done") was reinstalled **globally** for Claude Code on 2026-06-10 (user wants
it as main workflow; only the global install step done — Superpowers/`/s*`/ECC overlap
reconciliation deferred). Supersedes the "GSD removed 2026-06-08" claim in
[[plugin-routing-priorities]] and worktree-and-vault.md — those docs are now stale pending the
user's final orchestrator decision.

**Package:** `@opengsd/gsd-core` (scoped — bare `gsd-core` 404s on npm). NOT a Claude plugin/marketplace.
**Install cmd:** `npx @opengsd/gsd-core@1.4.4 --claude --global --profile=standard`
(`--profile`: full ≈12k cold-start tokens / standard ≈700 / minimal=core. Persisted; honored by `gsd update`.)
**Lays down:** `~/.claude/skills/gsd-*` (19 @ standard), `~/.claude/agents/gsd-*` (33),
`~/.claude/hooks/gsd-*` + `hooks/lib/`, runtime `~/.claude/gsd-core/` (VERSION file), and edits
`~/.claude/settings.json` hooks (7 events). Skips statusline unless `--force-statusline`.
**Uninstall:** `npx @opengsd/gsd-core --claude --global --uninstall`.

**GOTCHA 1 — manifest-idempotent installer:** re-running the installer does NOT restore files
deleted out-of-band; `gsd-file-manifest.json` records them as installed so it skips re-laying.
To restore deleted agents, copy from a project install (salonx `.claude/agents/gsd-*.md`, same
v1.4.4) or uninstall+reinstall.

**GOTCHA 2 — chezmoi (`~/.claude` is chezmoi-managed, see [[claude-config-chezmoi-sync]]):**
- `settings.json` is a TEMPLATE (`dot_claude/settings.json.tmpl`, only `{{ .chezmoi.homeDir }}`).
  GSD hooks were folded in by regenerating the tmpl from the live settings.json (home dir
  re-tokenized) → `chezmoi diff` = 0 so `apply` won't strip GSD hooks.
- GSD agents added to `.chezmoiignore` as `.claude/agents/gsd-*.md` (matches existing
  "externally-managed/regenerable" philosophy; skills/hooks/runtime already unmanaged). GSD owns
  them via installer/`gsd update`.
- **NEVER `chezmoi apply` GSD agent paths** to "clear cosmetic status": on 2026-06-10 a scoped
  `chezmoi apply ~/.claude/agents/gsd-*.md` DELETED 27 agents (DA = dest-modified-since-written →
  apply removed them). Add the ignore rule FIRST, then status resolves with zero risk.

Dotfiles source left with 2 uncommitted changes (settings.json.tmpl + .chezmoiignore) for user
review — not pushed.
