# Memory Index

## Environment & Configuration
- [Claude Config chezmoi Sync](claude-config-chezmoi-sync.md) — ~/.claude synced via chezmoi to private theduy3/dotfiles; edit→`chezmoi add`→push (settings.json is a .tmpl — edit source or hourly apply reverts it, incl. gsd-core installer writes)
- [Permission Rules: Edit() not Write()](claude-permission-edit-not-write.md) — `Write(path)` rules silently ignored by the matcher; the .env/secrets/.ssh denies were inert until 2026-07-16
- [Status Line & Hooks](statusline-and-hooks.md) - Status line setup, write hook whitelist
- [Commands & Hooks](commands-and-hooks.md) - 18 slash commands inventory, permission hook layer stack
- [ECC Cost-Warning Killswitch](ecc-cost-warning-killswitch.md) — `ECC_CONTEXT_MONITOR_COST_WARNINGS=off` silences $5/$10/$50 COST NOTICE prompts; user wants work done, not token-saving
- [Plugin Routing Priorities](plugin-routing-priorities.md) - GSD owns the loop; ECC+Superpowers = explicit leaf libraries; /s* REMOVED 2026-07-17. Canonical rule in ~/CLAUDE.md §Workflow Orchestration.
- [ECC Memory Graph Storage](ecc-memory-graph-storage.md) — knowledge graph lives in npx cache (fragile); markdown memory = source of truth, graph = derived view; re-seed if empty
- [EnterWorktree Busts Prompt Cache](enterworktree-busts-prompt-cache.md) — Enter/ExitWorktree regenerate CWD-dependent system-prompt sections → cache prefix bust; tool contract beats prose docs (verdict A not B)
- [Time Machine Interrupted Loop](timemachine-interrupted-loop.md) — TM "not backing up" = lost reference snapshot → deep-scan→interrupt loop on portable USB; fix = one uninterrupted `startbackup` + `caffeinate -dimsu` (2026-07-13)
- [Android Remote Access Stack](android-remote-access-stack.md) — Tailscale mesh + Terminus + herdr to reach bluehost/hostinger/mac from Pixel; node IPs, --ssh-off, mac socket-activated sshd (2026-07-13)
- [herdr Host = Hostinger](herdr-host-hostinger.md) — Hostinger is the always-on Claude+herdr box (6.9G free); Bluehost RAM-disqualified (990Mi, 4.5G swap at idle) — don't retry. herdr under systemd w/ 4G cgroup cap (2026-07-16)
- [Syncthing Vault Cluster](syncthing-vault-cluster.md) — Bluehost=24/7 master, 6 devices, theduyvault+wylios-vault; .stignore per-device gotcha, never sync .git, case conflicts, versioning now ON (2026-07-13)

