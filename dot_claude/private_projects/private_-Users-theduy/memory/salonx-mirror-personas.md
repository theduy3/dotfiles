---
name: salonx-mirror-personas
description: Fresh read-only salonx clone for hermes-wylios read personas (Product-Lead) — fixes stale-checkout false-negatives
metadata: 
  node_type: memory
  type: project
  originSessionId: 484fbc7f-0428-420f-bf09-271c23f8f82e
---

Read-only personas on hermes-wylios (Bluehost, [[hermes-desktop-remote]]) answered repo
questions from the STALE shared clone `~/.hermes/work/salonx` (nothing pulls it between
container recreates) → e.g. Product-Lead (`salonx-product` profile) wrongly called WYL-42's
merged backend "missing." Fix deployed 2026-07-02.

**Mirror:** `/vault/repos/salonx-mirror` (host `/root/wylios-vault/repos/...`), auto-synced to
`origin/main` every 10m by host systemd `salonx-mirror.timer`→`.service` (`docker exec`, runs
as agent uid **1500**, `fetch`+`reset --hard`, logs `/vault/logs/mirror.log`). Verified pulling
new commits (39425ee→8c61646). Separate from the engineer's WRITABLE `~/.hermes/work/salonx` —
do NOT redirect that (salonx-engineer writes there for the s1→s9 coding flow).

**Auth:** fine-grained read-only PAT (Wylios-Dev/salonx, Contents+PRs read) at
`/vault/secrets/salonx-read.pat` (0600) via `GIT_ASKPASS=/vault/secrets/askpass-salonx.sh` —
token never in `.git/config`; push disabled (`remote push-url DISABLED_READONLY`). Preserves
the box's write-isolation invariant.

**gh:** static binary `/vault/bin/gh` (in volume → survives `docker restart`), reads PRs via the
container's ambient `GITHUB_TOKEN` (theduy3). `gh pr view 1015` works.

**Durability:** everything lives in the persistent `/vault` volume (host `/root/wylios-vault`),
so a container recreate keeps working w/o re-running the bootstrap. Bootstrap script:
`~/salonx-mirror-bootstrap.sh` (Mac) — idempotent, `ssh root@129.121.100.233 'bash -s' < it`.
Agent reaches everything via ABSOLUTE PATHS (`/vault/repos/salonx-mirror`, `/vault/bin/gh`) —
no env dependency. **DO NOT add an env-export block to `entrypoint.wylios.sh`**: an `awk >tmp; mv`
edit stripped its `+x` on 2026-07-02 (bind-mounted host→`/home/hermes/entrypoint.sh`), tini
couldn't exec PID1 → whole-fleet crash loop. Recovered via `.bak` + `chmod 0755` + restart. If a
boot-script edit is ever truly needed, use `sed -i`/`ed` (mode-preserving) and re-`chmod +x`.
`entrypoint.wylios.sh` = host `/root/hermes-wylios/entrypoint.wylios.sh`, must stay `0755`.

**OPEN last-mile:** Product-Lead still needs INSTRUCTION to prefer `$SALONX_MIRROR` over the stale
clone. That lives in the `salonx-product-specs` skill / `SALONX-REPO-BRIEF.md` which is runtime-
fetched (vault/Paperclip), not a static container file — user must add the directive there.
Draft text: scratchpad `salonx-mirror/product-lead-repo-brief-patch.md`.

Access to Bluehost = **SSH key from the Mac only** (`root@129.121.100.233`); other hosts fall
back to password (disabled) and fail.
