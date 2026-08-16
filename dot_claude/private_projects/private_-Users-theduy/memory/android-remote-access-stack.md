---
name: android-remote-access-stack
description: "Android→boxes remote dev stack — Tailscale mesh + Terminus SSH + herdr agent multiplexer; node IPs, --ssh-off decision, mac socket-activated sshd"
metadata: 
  node_type: memory
  type: project
  originSessionId: d42cc217-dd7f-4491-a398-76e44a4a1080
---

Set up 2026-07-13. Access Claude Code / shells on all boxes from Android (Pixel) via a 3-app stack: **Tailscale** (mesh VPN), **Terminus** (Android SSH client), **herdr** (agent multiplexer — persistent terminals that keep coding agents alive across SSH drops; https://herdr.dev, binary not an app, no account/telemetry).

## Tailnet (account duynt1989@, one tailnet)
- `bluehost`  100.105.247.34 — Bluehost VPS root@129.121.100.233 (hal-server-803171.novalocal). herdr 0.7.3. always-on.
- `hostinger` 100.113.169.110 — Hostinger srv1300679 root@147.93.116.94. herdr 0.7.3. always-on.
- `macbook-air-m4` 100.124.215.56 — this Mac, user theduy. herdr present. reachable ONLY while awake.
- `pixel-10` 100.123.143.86 — Android client.
- `macbook-air-m4-1` 100.67.159.28 — STALE duplicate Mac node; delete in admin console.

## Key decisions / gotchas
- **Tailscale SSH (`--ssh`) DISABLED on both VPSes** (`tailscale set --ssh=false`). With it on, tailscaled hijacks tailnet port 22 with identity/ACL auth in "check" mode → hangs normal clients. Off = plain OpenSSH + your keys falls through. Terminus uses key auth.
- **Mac needed Remote Login ON** (System Settings→Sharing). Fresh mac ships sshd off; tailnet delivers packets but nothing listens. sshd is **socket-activated by launchd** → `launchctl print system/com.openssh.sshd` shows `state = not running` when idle even though it works; don't treat that as broken.
- Headless `tailscale up`: background with `setsid ... </dev/null &` (plain `nohup &` got reaped when SSH session closed, node registered admin-side but daemon stuck NeedsLogin). Read auth URL from log, user clicks.
- Auto-mode classifier blocks SSH state-writes to prod VPSes even when user-approved → user runs them via `!` prefix.

## herdr usage (from phone)
SSH in → `cd <project>` → `herdr` (attaches persistent default session) → run `claude`. Detach `ctrl+b` then `q` (or close terminal) — agent survives. Reattach: `herdr`. Stop server: `herdr server stop`. Better state detection: `herdr integration install claude`. Agent-facing docs: https://herdr.dev/agent-guide.md ; skill https://raw.githubusercontent.com/ogulcancelik/herdr/master/SKILL.md.

## Status: COMPLETE (2026-07-13)
- MagicDNS enabled → hosts reachable by name. Stale macbook-air-m4-1 deleted.
- Terminus Ed25519 key `pixel` generated; pubkey installed in authorized_keys on bluehost, hostinger, mac. All three connect from Pixel by name + key auth.
