---
name: hermes-platform-topology
description: "Which Hermes container serves which chat platform, the profiles in each, and how platform activation is gated (bot-token presence, not a config flag)"
metadata: 
  node_type: memory
  type: project
  originSessionId: a0db6fb1-f1de-465d-bf25-6edf0df11848
---

Bluehost VPS (`root@129.121.100.233`, see [[hermes-desktop-remote]]) runs **two separate Hermes compose projects, split by chat platform.** Each runs many *profiles*; per profile there are two processes — a `bash entrypoint.sh gateway run` supervisor + a `python hermes gateway run` child.

**`/root/hermes` container = `hermes` = TELEGRAM** (model **gpt-5.5**). **8 profiles, all gateway running:** default, butter, catthew, charles, finance, thor, **zeus**, **wiki**. zeus = the personal assistant; home channel `8446251233` = theduy's Telegram DM. zeus is **Telegram-only** and connected/live.

**`wiki` profile (added 2026-06-21) = theduyvault librarian.** Own Telegram bot (token prefix `8821743046:`), reuses zeus's `TELEGRAM_ALLOWED_USERS` (same person). Job: dump anything (text/link/photo/PDF/voice) → it captures to `/vault/Inbox/` → runs the **`wiki-ingest`** skill (vision-OCR, dedup via `rg`, atomic typed notes into `/vault/Notes/`, archive `Sources/`, update `MOCs/`+`System/wiki-index.md`) → replies a summary. Built by cloning the zeus profile pattern: `profiles/wiki/` = default `config.yaml` (gpt-5.5/codex, shared `auth.json` symlink → codex OAuth pool), `.env` (token+approval=auto), `SOUL.md` (librarian persona), copied `skills/{wiki-ingest,wiki-lint}`. **Decision: default-profile nightly `wiki-ingest`/`wiki-lint` cron stays as-is = background safety sweep; wiki = interactive front door (no rip-out).** "embed" half is downstream — qmd on the Mac indexes the markdown after sync (no qmd on the box; ingest dedup uses `rg`). **Video links capped (2026-06-21): metadata+transcript only via `yt-dlp --skip-download --write-auto-subs/--write-subs --convert-subs srt`; NEVER keep `.mp4`/audio (box RAM/disk tight) — rule lives in `profiles/wiki/SOUL.md`.** Verified live: FB video link → downloaded+synthesized note `Notes/Social Media Agency Content Operations.md` (cross-linked, frontmatter), Sources/ root-owned → Notes/ archive fallback fired. Reload SOUL without fleet bounce = `kill` the pid in `profiles/wiki/gateway.pid`; supervisor revives in ~2s.

**`/root/hermes-wylios` container = `hermes-wylios` = DISCORD** (model **claude-opus-4-8**; `default` profile stopped). 6 profiles, all connected:
- `wylios-ceo` → **CEO-Wylios#6145**
- `salonx-engineer` → Engineer-SalonX#2400
- `salonx-gtm` → GTM-Lead-SalonX#8047
- `salonx-product` → Product-Lead-SalonX#6933
- `salonx-research` → Market-Research-SalonX#0568
- `salonx-sales` → Sales-Rep-SalonX#7877

**Platform activation gate = BOT-TOKEN PRESENCE, not a config `enabled:` flag.** The `discord:`/`telegram:`/`whatsapp:`/`mattermost:` blocks in a profile's `config.yaml` are *behavior settings only* (require_mention, channels, threads) — there is **no `enabled:` key**. A platform starts iff its bot token exists. zeus has `TELEGRAM_BOT_TOKEN` in `profiles/zeus/.env` but **no `DISCORD_BOT_TOKEN`** (not in profile `.env` nor global `.hermes/.env`), so Discord structurally cannot start (`[Discord] No bot token configured` → auto-pauses after 10 fails; pause persists across reboots). To give zeus Discord you'd add a `DISCORD_BOT_TOKEN` + `/platform resume discord` (or gateway restart) — confirmed 2026-06-20 that this is intentionally off.