## Active Projects
- [Task Queue](task-queue.md) — persistent cross-session task queue; scan Active section on session start, update on completion
- [Consolidation into /s*](consolidation-into-s-star.md) — RESOLVED opposite way: /s* suite deleted 2026-07-17, GSD sole loop owner. Harvested agents/skills survive. Historical record.
- [GSD Reinstalled Globally](gsd-reinstall-global.md) — `@opengsd/gsd-core` 1.4.4 `--claude --global` (2026-06-10); manifest-idempotent + chezmoi-ignore for agents; supersedes "GSD removed" claims
- [Sans Souci Ongles & Spa SEO](seo-sanssouci.md) — Wix nail salon, Laval QC. Phase 1 complete (35→55/100). Phase 2: /faq, /galerie, reviews, citations.
- [Remote Control Persistence](remote_control_persistence.md) — Android remote control: session persistence, permission model, ExitPlanMode still blocks (~10%)
- [Hermes Desktop → Remote VPS](hermes-desktop-remote.md) — MIGRATED 2026-06-19 to Bluehost root@129.121.100.233 (was Hostinger 147; Dokploy/Supabase stayed). "Hermes Agent.app" → gateway API 8642 (key /root/hermes/.desktop-api-key) via SSH tunnel. RAM-tight (3.8G+swap). zeus profile root:root perm bug RESOLVED 2026-06-20 (chown -R in volume; stale `docker logs --tail` trap).
- [Hermes Platform Topology](hermes-platform-topology.md) — `hermes`=Telegram (zeus+11, home chan 8446251233) / `hermes-wylios`=Discord (CEO-Wylios + 5 SalonX bots). Platform gate = bot-token presence, not config `enabled:`. zeus Telegram-only (no DISCORD_BOT_TOKEN). Per-profile gateway.pid is JSON; per-profile logs in profiles/<n>/logs/. Python tool-chain fix 2026-06-20: node/bin wrapper→venv python (terminal tool lacked pyyaml); `docker top` is the only reliable liveness check. +`wiki` librarian profile added 2026-06-21 (own TG bot 8821743046:, dump→/vault/Inbox→wiki-ingest→Notes; default wiki cron stays as nightly sweep).
- [Hermes-Wylios Config Regen](hermes-wylios-config-regen.md) — entrypoint.wylios.sh rewrites every profile's config.yaml from .env on each boot → `config.yaml`/`hermes config set` ephemeral; durable per-profile model lives in entrypoint PROFILE-MODEL-OVERRIDE block (3 Opus + 3 Sonnet, 2026-06-20). Only clean restart = `docker restart hermes-wylios`. All 6 share 1 anthropic OAuth cred. "out of extra usage" 400 = account extra-usage pool exhausted (claude.ai/settings/usage), NOT Discord/weekly-limit; model downgrade slows burn, doesn't unblock.
- [GSD Off-box Pipeline](gsd-offbox-pipeline.md) — LIVE: salonx-engineer builds off-box via GSD on GitHub Actions + headless Claude Code, Paperclip→repository_dispatch bridge, reuses approve→merge→deploy chassis. 2026-06-28: fixed the 100%-dead Discord PARK path w/ a sonnet pre-pass grey-area scan that parks BEFORE the 45m build. Runtime: GSD 45m; pre-PR verify slimmed (dropped dup `build`, ~12-15min recovered, b65cf49).
- [Hermes-Wylios Coding Pipeline](hermes-wylios-coding-pipeline.md) — autonomous s1→s9 coder: Discord brainstorm→Paperclip WYL issue→kanban→salonx-engineer→worktree PRs on Wylios-Dev/salonx→#product-dev forum→Discord approve. Driven by CODING-SOP.md (static volume file). Opened PR #653. CWD-ENOENT (os.getcwd FileNotFoundError, persistent_shell camping in GC'd scratch) was #1 failure → fixed 2026-06-20 w/ CWD-safety SOP section. Open: stalled wyl-15, gitnexus unindexed, gh missing.
- [Hermes Discord Role-Mention Drop](hermes-discord-role-mention.md) — bots silently drop owner `<@&role>` mentions (not in message.mentions); managed role undeletable; fixed via entrypoint boot auto-patch 2026-06-27
- [Paperclip Tunnel Topology](paperclip-tunnel-topology.md) — paperclip.salonxai.cloud split-brain: Traefik+TLS+basicAuth edge on Hostinger, origin (node :3100 in host-net hermes-wylios) on Bluehost, bridged by SSH tunnel `paperclip-tunnel.service`. 401=password, 502=tunnel/relay/origin. Fixed 2026-06-20 after hermes-wylios migration orphaned the route.
- [Hostinger Restic Backup](hostinger-restic-backup.md) — srv1300679 (147.93.116.94) restic→B2 hourly. 2026-07-05: `forget --prune` on restic 0.12.1 hung 37h on a B2 SYN-SENT stall, camped repo lock, failed every run (no data loss). Fixed: upgraded 0.12.1→0.19.1, split prune to daily+`timeout`, real `flock`, startup unlock. Diagnose "hung" restic via `ps time`(0)+`ss`(SYN-SENT).
- [Salonx Mirror for Personas](salonx-mirror-personas.md) — `/vault/repos/salonx-mirror` auto-synced to main every 10m (host systemd) gives read personas (Product-Lead) current merged code + `/vault/bin/gh`, fixing stale `~/.hermes/work/salonx` false-negatives. Agent uses ABSOLUTE paths (no entrypoint env). WARNING: editing `entrypoint.wylios.sh` with `mv` stripped `+x` → whole-fleet crash loop 2026-07-02.
- [Discord-Driven Pipeline](discord-driven-pipeline.md) — 3-plan redesign (task-runner loop + ship/stop poller + PL-bot critic gates) replacing monolithic gsd-runner. ALL 3 PLANS + BOTH GATES PROVEN LIVE (2026-07-12): spec→critic→approve→plan→critic→in_review all clean e2e. Plan-gate block root cause = stale persistSession (June-25 session resumed w/ old flow); fixed via reset-session + origin-not-mirror AGENTS.md rule + mandatory in_review disposition. Remaining: owner approve plan → `ship WYL-44` → task-runner build → §10 diff. Specs in ~/tasks/.

