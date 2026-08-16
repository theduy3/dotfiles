---
name: claude-plugins-not-chezmoi-synced
description: "~/.claude/plugins (marketplace/npx plugins) is NOT chezmoi-tracked — reinstall on new boxes via the bootstrap script, don't try to sync"
metadata: 
  node_type: memory
  type: project
  originSessionId: ae4004d0-30e7-4aae-b1ef-538568714cf0
  modified: 2026-07-21T20:11:10.034Z
---

chezmoi tracks `~/.claude/skills/*` (real dirs) and `~/.agents/skills/` (64 entries),
but **`~/.claude/plugins/` has 0 chezmoi-managed files** — verified 2026-07-19 via
`chezmoi managed | grep -c .claude/plugins` → 0. So marketplace/npx-installed plugins
(ecc, superpowers, caveman, claude-mem, gsd, obsidian, last30days, ponytail, …) do NOT
git-sync to the Hostinger VPS. They must be **reinstalled**, not synced.

Two gotchas beyond plugins:
- **chezmoi is not a live mirror.** A skill dropped into `~/.claude/skills/` by an npx
  installer stays UNTRACKED until you `chezmoi add` it — e.g. the 48 `gsd-*` skill dirs
  are present on disk but untracked (GSD is deliberately `.chezmoiignore`'d as npx-regenerable).
- **Syncing SKILL.md ≠ syncing runtime.** A synced skill still needs its MCP server /
  npx binary / python venv present on the target (hence the `**/.venv`, `**/node_modules`
  ignores).

## The fix: `~/vps-bootstrap-claude-plugins.sh`
Self-contained bootstrap, chezmoi-tracked (source `executable_vps-bootstrap-claude-plugins.sh`,
theduy3/dotfiles, latest f51f560). Embeds a SNAPSHOT (2026-07-19) of 13 marketplaces +
20 user plugins + 5 disabled-state restores; gates on Node>=18 (nvm auto, or
`AUTO_INSTALL_NODE=1` → NodeSource apt/dnf/yum); reinstalls GSD via npx. Idempotent.

**Proven live on Hostinger VPS 2026-07-21**: Node auto-check passed (v25.8.1), 9 marketplaces
cloned, 8 plugins installed, disables restored, GSD 1.7.0. One failure — `ecc@ecc`.
ROOT CAUSE = marketplace NAME DRIFT, not stale cache: upstream affaan-m/everything-claude-code
now declares manifest `name: ecc` (so snapshot `ecc@ecc` is CORRECT), but the VPS had registered
that repo LONG AGO under its old name `everything-claude-code`. `marketplace add <repo>` on a
same-repo copy = no-op ("already on disk"), never renames → `marketplace update ecc` fails
("not found"; registered name is everything-claude-code) and `ecc@ecc` can't resolve.
Idempotency has 3 layers: presence, currency (cache fresh), IDENTITY (registered under the name
your ids expect). The `install_plugin()` self-heal (commit f51f560) fixes currency only.
Name-drift fix is manual + one-time (documented in script's run-time NOTE):
  claude plugin marketplace remove everything-claude-code
  claude plugin marketplace add affaan-m/everything-claude-code   # re-registers as 'ecc'
  claude plugin install ecc@ecc --scope user

Deploy on a fresh box:
```
chezmoi update
AUTO_INSTALL_NODE=1 bash ~/vps-bootstrap-claude-plugins.sh
# then restart Claude Code (plugins load at startup)
```
Refresh the embedded snapshot when the plugin set changes — jq regen one-liners are in the
script header (over `known_marketplaces.json` + `installed_plugins.json`).

Uses the `claude plugin` CLI: `marketplace add <owner/repo>`, `install <plugin>@<mkt> --scope user`,
`disable <plugin>`. Project-scoped plugins (e.g. `social-media-skills` → a Mac repo path) are
skipped — re-scope per repo on the VPS.

Related: [[claude-config-chezmoi-sync]], [[gsd-reinstall-global]].
