---
name: salonx-graph-servers-scope
description: "salonx's two code graphs — CodeGraph db went missing 2026-07-22 (orphan WAL, reindex not repair); MCP servers bind their project root at SPAWN time, and code-review-graph is project-scoped to salonx/.mcp.json."
metadata: 
  node_type: memory
  type: project
  originSessionId: 131bb03e-24de-412a-b383-44b0170d1bc5
  modified: 2026-07-22T15:30:37.243Z
---

## Root cause of the 2026-07-22 CodeGraph failure: the db was gone

`salonx/.codegraph/` held only orphan `codegraph.db-wal` (10.8 MB) + `-shm`, **no base
`codegraph.db`**. The watcher daemon had exited on its 300 s idle timeout
(`Shutting down (idle timeout; clients=0)`) and the base file was gone. A WAL without its base
db is unrecoverable — **fix is reindex, not repair**:

```
cd /Users/theduy/Repo/salonx && codegraph init .
```

~60 s → 2,057 files / 20,158 nodes / 49,820 edges / 41 MB. `.codegraph/` is fully gitignored
(`*` + `!.gitignore`), so no git risk. Verify through the **MCP** path
(`codegraph_status` with `projectPath`), not just the CLI — the CLI opens the db file directly
while the MCP server keeps its own init state, so CLI-green can hide MCP-broken.

## MCP servers bind their project root at SPAWN time, not per call

Verified error text from a session started in `~`:

> No CodeGraph project is loaded for this session. Searched for a `.codegraph/` directory
> starting from: `/Users/theduy` … the MCP client launched the server outside your project.

The root is fixed when the session starts. So a "needs explicit `projectPath`" error means the
*session* began outside salonx — including a **resumed or compacted session** that carries the
old spawn root even though the visible CWD now reads salonx. Workarounds: pass `projectPath`
explicitly per call, or `--path` in the server args (don't do the latter globally — it would
pin the global `codegraph` server to one repo).

**Do not infer "user ran from `~`" from this error alone** — that mistake was made on
2026-07-22 while the actual cause was the missing db. Check `ls salonx/.codegraph/` for a real
`codegraph.db` before blaming CWD.

## Two graphs, different config scopes

| Server | Registered in | Loads when | Data | Freshness |
|---|---|---|---|---|
| `codegraph` | `~/.claude.json` (global) | always | `salonx/.codegraph/codegraph.db` | own watcher daemon; exits after 300 s idle |
| `code-review-graph` | `salonx/.mcp.json` (**project**) | only when the session starts in salonx | `salonx/.code-review-graph/graph.db` (~317 MB) | PostToolUse hook in `salonx/.claude/settings.json` (`code-review-graph update --skip-flows`) |

code-review-graph being hook-driven rather than daemon-driven is why it stayed healthy
(updated same day) while CodeGraph rotted.

## Query gotcha

"station" is ambiguous in salonx — top CodeGraph hits are **inventory** stations
(`StationsTab.tsx`, `StationRefillModal.tsx`). Station-*chores* symbols live in
`src/hooks/rpc/stationChores.rpc.ts`, `src/components/config/StationChoreSetupCard.tsx`,
`src/components/chores/StationChoreReminderList.tsx`. Query those names directly.

Routing rule unchanged and intent-based: CodeGraph = explore/dep-trace/refactor planning;
code-review-graph = commit/diff/PR review only. See [[plugin-routing-priorities]],
[[salonx-worktree-guard]], [[salonx-gates-local]].
