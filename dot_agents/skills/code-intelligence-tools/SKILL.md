---
name: code-intelligence-tools
description: Detailed tool tables and workflow for Graft, CodeGraph, and code-review-graph. Use when exploring a codebase, tracing dependencies, planning a refactor, or reviewing a commit/diff/PR — anywhere the routing rule in ~/.claude/CLAUDE.md points here for exact tool names and call order.
---

# Code intelligence: Graft + CodeGraph + code-review-graph

**Routing rule lives in `~/.claude/CLAUDE.md` §Code intelligence** — not restated here.
That file is always loaded; this skill holds the detail tables the canonical rule doesn't carry.

Three separate stores, no collision: `graft/` markdown (gitignored) · `<repo>/.codegraph/codegraph.db`
· `<repo>/.code-review-graph/graph.db`. **All three are per-repo.** CodeGraph only *looks* global —
one registration in `~/.claude.json` serves every repo, but each query binds a project via that
repo's `.codegraph/`; reach across repos with the `projectPath` argument.

### Orientation — Graft (CLI only, MCP deliberately NOT registered)

Trial-scoped to salonx (built 2026-08-15, structural only). `graft build` in another repo turns it
on there — the routing rule self-gates on `graft/` existing.

| Command | Use when |
|---------|----------|
| `graft map` | Repo orientation — per-directory hubs + hotspots ranked by inbound refs. No CodeGraph equivalent |
| `graft ask "<task>"` | Ranked nodes relevant to a task description |
| `graft skeleton <file>` | API surface of a file without function bodies |
| `graft check` | Drift between code and graph |

⚠️ **Do not run `graft init`.** It registers a 6-tool MCP server (`graft_find_code`,
`graft_trace_calls`, …) that duplicates `codegraph_*` — pure context bloat. Read `graft/` with
Read/Grep, which is upstream's intended access path.
⚠️ `graft build --deep` (LLM concept nodes) is **not built** — needs a paid API key, none configured.
Everything above is structural tree-sitter, `$0`.

### Exploration — CodeGraph FIRST

- **"How does X work" / architecture / survey an area**: `codegraph_explore` (one call, verbatim source)
- **Callers / callees / blast radius**: `codegraph_callers` / `codegraph_callees` / `codegraph_impact`
- **Symbol location**: `codegraph_search`

### Review — code-review-graph FIRST

| Tool | Use when |
|------|----------|
| `detect_changes_tool` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context_tool` | Need source snippets for review — token-efficient |
| `get_impact_radius_tool` | Blast radius of the change under review |
| `get_affected_flows_tool` | Execution paths impacted by the diff |
| `query_graph_tool` | Tracing tests_for / dependencies during review |
| `list_graph_stats_tool` | Index freshness — node/edge counts + `head_matches_build` |

⚠️ **The `_tool` suffix is mandatory on all 30 code-review-graph tools** — unlike `codegraph_*`,
which carry none. Verified 2026-08-15 against the installed package; the table above was wrong
from the start and went unnoticed because the server was disabled. A `select:` on a bare name
returns "no matching deferred tools found", which reads exactly like the server being down —
so a typo here costs a wrong diagnosis, not just a retry.

### Workflow

1. Graphs auto-update on file changes. CodeGraph: a **per-repo daemon** (`daemon.sock`/`daemon.pid`
   under `.codegraph/`), which exits after 300 s idle. code-review-graph: PostToolUse hook on
   `Edit|Write`. Graft: refreshes structurally on every query (~ms, `$0`, never calls an LLM).
2. Repo orientation → `graft map` when `graft/` exists.
3. Exploration or refactor planning → CodeGraph tools.
4. Code review → `detect_changes_tool`, then `get_review_context_tool` /
   `get_affected_flows_tool`; `get_impact_radius_tool` before calling a code-changing task done.
5. Fall back to Grep/Glob/Read only when the graph doesn't cover what you need.