## Workflow Ownership
- [Spec-Plan-TDD Ownership](spec-plan-tdd-ownership.md) — human owns /spec+/plan (grilled, approve); Claude owns implement→gates→commit→PR→CI→merge autonomously, FULL AUTO-MERGE (no ping, all repos, decided 2026-07-17). As-built /tdd-gates hard-stops at green gates ("human ships") — that wall contradicts this; carry through to merge.

## Safety Rules
- [Worktree Branch Safety](feedback_worktree_branch_safety.md) - NEVER commit to main in a worktree; verify branch before any git write op
- [ExitPlanMode Hook](feedback_exitplanmode_hook.md) - ExitPlanMode cannot be auto-approved on Android: neither allow list nor hooks bypass requiresUserInteraction() interactive UI
- [Worktree CWD ENOENT](feedback_worktree_cwd_enoent.md) - Hooks failing with `posix_spawn '/bin/sh'` ENOENT = parent CWD unlinked after `git worktree remove`; restart required
- [1M Context Flag](feedback_1m_context_flag.md) - `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` in settings.json silently caps at 200K; check first when 1M model returns 200K
- [GSD Orphan Project Hooks Crash](gsd-orphan-project-hooks-crash.md) — dead project-local `hooks` block (GSD uninstall) crashes every event with MODULE_NOT_FOUND; `jq 'del(.hooks)'` main + worktree settings, global covers it
- [GSD Phase Worktree Guard](gsd-phase-worktree-guard.md) — global PreToolUse hook blocks main-checkout source writes while STATE.md `status: executing`; `GSD_ALLOW_INLINE=1` escape hatch for Pattern-C/gap-closure; self-disarms on status flip; wiring in settings.json.tmpl
- [Salonx Gates Local](salonx-gates-local.md) — `bun run gates` tier 4 locally: psql is keg-only libpq, 5432 taken → container on 55432; full recipe
- [Salonx Worktree Guard](salonx-worktree-guard.md) — hard PreToolUse hook blocks ALL Write/Edit into salonx MAIN checkout (no /s*-state gate); forces parallel sessions into worktrees; HEAD-collision incident RECOVERED 2026-07-03 (PRs #1049–#1052, zero loss) + salonx merge/CI ops notes; 73-spec audit 2026-07-03: ZERO wipe victims, only unmerged work = i18n Phase M (fr/vi/km) on translate-km branch (obsolete keyring, needs remap)

## User Preferences
- Terminal: Ghostty
- Package manager: `bun run` preferred for speed; `install` follows project lockfile (`package-lock.json` → npm, `bun.lock` → bun)
- Output style: learning mode
- Attribution: disabled globally
