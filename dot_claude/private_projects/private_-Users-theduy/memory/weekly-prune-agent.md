---
name: weekly-prune-agent
description: "Weekly cache-prune LaunchAgent (com.theduy.weekly-prune, Sun 11:00) — built 2026-08-15 because nothing on the Mac reclaimed cache; .cache/uv reached 36G because LIVE uvx MCP servers hold the cache lock for their whole session lifetime (they are NOT orphans — do not kill)"
metadata: 
  node_type: memory
  type: project
  originSessionId: b41c125a-2613-4b28-b22d-c48fa67d35d1
  modified: 2026-08-15T21:31:12.604Z
---

`~/.local/bin/weekly-prune.sh` + `~/Library/LaunchAgents/com.theduy.weekly-prune.plist`.
**Sunday 11:00**, `RunAtLoad=false`, no `KeepAlive`, nice 10, LowPriorityIO.
Log `~/.local/state/weekly-prune.log` (self-rotating at 1MB). Verified under launchd:
`runs=1, last exit code=0`, 11s. **Not chezmoi-managed** — local to the Mac by design
(brew/docker paths are Darwin-only). See [[claude-config-chezmoi-sync]].

## Why it exists

Four audits (2026-08-14/15) showed **every large disk win was a cache, and every deleted cache
came back**: `.cache/uv` 0→884M in six hours, `codex-runtimes` fully regrown after deletion.
Crontab had one entry (salonx DB sync); no LaunchAgent did maintenance. Manual cleanup could
never hold. See [[codex-claude-inventory-mirror]].

## 🔑 The real reason .cache/uv reached 36G

**Long-running `uv tool uvx ... serve` MCP servers hold an fd on `.cache/uv/.lock` for their
entire lifetime**, so `uv cache prune` can never succeed while any is alive — and during any
agent session, one always is. Observed 2026-08-15: four `code-review-graph serve` processes,
ages 21h–1d5h, ~21MB RSS total (the cost is the lock, not memory).

🛑 **They are NOT orphans — do NOT kill them.** I called them orphans from age alone; checking
`ppid` proved every parent alive: two live `claude` sessions (one `--model fable -r`, one
`bg-spare`) and two `bun @oh-my-pi/pi-coding-agent` sessions, each with a live child. **Age is
not evidence of abandonment.** Always check `ps -o pid,ppid` before calling a process orphaned.
Owner decision 2026-08-15: leave them running.

**This is why the cap matters more than the prune.** The polite path is permanently blocked in
practice; only `clean --force` past `UV_CACHE_CAP_MB` can reclaim. The 36G scenario is covered
either way. ⚠️ Untested: `clean --force` has never actually been executed against a held lock —
branch logic verified across 5 cases, real force-vs-live-lock is unproven.

## ✅ ROOT CAUSE FIXED at source 2026-08-15

`~/Repo/salonx/.mcp.json` ran code-review-graph as
`uvx --with sentence-transformers --with igraph code-review-graph serve`. **`uvx` builds an
EPHEMERAL env per invocation**, so every session opening salonx re-cached sentence-transformers +
torch — measured **~1 GB per new session** (884M→2948M in 19 min as holders went 4→6, then flat;
it is burst-per-session, NOT a steady rate). `uv tool list` was empty — nothing persistent.

Fix applied — reuse the **existing pipx install** rather than adding a second manager:
`pipx inject code-review-graph sentence-transformers igraph` (venv 441M → **1.1G**, one time),
then repoint `.mcp.json` at `/Users/theduy/.local/bin/code-review-graph` with
`"args":["serve"], "cwd":"/Users/theduy/Repo/salonx"` — the shape `~/Repo/SS-website/.mcp.json`
already used. **The correct pattern was already in the repo set; salonx was the outlier.**

- Verified: extras import (sentence_transformers 5.7.0, igraph 1.0.0, torch 2.13.0 — cp314 wheels
  exist, dry-run first); binary reads salonx's graph (23,008 nodes / 240,684 edges, rc=0); real MCP
  `initialize` handshake starts fastmcp on stdio, rc=0.
- `.mcp.json` is **gitignored via `.git/info/exclude`** → local-only, no repo/team impact. Backup at
  `.mcp.json.pre-persistent-<ts>`. The salonx worktree guard did NOT block this edit.
- ⚠️ Already-running uvx servers keep their lock until those sessions end; only NEW sessions pick up
  the persistent binary.
- ⚠️ `~/Repo/SS-website/.mcp.json` omits the extras entirely — if that repo ever needs embeddings
  it will behave differently from salonx. Not touched.

## Design decisions (each one cost a failed test)

- **`uv cache prune` alone is useless here.** It only drops *unreachable* objects; 860M of the
  884M sat in `archive-v0`, all reachable. Prune would never have capped growth. Hence a
  **size cap: `UV_CACHE_CAP_MB=5120`** (env-overridable) → past it, `uv cache clean --force`.
  Force ignores the in-use check; accepted tradeoff, since uvx servers restart every session
  but an unbounded cache hit 36G once.
- **`UV_LOCK_TIMEOUT=60`** (default 300). The first test stalled a full 5 minutes on the lock
  before erroring, blocking every later step. Now it checks `pgrep` for holders and skips fast:
  runtime went 5min → 2.5s.
- **macOS has NO `flock(1)`** — util-linux only, and brew coreutils does not supply it. The
  first version used it and would have **silently no-opped forever**: under `set -u` the failed
  `flock` made the guard true, so it logged "another run holds the lock" and exited 0 looking
  healthy. Replaced with an atomic `mkdir` lock + 120-min stale reclaim + EXIT trap.
- **No `rm -rf` anywhere** — removal is delegated to each tool's own prune subcommand (also
  keeps it clear of the `Bash(rm -rf *)` deny, see [[claude-permission-edit-not-write]]).
- `docker image prune -f` **not** `-a` (would force multi-GB re-pulls); skipped entirely unless
  the daemon is already up — never start Docker to prune it.
- **Deliberately NOT pruned:** `codex-runtimes` (1.5G but the Codex app re-downloads it — churn,
  not savings), `~/.npm/_cacache` (real install speedup), Docker volumes (may hold local DB state).

## How to apply

- Check it is working: `grep '^2' ~/.local/state/weekly-prune.log | tail -20`.
- A run logging "N uv process(es) hold the cache lock — skipping prune" is the **normal steady
  state**, not a failure. Expect it on most weeks. The cap is what protects the disk; the prune
  is a bonus that only lands when no agent session is open.
- Test the over-cap path without waiting: `UV_CACHE_CAP_MB=1 bash ~/.local/bin/weekly-prune.sh`
  — ⚠️ this really does force-clean the cache.
