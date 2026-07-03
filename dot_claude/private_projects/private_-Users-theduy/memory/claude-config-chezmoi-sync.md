---
name: claude-config-chezmoi-sync
description: ~/.claude global config is synced via chezmoi to private repo theduy3/dotfiles
metadata: 
  node_type: memory
  type: project
  originSessionId: c5b1847c-8c65-4b25-91a5-c49aadbf78be
---

`~/.claude` config is version-controlled with **chezmoi** (source at `~/.local/share/chezmoi`, branch `main`) and pushed to private GitHub repo **theduy3/dotfiles**. Set up 2026-05-23.

**Scope synced:** CLAUDE.md, RTK.md, settings.json (as `settings.json.tmpl`), statusline.sh, rules/, commands/, hooks/, agents/, skills/ source. **Excluded** via `.chezmoiignore`: `.credentials.json` (OAuth — auth per-machine), skill venvs/node_modules/__pycache__, 9 externally-symlinked skills, all heavy/transient dirs (projects/, plugins/).

**Two files are chezmoi templates** using `{{ .chezmoi.homeDir }}` (so they port to the Linux VPS): `settings.json.tmpl` (statusline path) and `hooks/gitnexus/gitnexus-hook.cjs.tmpl` (npm-global cliPath).

**How to apply:** To change global config, edit the live file then `chezmoi add ~/.claude/<file>` → `chezmoi cd` → commit → push. Or `chezmoi edit ~/.claude/<file>` → `chezmoi apply`. On another machine: `chezmoi update` (= git pull + apply). New machine bootstrap: `chezmoi init --apply git@github.com:theduy3/dotfiles.git`.

**Note:** old in-place `~/.claude/.git` was retired (chezmoi is sole VCS).

**⚠️ settings.json is a TEMPLATE — live edits revert.** The push job runs `chezmoi apply --force` hourly, which regenerates `~/.claude/settings.json` FROM `dot_claude/settings.json.tmpl`. `chezmoi re-add` does NOT pull edits back into templates. So editing live settings.json alone gets reverted within the hour. **Must edit `~/.local/share/chezmoi/dot_claude/settings.json.tmpl` too**, then verify `chezmoi diff ~/.claude/settings.json` is empty before relying on it.

**Plugin self-heal (added 2026-06-04):** After a Claude Code reinstall, `~/.claude/plugins/installed_plugins.json` empties + cache dirs wipe, but `enabledPlugins` in settings.json persists → plugins with PostToolUse hooks throw "Plugin directory does not exist". Fix: `~/.local/bin/claude-plugins-reconcile.sh` (synced) reads `enabledPlugins`, reinstalls any whose cache dir is missing. Marketplaces self-restore from `extraKnownMarketplaces` in settings.json — every needed marketplace MUST be listed there (incl. `thedotmack` for claude-mem, `everything-claude-code`→self-registers as `ecc`). Gotcha: marketplace/plugin names drift on rename — `everything-claude-code@everything-claude-code` became `ecc@ecc`. Don't back up installed_plugins.json alone — it records install paths w/o the cache dirs, so restoring it reproduces the error.

**Auto-sync (added 2026-05-23):** Mac-authoritative → VPS read-only replica. One shared script `~/.local/bin/claude-sync.sh` (synced via chezmoi, `private_dot_local/bin/executable_claude-sync.sh`) driven by per-machine role file `~/.config/claude-sync/role` (`push`=Mac, `pull`=VPS, default `pull`). Mac: launchd `~/Library/LaunchAgents/com.theduy.claude-sync.plist` hourly → re-add+commit+pull--rebase+push+apply. VPS: cron hourly → `chezmoi update --force`. Never force-pushes, conflict→abort+alert. Telegram alerts on failure via `~/.config/claude-sync/telegram.env` (chmod 600, NOT synced; `.config/claude-sync` + `Library/LaunchAgents` are in `.chezmoiignore`). VPS auth = read-only SSH deploy key via `github-dotfiles` ssh host alias. Logs: `~/.claude-sync.log`.
