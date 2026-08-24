---
name: remarkable-paper-pro-ssh
description: "reMarkable Paper Pro SSH access — one `rmpp` alias over Wi-Fi/hotspot/USB via ~/bin/rmpp-connect; no mDNS, dropbear fingerprint, ~/.ssh denied to Claude tools"
metadata: 
  node_type: memory
  type: project
  originSessionId: 15941084-592b-4f2b-85e7-b383a2533440
  modified: 2026-08-24T16:51:50.645Z
---

reMarkable Paper Pro quick-access set up 2026-08-24. One alias `rmpp` resolves
the tablet across home Wi-Fi, phone hotspot, and USB.

- Finder: `~/bin/rmpp-connect` (ProxyCommand). Order: `RMPP_HOST` env → USB
  `10.11.99.1` → cached IP (`~/.cache/rmpp-ip`) → sweep every local /24 for a
  dropbear banner. `--where` prints the resolved IP, `--selftest` asserts.
- Config: `~/.config/rmpp/ssh.conf`, pulled in by one `Include` line at the TOP
  of `~/.ssh/config` (ssh_config is first-value-wins — below a `Host *` block it
  gets shadowed).
- **The tablet publishes no mDNS.** `remarkable.local` never resolves; every
  guide that uses a hostname is wrong for this device. Discovery must be by IP.
- Fingerprint is `SSH-2.0-dropbear_2025.88` plus a pre-auth `unlocked` banner.
  Macs/NASes answer `OpenSSH`, so matching on "dropbear" makes a /24 sweep
  selective — verified it correctly rejects this Mac's own :22.
- `HostKeyAlias rmpp` is load-bearing: the IP changes per transport, so trust is
  pinned to the name and one `known_hosts` entry covers all three.
- Auth offers `publickey,password`. Root password lives on the device:
  Settings → General → Help → Copyright and licenses → bottom (GPLv3 Compliance).
  reMarkable OS updates can wipe `/home/root/.ssh/authorized_keys` → re-run
  `ssh-copy-id`.
- ⚠️ **`~/.ssh` is hard-denied to Claude's Read/Bash tools** (permission
  settings) — key generation and the `Include` line must be run by the user.
  See [[claude-permission-edit-not-write]].
- macOS registers the tablet as network service **"Paper Pro"** on `en5`, ranked
  **above Wi-Fi**, so plugging in points the default route at `10.11.99.1`.
  Internet still worked when checked; if it ever dies on plug-in, drag Wi-Fi
  above Paper Pro in Network settings.

Related: [[android-remote-access-stack]]
