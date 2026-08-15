---
name: code-intelligence-three-layer
description: Graft(L0 CLI-only)+CodeGraph(L1)+code-review-graph(L2) routing live 2026-08-15; CRG had been silently dead via a settings.local.json enabled/disabled conflict; graft MCP deliberately unregistered.
metadata: 
  node_type: memory
  type: project
  originSessionId: 2947c093-cc73-45a2-b8b2-99e80b03125a
  modified: 2026-08-15T21:22:19.430Z
---

## The three layers (routing rule in `~/.claude/CLAUDE.md` §Code intelligence)

| L | Tool | Store | Access |
|---|---|---|---|
| L0 orientation | Graft | `<repo>/graft/` markdown, 76 MB in salonx | **Read/Grep + CLI only** — MCP deliberately NOT registered |
| L1 navigation | CodeGraph | `<repo>/.codegraph/codegraph.db` | `codegraph_*` MCP |
| L2 review | code-review-graph | `<repo>/.code-review-graph/graph.db` | `mcp__code-review-graph__*` + PostToolUse hook |

**All three are per-repo.** CodeGraph only *looks* global — one registration in `~/.claude.json`
serves every repo, but each query binds a project via that repo's `.codegraph/`. Engine is
`node:sqlite` (WAL + FTS5), **not RocksDB**, and there is no db under `~/.codegraph/` — that path
holds only the runtime install (a 120 MB bundled node binary). See [[salonx-graph-servers-scope]].

## code-review-graph was silently dead

`~/.claude/settings.local.json` listed it in **both** `enabledMcpjsonServers` and
`disabledMcpjsonServers`; disabled won, so no `mcp__code-review-graph__*` tool resolved anywhere —
while `~/.claude/CLAUDE.md` routed every review to it. The PostToolUse hook
(`code-review-graph update --skip-flows`) kept indexing the whole time, so the 331 MB salonx graph
looked healthy and nothing surfaced the breakage. **Removed the `disabledMcpjsonServers` key
2026-08-15.**

**Why it matters:** a warm index is not a working tool. The hook proves freshness, not reachability.
**How to apply:** conflicting enable/disable keys fail closed and silently — check *both* lists, and
confirm the tool actually appears in the session, not just that its index is recent.

## Every code-review-graph tool ends in `_tool` — `codegraph_*` tools do not

Real names: `detect_changes_tool`, `get_review_context_tool`, `get_impact_radius_tool`,
`get_affected_flows_tool`, `query_graph_tool`, `list_graph_stats_tool` — 30 in total, all
suffixed. Verified 2026-08-15 by grepping the installed package
(`.cache/uv/archive-v0/*/site-packages/code_review_graph/`), not by trusting a report.

`~/CLAUDE.md`'s review table carried the **bare** names from the start and nobody noticed,
because the server was disabled so nothing ever called them. Fixed 2026-08-15 across 9 sites in
`~/CLAUDE.md` + `~/.claude/CLAUDE.md`.

**Why it matters:** a `select:` on a bare name returns "no matching deferred tools found" — which
is *indistinguishable from the server being down*. One symptom, two very different causes, so a
name typo buys a wrong diagnosis rather than a retry.
**How to apply:** never normalize the suffix away as a "typo" — and when a tool name doesn't
resolve, check the name against the package before concluding the server is unreachable.

## Graft: trial, CLI-only, deliberately not MCP

Installed `@nanonets/graft` 0.10.1 globally; `graft build` in salonx only → 2,211 cards / 10,746
nodes / 27,674 edges in 18 s, `$0`.

- **Never run `graft init`** — it registers 6 MCP tools (`graft_find_code`, `graft_trace_calls`, …)
  that duplicate `codegraph_*`. Upstream's intended access path is Read/Grep over the files.
- `graft build --deep` (LLM concept nodes) is **unbuilt** — needs a paid API key; none exists in env
  or shell rc. Everything in use is structural tree-sitter.
- **`graft map` is the one genuinely additive capability**: per-directory hubs + hotspots ranked by
  inbound reference count, whole repo, ~1.5k tokens. CodeGraph has no equivalent — it answers named
  questions with verbatim source.
- Zero git footprint: `graft build` appends `graft/` to the repo `.gitignore`; that edit was
  reverted and `graft/` added to `~/.config/git/ignore` instead. Rollback = `rm -rf
  ~/Repo/salonx/graft` + drop that line.
- **Kill criterion:** decide by 2026-08-29 — if structural-only cards add nothing over CodeGraph,
  drop it or fund `--deep`.

## chezmoi: this Mac is `push` role, so deployed edits are captured, not reverted

`~/.config/claude-sync/role` = **push**. `claude-sync.sh` runs `chezmoi re-add` → commit → push →
`chezmoi apply --force`, in that order. So editing the **deployed** `~/.claude/CLAUDE.md` or
`~/CLAUDE.md` is correct on this box — re-add captures it before apply runs.

**The "edit source or the hourly apply reverts it" rule is `.tmpl`-only** (`settings.json.tmpl`),
because `re-add` won't overwrite a template with rendered output. Plain managed files round-trip
fine. Corrects the over-broad claim in [[claude-config-chezmoi-sync]].

Bonus: `~/.claude` is not a git repo, so background-session isolation guards don't fire there —
unlike `~/.local/share/chezmoi`, which is a repo and does trip
[[bg-isolation-guard-scope]] from a `~`-rooted bg session.
