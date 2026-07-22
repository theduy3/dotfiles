## Code intelligence — graph-tool routing (don't blend the three)

Use **CodeGraph** (`codegraph_*`) for whole-repository exploration, dependency tracing,
architecture questions, and refactor planning.
Use **code-review-graph** only for commit, diff, or PR reviews; obtain minimal review
context (`detect_changes`, `get_review_context`) before reading files manually.
Use GitNexus only when explicitly asked. Tiebreaker: if the chosen server reports an
unbuilt graph for the current repo (`codegraph_status` / `list_graph_stats` → 0 nodes —
as at the `~` home-dir level), fall back to Grep/Glob rather than silently switching tools.
