---
name: hostinger-restic-backup
description: "srv1300679 (Hostinger 147.93.116.94) restic→B2 backup pipeline — design, the 2026-07-05 prune-hang incident, and the flock+split-prune fix"
metadata: 
  node_type: memory
  type: project
  originSessionId: 23e0d071-6855-44d7-9f64-6db9e9667f47
---

Hourly restic→Backblaze B2 backup on **srv1300679 / 147.93.116.94** (Hostinger VPS, the Dokploy/Supabase box — see [[hermes-desktop-remote]]). Backs up 6 Supabase tenant DBs (salon360qc, salon365, checkin, ss-website, ongles, demo) + Dokploy control DB + config dirs. Repo ~88 GiB. Scripts in `/root/supabase-setup/scripts/`, creds in `backup-env.sh` (Telegram alert channel: TELEGRAM_BOT_TOKEN/CHAT_ID). Logs: `/var/log/restic-backup.log`, `/var/log/restic-prune.log`.

**Root failure mode: restic ops wedge on stalled B2 TCP (socket stuck `SYN-SENT`, zero CPU).** Diagnose a "hung" restic by `ps -o time` (0 = waiting not working) + `ss -tnp | grep restic` (SYN-SENT = blackholed connection). Kill + `restic unlock` + retry usually clears it; B2 itself stays reachable (other ops succeed seconds later).

**2026-07-05 incident:** `restic forget --keep-* --prune` (restic **0.12.1**) hung **37h** on a B2 stall, holding the repo's exclusive lock → every hourly run failed at "repository is already locked". The forget *phase* completed (retention applied); only prune hung. No data loss (`restic check` clean, 76 snapshots). Old `/tmp/restic-backup.lock` guard was worthless — a plain `[ -f ]` test whose `cleanup()` did unconditional `rm -f`, so each failing run deleted the owner's lock.

**Fix applied (2026-07-05):**
- restic **0.12.1 → 0.19.1** (`restic self-update`; new prune far faster/robust).
- **Split prune off the hourly path:** `backup-b2.sh` hourly does backup + `restic forget` (metadata-only, NO --prune); new `prune-b2.sh` runs **daily 08:30 UTC** (cron), `restic prune` wrapped in `timeout 2h`.
- **Real `flock`** on `/var/lock/restic-b2.lock` (FD 9, `-n`) shared by both scripts → auto-releases on exit/kill, no stale locks, backup+prune never overlap.
- Defensive `restic unlock` (stale-only) at each script start.
- Originals backed up to `*.bak-<ts>` + `/root/crontab-backup-<ts>.txt`. Crontab marked `PROTECTED — Do NOT modify without explicit user command`.

**Ops notes:** my tools can't read `~/.ssh` (perm-walled) — user must supply SSH target. `restic snapshots --latest N` trailing "N snapshots" count is a display artifact; trust `restic check` ("X / X snapshots") or full `restic snapshots` for true count. Interrupted prune leaves non-critical "pack contained in several indexes" → `restic repair index` (but that too can SYN-SENT stall).
