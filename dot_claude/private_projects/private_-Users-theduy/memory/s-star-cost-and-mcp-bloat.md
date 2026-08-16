---
name: s-star-cost-and-mcp-bloat
description: "/s* cost audit — Fable dominance is the session-model orchestrator, not agents; MCP context-bloat layers and how to trim them"
metadata: 
  node_type: memory
  type: project
  originSessionId: 05b377e5-93ca-4cb2-9289-c67e453ea36b
  modified: 2026-07-24T20:15:19.667Z
---

Audit 2026-07-24 of daily model spend ($188.71; Fable 78% at $146.95).

**Root cause of "Fable does most the work":** `/s*` skills pin NO model → they inherit the
**session model**. Only agents pin models (s-implementer=opus, reviewers=opus, gate-runner/shipper=sonnet).
So Fable's cost = the **main-loop orchestrator** + `/s0-spec` + `/s1-plan` (Fable by design, ADR 0006),
NOT code work. Agents are already correctly tiered. `s-auto/SKILL.md:170` — stages run inline in the session.

Fable's $147 breakdown: cache-read 58M (~$58, re-reading the huge context prefix every turn),
cache-create 3.5M at 2× = 1h-TTL writes (~$69), output 388K (~$19). The 58M cache-read is the tell:
orchestrator re-reads the injected system prompt (skills registry + all MCP tool schemas) every turn.

**Biggest cost lever — APPLIED 2026-07-24:** s0/s1/orchestration moved off Fable to **Opus 5**
(was: Opus 4.8 co-equal fallback). ADR 0006 amended — Opus 5 is now the S0/S1 default; Fable 5 is
accepted only when the session is *already* on it, never requested. Enforcement is the **session
default pin**, not prose: `"model": "claude-opus-5[1m]"` in chezmoi `dot_claude/settings.json.tmpl`
(it previously pinned `claude-fable-5[1m]`, and the hourly `chezmoi apply` silently re-imposed Fable
over any `/model` default — that was the actual leak). S2–S5 agents pin the `opus`/`sonnet` **family
aliases**, so they move to Opus 5 / Sonnet 5 with no edit. One-off hard calls: `fable-advisor`
subagent, not a Fable session.

**Alias binds at session spawn, not per agent call** (verified 2026-07-24 from subagent transcripts,
`<project>/<session>/subagents/agent-*.jsonl` → `message.model`): a `/s-auto` run started 17:02Z ran
its whole S4 panel + `s-implementer` on `claude-opus-4-8` because Opus 5 only became visible on the
account at 19:18Z; `s-gate-runner` was `claude-sonnet-5`; the orchestrator was `claude-fable-5`. A
fresh CLI process resolves `opus` → `claude-opus-5`. **So a long-running `/s-auto` keeps its
start-time model generation — restart to move an in-flight pipeline up a tier.** That transcript path
is also the only reliable way to audit what a stage actually ran on; the UI shows tokens, not model.

**MCP bloat layers** (23 servers loaded; ~5 relevant to plan→ship). Levers differ per layer:
- Global `~/.claude.json` top-level mcpServers = everywhere. NOW minimal: only `codegraph`. (removed postiz)
- `/Users/theduy` project override (cua-computer-use, cua-driver, firecrawl) = ONLY home-dir cwd sessions,
  NOT /s* (runs in repo worktrees, different project key). Not a /s* problem.
- Repo `.mcp.json` = that repo only. salonx `Repo/salonx/.mcp.json` adds code-review-graph (uvx). Template
  saved for other repos. `.mcp.json` ADDS servers; it can NOT subtract globals/account connectors.
- Plugins = everywhere. Disabled `playwright` (pure dupe of ecc's) + `chrome-devtools-mcp` (chezmoi source
  settings.json.tmpl, commit e1802ea). ecc still bundles 6 MCP (github/context7/exa/memory/playwright/seq) —
  can't selectively disable without losing ecc's agents; left as-is.
- **claude.ai ACCOUNT connectors** (Notion/Canva/Higgsfield~75/Slack/Gmail/Calendar/Drive/postiz ~150 tools) =
  the biggest /s* bloat, loaded from the account NOT any local file. Config can't touch. Kill via `/mcp`
  in-session or claude.ai → Connectors. Headless VPS runs already can't load them.

MCP servers + plugins bind at **session spawn** → config changes need a Claude restart to take effect.

See [[statusline-and-hooks]] (settings.json is chezmoi .tmpl — edit source or hourly apply reverts),
[[plugin-routing-priorities]], [[claude-config-chezmoi-sync]].
