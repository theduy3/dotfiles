---
name: ecc-memory-graph-storage
description: "ecc:memory MCP knowledge graph stores to npx cache — fragile path, wiped by npx cache clean or version bump"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 7d54dfe6-570a-43ae-be33-689eccef4954
---

ecc plugin's `memory` MCP server (`@modelcontextprotocol/server-memory@2026.1.26`, pinned in plugin `.mcp.json`) has no `MEMORY_FILE_PATH` set, so the knowledge graph persists to the npx cache:

`~/.npm/_npx/f0415454dfb4e463/node_modules/@modelcontextprotocol/server-memory/dist/memory.jsonl`

**Fragility:** `npm cache clean`/`npx` cache eviction or a version bump in `.mcp.json` (new hash dir) silently resets the graph to empty. Plugin updates rewrite `.mcp.json`, so editing it to add `MEMORY_FILE_PATH` won't stick.

**Mitigation:** markdown memory dir stays source of truth; graph is a queryable derived view. Seeded 2026-07-10 (10 entities, 12 relations: theduy, salonx, hermes-fleet, pipelines, VPSes, [[task-queue]]). If graph comes back empty, re-seed from memory files.
