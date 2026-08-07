---
name: agentmemory-install
description: "agentmemory 0.9.28 installed on the MacBook, run deliberately in zero-LLM mode via a launchd service"
metadata: 
  node_type: memory
  type: project
  originSessionId: 52a30290-489a-4367-8ded-f4107d3a895f
  modified: 2026-08-07T16:53:37.460Z
---

**rohitg00/agentmemory 0.9.28** installed 2026-08-03/04 on the MacBook (was NOT installed before — a prior audit found only empty `AgentMemory/` stub dirs in both vaults, which belong to the unrelated Hermes VPS export, plus past session-transcript mentions).

**Shape — four locations, none of which alone tells the story:**
- Plugin `agentmemory@agentmemory` (user scope): **15 skills, 12 hooks, 53 MCP tools** (manifest advertises 54 — off by one). Marketplace + `enabledPlugins` in `settings.json`, mirrored into the chezmoi template (see [[claude-config-chezmoi-sync]] — `claude plugin install` writes there and the hourly apply reverts it otherwise).
- MCP auto-wired by the plugin's own `.mcp.json` (`npx -y @agentmemory/mcp`) — no manual registration. First connect **timed out at 30s** on a cold npx download; pre-warming `~/.npm/_npx` fixed it. Recurs if that cache is cleared.
- Server: launchd **`com.theduy.agentmemory`** (`~/Library/LaunchAgents`, chezmoi-ignored like the other per-machine agents), `RunAtLoad` + `KeepAlive`, log `~/.agentmemory/server.log`. KeepAlive verified by kill → auto-respawn.
- Ports: **3111** REST (`/agentmemory/health`), 3112 streams, **3113** viewer, `iii` engine daemon on 49134.

**launchd points at the pinned global binary** `~/.npm-global/bin/agentmemory`, NOT `npx -y` — npx resolves from the network on every cold start, so a login before Wi-Fi associates yields a dead service. Cost: updates are manual (`npm i -g @agentmemory/agentmemory@latest`).

**Two processes, not one.** `iii` (PPID 1 daemon) owns the REST API + streams; the `node agentmemory` process is only the viewer/worker registering against it. Duplicate workers are easy to create and **silently** fall back 3113→3114 rather than erroring — check `pgrep` count and `health.workers`, not just "did it start".

**⚠️ Runs zero-LLM BY DECISION (owner, 2026-08-04)** — BM25 + on-device embeddings. No LLM compression or auto-summaries. Nothing leaves the machine. Reversible via `~/.agentmemory/.env`.

**⚠️ CORRECTION 2026-08-07: "search and recall work" was WRONG.** Three defects found and two fixed:

1. **REST was 404 on every `/agentmemory/*` route** — `iii` served HTTP on 3111 with CORS headers but agentmemory's triggers were never registered. MCP proxies REST, so `memory_sessions`/`memory_smart_search` returned `[]` while `server.log` showed continuous `Observation captured`. **Writes worked, reads were severed.** FIXED by a full stop (`launchctl bootout` + `kill` the `iii` pid — bootout alone leaves `iii` alive) then restart. Routes need **~50s** to mount; probing at 30s still 404s. Don't diagnose before then.

2. **State path was relative** — `iii-config.yaml` had `file_path: ./data/state_store.db` and the plist sets `WorkingDirectory=/Users/theduy`, so the store materialised as a stray `~/data/`. Any process with a different cwd forks its own empty store; the MCP bridges already run from `/Users/theduy/Repo/salonx`. FIXED: pinned to `/Users/theduy/.agentmemory/data/`.
   **⚠️ That edit lives in `~/.npm-global/lib/node_modules/@agentmemory/agentmemory/dist/iii-config.yaml` — `npm i -g` WIPES IT.** Reapply after every upgrade or the store silently splits again.

3. **`import` persists observations but never indexes them — NOT fixed, filed upstream as
   [rohitg00/agentmemory#1163](https://github.com/rohitg00/agentmemory/issues/1163).**
   Imported obs are retrievable by `sessionId` but invisible to `smart-search` forever. Proof:
   `mem:obs:*` keys went 30 → 1,878 on import while `mem:index:bm25*` keys stayed at **8**.
   No endpoint reindexes them — `graph/build`/`consolidate`/`reflect` return 200 and do nothing,
   `migrate` 400, `graph/snapshot-rebuild` 503. Silent failure: 200s, correct `export` counts.

   **⚠️ Do NOT repeat this misdiagnosis:** scores of `0.01639/0.01613/0.01587` are exactly
   `1/61, 1/62, 1/63` — normal **RRF fusion, k=60** (`1/(k+rank)`). They look degenerate and are
   not. Constant scores across queries are expected; RRF discards relevance and uses rank only.
   The discriminating test is whether the *results* change, not the scores. They do — live-captured
   obs rank fine. Search works; the index is just missing everything `import` wrote.

Why no key, so this isn't re-litigated:
- No provider API key exists on this machine; Claude Code here is **OAuth subscription** auth (`.credentials.json`).
- **Codex subscription OAuth cannot substitute.** agentmemory's OpenAI path is API-key-only (`detectProvider`: `OPENAI_API_KEY → MINIMAX → ANTHROPIC → GEMINI → OPENROUTER → noop`); `~/.codex/auth.json` holds an **empty** `OPENAI_API_KEY` plus audience-scoped OAuth tokens usable only by the Codex client. The **only** subscription path in the whole product is Anthropic's (`AGENTMEMORY_ALLOW_AGENT_SDK` spawning `@anthropic-ai/claude-agent-sdk`), which ships disabled over a documented **Stop-hook recursion loop** risk and would burn subscription usage.
- A Gemini key was tried and rejected: `AQ.`-prefixed **GCP project** key (project 333934072261) returning 403 `PERMISSION_DENIED` — API not enabled, and that route may bill the project rather than the free tier. The free tier needs an **AI Studio** key (`AIza…`, aistudio.google.com/apikey).

**⚠️ Never write a non-working provider key.** `GEMINI_API_KEY` is first in **both** the LLM and the embedding detection chains, so a 403-ing key pulls agentmemory out of noop mode *and* switches embeddings off the working local model — breaking search as well as compression. A half-configured provider is strictly worse than clean zero-LLM.

**Overlap to resolve eventually:** four memory layers now coexist — native Claude Code memory (`~/.claude/projects/.../memory/`), the graph-engineering lesson store, `claude-mem` (installed, disabled), and agentmemory. No technical conflict (`deniedMcpServers` blocks `memory`, not `agentmemory`), but agentmemory's `remember`/`recall`/`forget` skills duplicate what the lesson store owns via `/s-auto`.
