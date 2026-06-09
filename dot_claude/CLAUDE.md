@RTK.md

## MCP: code-review-graph vs GitNexus — graph-tool precedence (don't blend the two)

Both `code-review-graph` and the `gitnexus-*` skills wrap an overlapping codebase
knowledge-graph MCP. For in-repo graph queries, prefer **`code-review-graph`**. Use GitNexus
only when explicitly asked. Tiebreaker: check `list_graph_stats` first — if `code-review-graph`
reports `Nodes: 0` (graph unbuilt for the current repo, as it is at the `~` home-dir level),
neither graph helps; fall back to Grep/Glob rather than silently switching tools.
