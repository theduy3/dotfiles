---
name: paperclip-tunnel-topology
description: "Paperclip control-plane is split-brain — Traefik edge on Hostinger, origin on Bluehost, bridged by SSH tunnel. How to debug 401/502."
metadata: 
  node_type: memory
  type: project
  originSessionId: 3835b42d-9861-4e1c-af79-ed008c6ab39c
---

Paperclip (Wylios company-ops control plane, `paperclip.salonxai.cloud`) is **split across two hosts** since the [[hermes-desktop-remote]] / hermes-wylios migration to Bluehost (2026-06-19):

- **Edge (Hostinger 147.93.116.94):** Traefik terminates TLS (Let's Encrypt) + basicAuth + Host allowlist. DNS (`dns-parking.com` = Hostinger NS) points `paperclip.salonxai.cloud` → 147.93.116.94. Router file = `/etc/dokploy/traefik/dynamic/paperclip.yml` (file-provider, hand-written, NOT a Dokploy app). basicAuth user `admin`, htpasswd apr1.
- **Origin (Bluehost 129.121.100.233):** paperclip = `node` proc inside `hermes-wylios` container, `network_mode: host`, bound `127.0.0.1:3100` loopback-only, **no published port**.
- **Bridge:** Hostinger `paperclip.yml` → socat `paperclip-relay.service` (`172.17.0.1:3190` → `127.0.0.1:3100`) → **SSH tunnel `paperclip-tunnel.service`** (Hostinger systemd, `ssh -N -L 127.0.0.1:3100:127.0.0.1:3100 root@bluehost`, Restart=always, enabled). Tunnel key on Bluehost authorized_keys is **forward-only hardened**: `command="/bin/false",restrict,port-forwarding,permitopen="127.0.0.1:3100"` — no shell.

**Debug map:**
- Public **401** = basicAuth (wrong/rotated password) — backend IS reachable. Hash one-way; reset via `openssl passwd -apr1` into `paperclip.yml`, Traefik hot-reloads.
- Public **502 / empty** = backend path dead. Check in order: `systemctl is-active paperclip-tunnel.service` (Hostinger) → `paperclip-relay.service` (Hostinger socat) → on Bluehost `curl 127.0.0.1:3100` (paperclip node alive inside host-net hermes-wylios).
- **Why:** Traefik file-provider routers survive container migrations verbatim — edge stayed Hostinger when origin moved Bluehost. `restrict` alone does NOT block ssh exec; needs forced `command=`.

Fixed 2026-06-20. Tunnel is the load-bearing link — if paperclip 502s, suspect it first.
