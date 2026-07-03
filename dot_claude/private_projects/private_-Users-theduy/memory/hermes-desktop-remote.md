---
name: hermes-desktop-remote
description: "How Hermes Desktop (Mac) connects to the remote VPS Hermes agent — API server, port, key, SSH tunnel"
metadata: 
  node_type: memory
  type: project
  originSessionId: cf8121b1-344f-41ac-b98f-ad68814107b6
---

**MIGRATED 2026-06-19: Hermes VPS moved `147.93.116.94` (Hostinger) → `129.121.100.233` (Bluehost/`hal-server-803171`, Oracle/Ashburn, PTR unifiedlayer.com).** Both compose projects (`/root/hermes` Telegram + `/root/hermes-wylios` Discord) lifted with volumes/secrets/vaults. Dokploy + Supabase + client apps STAYED on Hostinger `147` (88 containers, untouched). **Hostinger Hermes fully DECOMMISSIONED 2026-06-19 (no rollback): containers/volumes/image/dirs deleted, ~38 GB freed, ephemeral migrate key removed. Bluehost `129` is the ONLY copy now.** Bluehost is RAM-constrained (3.8 GB + 8 GB swap, per-service `mem_limit` overrides) — watch for OOM under load; real fix is resize ≥8 GB. Image transferred exact via `docker save`/`load` (no rebuild). Cross-distro gotcha: rsync volumes with `-aHA` (keep ACLs) — dropping `-A` strips the POSIX ACL that grants hermes(1500) write to root-owned profile dirs → gateway crash-loops on `auth.json` symlink. **RESOLVED 2026-06-20:** despite the ACL plan, the `zeus` profile dir still landed `root:root` (775) while every other profile was `hermes:hermes` — uid-1500 hermes couldn't write the dir, so startup `ln -sf ../../auth.json zeus/auth.json` spammed `ln: failed ... Permission denied`. Permanent fix = plain `docker exec -u 0 hermes chown -R hermes:hermes /home/hermes/.hermes/profiles` + `docker restart hermes`. It persists because `zeus` lives in the `hermes_hermes-data` volume (NOT a bind mount) and `entrypoint.sh` only does `ln -sf` (no re-chown to root). **Diagnostic trap:** `docker logs --tail N` on a quiet container reaches hours back and looked like it was "still failing" after the fix — always confirm with `-t` timestamps vs `docker inspect --format '{{.State.StartedAt}}'`; lines predating the boot are stale. Note: `hermes`/`hermes-wylios` are container names, not shell commands — access via `docker exec`/`docker logs`, never by typing the name (`command not found`).

Hermes Desktop = `fathah/hermes-desktop` (GitHub), app bundle named **"Hermes Agent.app"** (NOT "hermes-desktop" — searches must use "Hermes Agent"). Installed at `/Applications/Hermes Agent.app` v0.5.1 arm64, de-quarantined (unsigned Electron, needs `xattr -dr com.apple.quarantine`). arm64 dmg: `hermes-desktop-0.5.1-arm64.dmg`.

It is a thin client over Hermes's **OpenAI-compatible API server**, NOT the dashboard (9119).
- API server hosted by the **`hermes gateway`** process (no `serve`/`api` subcommand in v0.14.0). Enabled purely by env in `/root/hermes/.env`: `API_SERVER_ENABLED=true`, `API_SERVER_KEY=<secret>`, `API_SERVER_PORT=8642`, `API_SERVER_HOST=127.0.0.1`. Recreate gateway to load: `cd /root/hermes && HERMES_UID=1500 HERMES_GID=1500 docker compose up -d gateway` (`restart` does NOT reload env_file).
- **Security:** missing `API_SERVER_KEY` = unauthenticated RCE (full toolset incl. terminal). Key required even on loopback. Verify: no-auth → 401, with-key → 200 at `/v1/models`; base path `/v1`, health `/health`.
- Key stored on VPS at `/root/hermes/.desktop-api-key` (chmod 600). Pipe to Mac clipboard without transcript exposure: `ssh root@129.121.100.233 'cat /root/hermes/.desktop-api-key' | tr -d '\n' | pbcopy`.

Hermes VPS = `root@129.121.100.233` (Bluehost, post-2026-06-19 migration). Dokploy/Supabase/client apps stay on `root@147.93.116.94` (Hostinger). Dashboard binds 127.0.0.1:9119; API binds 127.0.0.1:8642 (both localhost-only, host networking).

**Connection = SSH tunnel** (dashboard/API are localhost-only by design): `ssh -f -N -L 8642:127.0.0.1:8642 root@129.121.100.233`. In Desktop: Remote mode, URL `http://127.0.0.1:8642` (add `/v1` if models empty), paste key. For durability use autossh + `~/.ssh/config` Host alias. NOTE: ssh config `Host paperclip` (now → 129) forwards `3101→3100` (wylios Paperclip admin API), NOT 8642 — the 8642 desktop tunnel is configured inside the Hermes Desktop app, repoint there too.

See [[seo-sanssouci]] context lives on same VPS. Related: VPS Hermes is Docker v0.14.0, 12 profiles, DeepSeek (vault note "Hermes Agent Setup and Operations").