**Ops cheats:**
- Per-profile gateway PID: `profiles/<name>/gateway.pid` is **JSON** `{"pid": N, "kind": "hermes-gateway", …}` — extract `.pid`, don't pass the whole blob to `kill -0` (false "DEAD").
- Per-profile logs live in `profiles/<name>/logs/gateway.log` (connect events, traffic); container stdout (`docker logs <container>`) only carries the **global entrypoint** output (e.g. the `ln -sf` symlink step), not per-profile platform events.
- `config.yaml` is **Hermes-managed** (auto-backups, regenerates platform stubs) — manual edits to it may be overwritten; prefer `.env`/CLI over hand-editing.
- **`docker top <container> -eo pid,etimes,args` is the ONLY reliable liveness check.** Burned ~7× this session by shorthand: JSON `gateway.pid`→`kill -0`, bare `grep "hermes gateway run"` (wylios uses `hermes -p <profile> gateway run`, profile sits between), `docker top -eo args` (bare col), and `awk "/HH:MM/"` anchors that miss when the event is at a different minute. `docker logs --tail N` on a quiet container also lies (reaches hours back) — use `-t` timestamps vs `.State.StartedAt`.
- **Re-trigger a cron job:** `hermes -p <profile> cron run <job-id>` (fires on the running gateway's next tick — coordinates via shared `jobs.json`, no rival scheduler). Status in `cron/jobs.json`: `last_status` / `last_error` / **`last_delivery_error`** (None = delivered) / `deliver`. Cron runs log to `cron/output/<hash>/<ts>.md` (25 KB briefing archive), NOT the interactive `inbound→response` lines in gateway.log.

**Python tool-chain fix (RESOLVED 2026-06-20 — migration scar):** The agent's `terminal` tool shells out with the container PATH (`.hermes/node/bin` first, NO venv), so `python3` hit **system `/usr/bin/python3` 3.12 which lacks `pyyaml`** (`ModuleNotFoundError: No module named 'yaml'`) and bare `python` didn't exist → the **Daily Evening Briefing** (job `b83af24484d0`) silently failed when parsing Obsidian task YAML frontmatter. The gateway's own venv (`/home/hermes/.hermes/hermes-agent/venv/bin/python3`) HAS pyyaml 6.0.3 — that's why the bot itself worked. **Fix = wrapper scripts** (NOT symlinks) at `/home/hermes/.hermes/node/bin/{python,python3}`:
```sh
#!/bin/sh
exec /home/hermes/.hermes/hermes-agent/venv/bin/python3 "$@"
```
- **Why a plain symlink FAILS:** a venv python invoked through an out-of-venv symlink resolves down to the base interpreter, finds no `pyvenv.cfg` adjacent → loads base site-packages → no pyyaml. The wrapper `exec`s the **absolute venv path**, so the invocation dir is inside the venv → `pyvenv.cfg` found → venv site-packages load. Verified: via wrapper, `python3 -c "import yaml,sys;print(yaml.__version__,sys.prefix)"` → `6.0.3 …/venv`.
- **Why `node/bin`:** it's FIRST on PATH **and** inside the `hermes_hermes-data` volume → durable across `docker compose up --force-recreate`, no container restart/blip needed. Create as the `hermes` user (uid 1500) so wrappers stay `hermes:hermes`.
- If a future briefing/task throws `ModuleNotFoundError`, the venv lacks that dep (not the wrappers) — `…/venv/bin/python3 -m pip install <pkg>` into the venv.

**Host CLI shortcuts (added 2026-06-20):** On the Bluehost host as root, `hermes` and `wylios` are pass-through wrapper scripts at `/usr/local/bin/{hermes,wylios}` → `exec docker exec -it <container> /home/hermes/.local/bin/hermes "$@"` (TTY-aware: `-it` on a terminal, else `-i`). So `hermes profile list`, `hermes -p zeus chat`, `hermes -p zeus cron list`, `wylios -p wylios-ceo chat`, etc. all work from the host. They target containers by NAME → survive reboots and `docker compose` recreates. Bare `hermes`/`wylios` = interactive chat with that container's `default` profile. (This is the answer to "typing hermes/wylios gives command not found" — they were never host commands; now they are.)
