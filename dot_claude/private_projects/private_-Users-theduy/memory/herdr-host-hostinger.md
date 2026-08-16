---
name: herdr-host-hostinger
description: Hostinger (not Bluehost) is the always-on Claude Code + herdr host; Bluehost is RAM-disqualified. herdr runs under systemd with a 4G cgroup cap.
metadata: 
  node_type: memory
  type: project
  originSessionId: 59f34656-b14a-4648-a90e-3466bb6dc767
---

**Hostinger `147.93.116.94` / tailscale `100.113.169.110` is the always-on Claude Code + herdr host** (set up 2026-07-16). Reach it from the Pixel via Termius over Tailscale → SSH → `herdr session attach`.

**Bluehost is disqualified for this, permanently — don't retry it.** Measured 2026-07-16: 2 vCPU / 3.8G RAM / **990Mi available** / already **4.5G into 8G swap at idle**. One Claude session measures 400–725MB RSS and the MCP stack costs ~1G before Claude starts. Adding herdr there means swap thrash and the OOM killer reaping the hermes fleet. Hostinger: 4 vCPU / 15G / **6.9G available** — 7x the headroom. See [[hermes-desktop-remote]] for what Bluehost must keep running.

**herdr runs under systemd** — `/etc/systemd/system/herdr.service`, `ExecStart=/root/.local/bin/herdr server` (the headless-server subcommand), `MemoryMax=4G` + `MemoryHigh=3G`. The cgroup bounds herdr **and every Claude session it spawns** (verified: a herdr-spawned `claude` pid lands in `/system.slice/herdr.service`), so a runaway 1M-context session is killed inside its own cgroup instead of reaping the box's production Dokploy/Supabase containers. **Never start `herdr server` by hand** — it lands in `user.slice/user-0.slice/session-*.scope`, outside the cap, and its socket then blocks the systemd unit (`error: herdr server is already running`). Stop strays with `herdr server stop`, then `systemctl start herdr`.

**Gotchas hit:**
- `pgrep -f "herdr server"` / `pgrep -f claude` match your own bash command line — false positives. Use `pgrep -x herdr` or grep the executable path.
- Substring collisions are real: `gsd-worktree-path-guard.js` **contains** `worktree-path-guard.js`. Anchor on `/<name>` when testing whether a hook is wired.
- Linux `settings.json` is chezmoi-ignored by design, so guards added via the template **never reach the VPS**. Hostinger's guards were wired by hand and persist for that same reason. See [[claude-config-chezmoi-sync]].

**How to apply:** for anything needing an always-on Claude, target Hostinger. Verify the cap survived with `cat /sys/fs/cgroup/system.slice/herdr.service/memory.max` (expect `4294967296`), not just `systemctl show`.

**Known unrelated noise on Hostinger:** several Dokploy swarm services (`app-transmit-*`, `app-program-back-end-*`, `salon360qc-app-*`) flap roughly hourly with `RestartPolicy {Condition: any, MaxAttempts: 0}`. Pre-dates the herdr work, no OOM involved — don't misread it as memory pressure.
