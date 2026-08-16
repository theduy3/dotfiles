---
name: claude-mem-archive
description: "claude-mem's 6-month history exported to greppable JSONL in the vault after agentmemory's search proved broken; ripgrep is the working recall path"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7848052f-8174-4a45-b983-f136b7f00ba9
  modified: 2026-08-07T16:54:05.479Z
---

**claude-mem disabled + source DB DELETED 2026-08-07.** Plugin off (7 hooks, 22 MCP tools,
14 skills) when the memory stack was collapsed to three layers: codegraph (architecture) /
code-review-graph (diff impact) / agentmemory (cross-session). The 886M `~/.claude-mem` was
deleted **only after** the archive matched source counts exactly — 42,390/42,390 observations,
3,490/3,492 summaries (the 2 skipped rows verified as 0 content bytes).

**The archive — `~/theduyvault/Notes/Claude-Context/claude-mem-archive/`, 24 MB gzipped, 147 shards.**
Exact counts, verified against source: **42,390 observations + 3,490 session summaries**,
2026-01-29 → 2026-08-07, sharded per project (`salonx.jsonl` 78 MB, `theduy.jsonl` 10 MB,
`*.summaries.jsonl` alongside). Exporter: `~/.claude/tools/claude-mem-export.py`
(`--types`, `--limit`, `--summaries`; opens source `mode=ro`).

**ripgrep IS the recall path, not agentmemory.** `rg -z "worktree" salonx.jsonl.gz` → 4,125 hits
(shards gzipped 2026-08-07: 111M → 24M, 4.6x; `rg -z` greps them natively). agentmemory's
`import` never indexes what it stores ([[agentmemory-install]], upstream issue #1163), so grep
over these shards is the only working search over this history today.

**Two schema traps if this is ever re-exported:**
- `observations.text` is **NULL for all 42,390 rows.** The obvious `text → content` mapping yields
  42,390 empty records that import cleanly and return nothing. Content lives in
  `title` / `subtitle` / `facts` / `narrative` / `concepts`; `facts`/`concepts` are JSON arrays
  stored as TEXT.
- claude-mem tracks `project` **per observation**; agentmemory tracks it **per session**. Sessions
  must be synthesized from `memory_session_id` + `project` or everything collapses to one project.

**Pilot import already in agentmemory:** 2,854 `decision`+`security_*` rows (1,842 sessions),
timestamps/types/importance preserved, retrievable by `sessionId`, **not findable by search**.
Full 42,390 payload staged at `~/.claude/archive/claude-mem-import-20260807.json` (103 MB, kept
OUT of the vault so Syncthing doesn't push it to all 6 devices) — ready to POST to
`/agentmemory/import` once BM25 is fixed. Import must be chunked: 2,854 records exceeded a
2-minute request window.

**Re-enable claude-mem** by flipping `claude-mem@thedotmack` to `true` in **both**
`~/.claude/settings.json` and the chezmoi template — template edit required or the hourly sync
reverts it ([[claude-config-chezmoi-sync]]).
