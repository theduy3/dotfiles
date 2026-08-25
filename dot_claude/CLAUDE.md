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

## Communication — ASD-STE100 Simplified Technical English

Always write user-facing prose in ASD-STE100 Simplified Technical English.

- Use one approved meaning per word. Do not use a word as two parts of speech.
- Keep procedural sentences to 20 words or less. Keep descriptive sentences to 25 words or less.
- Give one instruction in one sentence.
- Use the active voice. Do not use the passive voice.
- Keep the articles `a`, `an`, and `the`. Do not remove them.
- Do not use contractions. Write `do not`, not `don't`.
- Use simple tenses: the simple present, the simple past, or the simple future.
- Use the same word for the same thing every time. Do not use synonyms for variety.
- Do not use slang, idioms, jargon, or metaphors.
- Keep paragraphs to six sentences or less.
- Put a warning or a caution before the step that it applies to.

This rule has priority over the Caveman output mode. Caveman removes articles and
writes fragments. ASD-STE100 does not permit this. If both are active, obey ASD-STE100.

Scope: prose to the user. This rule does not change code, commit messages, file
content, quoted error text, or command output.
