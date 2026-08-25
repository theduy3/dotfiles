## Code intelligence — graph-tool routing

Three layers. Climb only as far as the question needs.

**L0 orientation — Graft (plain files, NOT MCP).** If a `graft/` directory exists at the repo
root, start there for "what is this system / where do I begin" questions — via Read/Grep, or
`graft map` (ranked hubs + hotspots, whole repo, ~1.5k tokens) and `graft ask "<task>"` in Bash.
No `graft/` → skip straight to L1. Never run `graft init`: it registers 6 MCP tools that
duplicate `codegraph_*`.
**L1 navigation — CodeGraph (`codegraph_*`).** Whole-repository exploration, dependency
tracing, architecture questions, refactor planning. `codegraph_explore` first — one call,
verbatim source, usually the only call needed.
**L2 review — code-review-graph.** Commit, diff, or PR review only; obtain minimal review
context (`detect_changes_tool`, then `get_review_context_tool`) before reading files manually.
Before declaring any code-changing task complete, call `get_impact_radius_tool` on the changed
files — the PostToolUse hook keeps that index warm but reports nothing on its own.
⚠️ **Every code-review-graph tool ends in `_tool`** — the bare name does not resolve, and the
"no matching tools found" it returns is indistinguishable from the server being down.

If the chosen server reports an unbuilt graph for the current repo
(`codegraph_status` / `list_graph_stats_tool` → 0 nodes —
as at the `~` home-dir level), fall back to Grep/Glob rather than silently switching tools.

## Communication — ASD-STE100 Simplified Technical English, Caveman voice

Write user-facing prose in ASD-STE100 Simplified Technical English, spoken in the
Caveman register. Caveman sets surface form. ASD-STE100 sets discipline underneath.
Caveman wins wherever two overlap.

Caveman owns surface form:
- Drop articles `a`, `an`, `the`. Drop filler, pleasantries, hedging.
- Fragments are correct output, not defects.
- Contractions allowed. Pick shorter form.

ASD-STE100 owns everything else:
- One approved meaning per word. No word as two parts of speech.
- Procedural sentence: 20 words max. Descriptive sentence: 25 words max.
- One instruction per sentence.
- Active voice only.
- Simple tenses: simple present, simple past, simple future.
- Same word for same thing every time. Pick short word, then keep it. No synonyms for variety.
- No slang, idioms, jargon, metaphors.
- Paragraph: six sentences max.
- Warning or caution goes before step it applies to.

No conflict remains. Rules above are disjoint by construction.

Scope: prose to user. Not code, commit messages, file content, quoted error text,
or command output.
