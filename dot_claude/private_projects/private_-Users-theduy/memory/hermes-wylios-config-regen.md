---
name: hermes-wylios-config-regen
description: "hermes-wylios entrypoint regenerates per-profile config.yaml from .env on every boot — config.yaml/`hermes config set` edits are ephemeral; durable per-profile config must live in entrypoint.wylios.sh"
metadata: 
  node_type: memory
  type: project
  originSessionId: 35b95f60-5b5d-46eb-9d7e-9be41c0e4681
---

Bluehost `hermes-wylios` container (6 Discord profiles: wylios-ceo + 5 salonx-*). Durability + ops facts learned 2026-06-20:

**Config is ephemeral.** `entrypoint.wylios.sh` (host: `/root/hermes-wylios/entrypoint.wylios.sh`, bind-mounted → `/home/hermes/entrypoint.sh`) reapplies `HERMES_MODEL_DEFAULT`/`PROVIDER`/`AUXILIARY` (from `/root/hermes-wylios/.env`) to **every** profile via `hermes -p <name> config set model.*` on each boot. So `config.yaml` edits and `hermes config set` are **wiped on restart**. Stack designed for a *uniform* fleet model — no per-profile model knob in `.env`.

**Per-profile override = patch entrypoint.** The `# PROFILE-MODEL-OVERRIDE` block after the global model loop (~line 113) re-sets specific personas AFTER the global pass.

**SPLIT FLEET (2026-06-20, current):** `.env` baseline stays anthropic/`claude-opus-4-8` → applied to all 6 + global/admin `hermes -z` + the engineer coding worker (kept on the reliable anthropic pool). Override block then flips the OTHER 5 to OpenAI Codex:
```
for _p in wylios-ceo salonx-sales salonx-research salonx-gtm; do
  hermes -p "$_p" config set model.provider  openai-codex >/dev/null 2>&1 || true
  hermes -p "$_p" config set model.default    gpt-5.5     >/dev/null 2>&1 || true
  hermes -p "$_p" config set model.auxiliary  gpt-5.5     >/dev/null 2>&1 || true
done
```
Result: **salonx-engineer + salonx-product = anthropic/claude-opus-4-8; ceo/sales/research/gtm = openai-codex/gpt-5.5.** To move a persona ON/OFF codex: add/remove its name from the `for _p in` loop list (off = stays on the anthropic/Opus baseline), restart container. Verified end-to-end (profile-scoped `hermes -p <p> -z` returns text for both a codex profile and engineer).

**⚠️ CODEX MODEL ID GOTCHA (cost me ~10 probes):** the ChatGPT-OAuth codex backend (`chatgpt.com/backend-api/codex`) silently streams **ZERO bytes** — surfaces as `hermes -z: no final response was produced` — for any model id it doesn't serve, NEVER a 400. The served id here is **`gpt-5.5`**. `gpt-5`, `gpt-5-codex`, `openai/gpt-5-codex` (the old entrypoint default), `codex-mini-latest` ALL return empty. Discover ids by brute-forcing `hermes -z "say OK" --provider openai-codex -m <id>`. `hermes model list` shows nothing for codex (no /v1/models on that backend).

**READ-ONLY CODEBASE PERSONAS (2026-06-20):** the 4 codex personas (gtm/sales/research/ceo) get codebase READ on Discord but a HARD write-block; engineer+product keep full write. Mechanism = `# --- READ-ONLY CODEBASE PERSONAS` block in entrypoint (re-asserted each boot): (1) `platform_toolsets.discord = [hermes-discord, file]` per persona (chat + file read); (2) per-profile `hooks: pre_tool_call` → `~/.hermes/hooks/block-codebase-writes.py` (matcher `.*`), which emits `{"decision":"block"}` for write tool_names (write_file/edit_file/apply_patch/move_file/terminal/...) and is silent (allow) for reads; (3) `hooks_auto_accept: true` so the non-TTY gateway doesn't stall on first-use hook consent. Hook fires at PROFILE level on `pre_tool_call` (platform-independent) — so testable via `hermes -p <p> -z` (cli path). Verified at FS level: engineer write creates file; gtm `write_file` blocked (file never created); gtm `read_file` returns content. Git push already separately blocked (no PAT, `gitconfig.readonly`). Hook wire protocol: stdin JSON `{tool_name,tool_input,...}` → stdout `{"decision":"block","reason":...}`; `shell=False` (script path, no pipes); manage via `hermes hooks list/test/doctor` (no `add` subcommand → must write the `hooks:` block into config.yaml directly).

**⚠️ `hermes tools enable <ts> --platform discord` CLOBBERS the curated toolset:** running it replaced the minimal `platform_toolsets.discord: [hermes-discord]` with the FULL 17-toolset default (incl. terminal/code_execution/computer_use/kanban/delegation — all write/exec). Do NOT use `hermes tools enable` to add a single toolset to a persona; edit `platform_toolsets.<platform>` directly (raw text — no pyyaml in container). Caught pre-restart so the dangerous set never loaded.

**Codex auth:** shared pooled `auth.json` `credential_pool` carries BOTH `anthropic` + `openai-codex` creds; profile `provider` field selects pool. Codex login (headless VPS): `docker exec -it hermes-wylios hermes auth add openai-codex --type oauth --manual-paste`, then `hermes auth reset openai-codex` (clears `suppressed_sources` flag). `hermes auth status openai-codex` / `hermes doctor` = source of truth ("logged in"); a key existing in `credential_pool` can still be invalid ("No Codex credentials stored"). Backups before edit: `entrypoint.wylios.sh.bak-<ts>`, `.env.bak-<ts>`.

**Restart semantics (gateways):** each profile gateway is a python proc under a per-profile `entrypoint.sh gateway run` bash wrapper (tini PID1 → bash 7 → 6 wrappers). `hermes gateway stop` does NOT auto-respawn. `hermes gateway restart`/`run` FOREGROUND-HANG through `docker exec` (orphans the gateway to the exec). `gateway start` is unsupported in-container (points to `docker restart`). **Only clean fleet restart = `docker restart hermes-wylios`** (~60-90s to relaunch all 6; box is RAM-tight, 160Mi free + swap). Liveness check: `pgrep -f "profile <P> gateway run"` — boot is slow, don't trust an early DOWN read.

**Shared credential = single point of failure.** All 6 profiles share ONE anthropic OAuth credential (pooled `auth.json`, id `2930b2`, label `anthropic-fixed`, source `manual:hermes_pkce`). Model id format in config is hyphen/no-prefix (`claude-opus-4-8`, `claude-sonnet-4-6`); catalog shows dot/prefixed (`anthropic/claude-sonnet-4.6`) but config uses hyphen form. See [[hermes-platform-topology]].
