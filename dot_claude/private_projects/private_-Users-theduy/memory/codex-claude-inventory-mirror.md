---
name: codex-claude-inventory-mirror
description: "Codex CLI removed 2026-08-12 and replaced by OMP (@oh-my-pi), which is a Codex-PROTOCOL client — ~/.codex is live state, not residue. ~/.agents/skills is now chezmoi-synced to all 3 boxes."
metadata: 
  node_type: memory
  type: project
  modified: 2026-08-15T20:38:29.367Z
  originSessionId: af9594d9-ef17-4ac2-a3fd-a86b11e205c6
---

## Superseded: the Codex CLI is gone (2026-08-12)

`@openai/codex` (262M) and `oh-my-codex`/`omx` are uninstalled; `codex` and `omx` no longer
resolve. The old `~/.codex/sync-claude-inventory.sh` copier and its `dot_codex` chezmoi entry are
removed. **Ignore any earlier instruction to re-run that sync script.**

🔥 **`~/.codex` is NOT dead — do not delete it.** OMP is a **Codex-protocol client**: its bundle
carries `codex:{userBase:".codex",userAgent:".codex"}`, walks `[".claude",".codex",".gemini"]` as
agent dirs, has a `source="codex"` class defaulting to `~/.codex`, and reads `CODEX_HOME` /
`CODEX_OAUTH_TOKEN` / `CODEX_WEBSOCKET`. It writes live sqlite state there
(`goals_1`, `memories_1`, `queue_1`, `state_5` + WALs, `thread-writer-locks`) plus a trust entry
for `~/Repo/salonx` in `config.toml`. **Near-miss 2026-08-12:** `.codex` was briefly listed in
`.chezmoiremove` — which deletes on *every* device — and the Mac's `claude-sync` LaunchAgent applies
hourly. Caught before any apply ran. Sessions (234M/141 files) archived at
`~/codex-sessions-archive-20260812`; **the sqlite DBs were never archived.**

## Current agent stack (Mac)

- **`claude`** — `~/.claude/skills` (111 symlinks → `.agents` + real dirs)
- **`pi`** `@earendil-works/pi-coding-agent` 0.84.1 — loads `~/.agents/skills` natively
- **`omp`** `@oh-my-pi/pi-coding-agent` 17.2.15 — loader registered as *"Load skills from
  .agent/skills and .agents/skills (project walk-up + user home)"*. Runs via **bunx**, not the
  npm-global copy. Config `~/.omp/agent/config.yml`, default role `openai-codex/gpt-5.6-sol`.
- **`codex-router`** — 🛑 **DISABLED 2026-08-15 by owner decision ("i don't need the router").**
  Disabled with its own `./bin/disable` → `config-manager disable` + `service.mjs uninstall`: plist
  removed from `~/Library/LaunchAgents`, launchd unregistered, :4100–4103 free, no stray processes.
  Plist is **not chezmoi-managed**, so the hourly `claude-sync` will not restore it. Codex routing
  stayed `native` (it had never been enabled). **Then fully DELETED 2026-08-15:**
  `~/.local/share/codex-router` (526M, 502M of it a rebuildable LiteLLM `.venv`) and the orphaned
  state dir (6.8M — stale `internal-secret`/`caller-secret` + 6.2M crash log) = **533M**. Git tree
  was clean, 0 unpushed commits, remote live. Reverse = reclone
  `github.com/duolahypercho/codex-router` + `./bin/install`. Only remnant left behind:
  `<CODEX_HOME>/config.toml.pre-codex-router`.
  ❌ **The old "load-bearing for OMP's default model role" claim was WRONG — do not reinstate it.**
  Verified 2026-08-15 before disabling: OMP's `~/.omp/agent/config.yml` default role is
  `anthropic/claude-opus-5`, fallback chains are `xai-oauth/*` + `deepseek/*` — all direct provider
  routes. Neither `~/.codex/config.toml` nor orca's `config.toml` referenced the router, and it had
  **zero providers configured**. Only :4100–4103 hits on disk were historical OMP session
  transcripts — which is probably what created the false impression.
  ⚠️ **Kept for reference — rebuilding orca's `codex-runtime-home` silently orphans the router.** The
  plist pins `MODEL_ROUTER_STATE_DIR` to
  `~/Library/Application Support/orca/codex-runtime-home/home/codex-router`. When orca recreated that
  home on 2026-08-13 the state dir came back **empty** — no generated `internal-secret` /
  `caller-secret` — so `src/start.mjs:34` threw `Internal service key is missing` on every launch.
  With `KeepAlive` + 10s `ThrottleInterval` it respawned **11,616 times (~32h)**, silent except a
  6.2M `router.log`. **launchd reports this as a healthy-looking agent** — only `last exit code = 1`
  in `launchctl print` reveals it.
  **Repair:** export the plist's env (`CODEX_HOME`, `MODEL_ROUTER_STATE_DIR`, the four ports), then
  `cd ~/.local/share/codex-router && ./bin/install --prepare-only` → regenerates secrets,
  `litellm.yaml`, catalogs; then `launchctl bootout` + `bootstrap`.
  **Use `--prepare-only`, NOT `./bin/doctor --fix`** — the latter is `bin/install --force-deps`,
  which forces `npm ci` *and* a fresh `uv pip install litellm`, repopulating the uv cache
  (see [[claude-minimal-s-runtime]]). Plain `bin/install` also refuses to run while
  **no provider credential is configured**, which is the state this box is in — the router serves
  loopback health but has zero upstream routes until `./bin/setup --guided` + `./bin/enable`.

**All three agents read `~/.agents/skills`.** It is a de-facto cross-vendor standard (Codex, Pi, and
OMP each implemented it independently), so it is the correct sync unit — one path serves every agent.

## ~/.agents/skills is now chezmoi-managed (2026-08-12)

Source `dot_agents/`, 145 skills / ~939 managed entries / 6.4M. Was **146 Mac vs 2 Hostinger vs 8
Bluehost**; now 146 / 145 / 151 (Bluehost keeps 6 local extras — `caveman`, `context-canary`,
`fuck-slop`, `interface-kit`, `junior-to-senior`, `loop-factory` — worth pulling back to the Mac).

- **`.agents/skills/cua-driver` is `.chezmoiignore`d** — the only symlink in the tree
  (→ `/Applications/CuaDriver.app`); it would dangle on Linux. Verified 0 dangling links on all boxes.
- ⚠️ **chezmoi is push-on-add.** `chezmoi re-add` in `claude-sync.sh` only refreshes *already
  managed* files — a brand-new skill dropped into `~/.agents/skills` still needs an explicit
  `chezmoi add`.

## Why Bluehost had never synced once

`claude-sync.sh` **overwrites** `PATH` at line 9 (so exporting a PATH before calling it does
nothing). Bluehost installs chezmoi to **`/root/bin/chezmoi`**, absent from that hardcoded list, so
the `command -v chezmoi` guard aborted every run — zero log entries, ever. Fixed two ways:
`$HOME/bin` added to the script's PATH (propagates to all boxes), plus a
`/root/.local/bin/chezmoi → /root/bin/chezmoi` symlink on Bluehost as a bootstrap and safety net.
Bluehost also had **no cron at all**; now `0 * * * * /root/.local/bin/claude-sync.sh` with
`role=pull`, matching Hostinger. Related: [[hostinger-gsd-runtime-live]],
[[claude-config-chezmoi-sync]].
