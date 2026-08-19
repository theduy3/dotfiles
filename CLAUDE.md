# Global Configuration

> Applied to all sessions from `~`. Project-specific commands and architecture belong in each repo's CLAUDE.md. When project instructions conflict with this file, **project wins**.

## Permission Model

Read-only tools are auto-approved (no prompt): `Read`, `Glob`, `Grep`, `WebSearch`, `WebFetch`.
Safe read-only Bash commands are also auto-approved: `ls`, `cat`, `head`, `tail`, `wc`, `which`, `supabase status`, `supabase db diff`.

**Still gated (requires approval):** `Write`, `Edit`, `Agent`, destructive Bash, MCP tools (Slack/Notion sends).

## Package Manager

Prefer `bun run` over `npm run` for speed. For `install`, follow the project's lockfile (`package-lock.json` → `npm`, `bun.lock` → `bun`). Defer to project CLAUDE.md if it specifies otherwise.

## Behavioral Principles

### Plan when the shape is unclear
- Newer models (Opus 4.6+/Fable) plan implicitly — don't force plan mode for every 3+ step task.
- Reach for a written plan/spec when work is genuinely ambiguous or architectural, or when the
  artifact itself is wanted as a record of intent. Otherwise delegate and run.
- If something goes sideways, STOP and re-plan — don't keep pushing.

### Subagent Strategy
Spawn subagents to isolate context, parallelize independent work, or offload bulk mechanical tasks. Don't spawn when the parent needs the reasoning, when synthesis requires holding things together, or when spawn overhead dominates.

Pick the cheapest model that can do the subtask well:
- **Haiku**: bulk mechanical work, no judgment
- **Sonnet**: scoped research, code exploration, in-scope synthesis
- **Opus**: subtasks needing real planning or tradeoffs

If a subagent realizes it needs a higher tier than itself, return to the parent.

Parent owns final output and cross-spawn synthesis. User instructions override.

- One tack per subagent for focused execution
- For complex problems, throw more compute at it
- **Depth cap: max 2 tiers.** Parent → subagent → at most one more tier; beyond that, return findings instead of spawning further
- **Haiku never spawns subagents.** If a Haiku worker needs help, return to parent for re-dispatch — task was scoped wrong
- **No self-escalation.** Subagent that needs a smarter model returns to parent; never spawn at higher tier on its own (hides cost from orchestrator)

### Tool Preference Ladder
Pick the cheapest tool that can do the job; escalate only when blocked.

**Web fetching** (in order):
1. **WebFetch** — free, text-only, works on public pages that don't block bots.
2. **agent-browser CLI** — free, local Rust CLI + Chrome via CDP. For dynamic pages or auth walls that WebFetch can't handle. Returns the accessibility tree with element refs (@e1, @e2). ~82% fewer tokens than screenshot-based tools. Install: `npm i -g agent-browser && agent-browser install`. Use `snapshot` for AI-friendly DOM state, element refs for interaction.
3. **claude-in-chrome MCP** — fallback when agent-browser CLI not installed and target is auth-walled/JS-heavy.
4. **`mcp__computer-use__*`** — last resort for native apps or when browser tooling can't reach the target.

**PDF files**: Use `pdftotext` via Bash, not the `Read` tool. `Read` loads PDFs as images (expensive). Only use `Read` when the user explicitly asks to analyze images/charts inside the document. Note: `pdftotext` only works for PDFs on local disk — chat-attached PDFs render via `Read` only.

**Repo search**: `Grep`/`Glob` for known scope; Explore subagent only when 3+ queries needed.

**Known file path**: `Read` directly; never use Explore for known paths.

**Recurring patterns**: Notice recurring fetch/parse patterns and propose wrapping them as dedicated tools. When the same fetch/parse logic comes up more than once, suggest wrapping it as a named tool (skill file or `.py` script with extraction baked in for that source). Add the entry to the `## Dedicated Tools` registry below and reference it by name on future calls. For 3+ repetitions in a single session, wrap it immediately as a Bash one-liner or a small script.

### Demand Elegance
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip for simple, obvious fixes — don't over-engineer

### Self-Improvement
- After ANY correction: update `tasks/lessons.md` in the **active project**
- Write rules that prevent the same mistake recurring
- Format: category header, one-line rule, commit hash. Keep it scannable.

## Workflow — Claude plans, OMP executes

> **Claude thinks, OMP builds.** Both run in herdr panes.

- **Claude owns the front half**: brainstorm → interview → spec (`tasks/spec-<topic>.md`) → plan
  (`tasks/todo-<topic>.md`) → adversarial review of both. Stop at an approved plan.
- **OMP owns the back half** (`omp`, @oh-my-pi): implement, test, commit, PR. Hand off by pointing it
  at the approved `tasks/todo-<topic>.md`.
- Claude implements only when told to directly ("do it here"). Default is hand-off, not execution.
- No autonomous ship loop on the Claude side. Claude does not merge.
- ⚠️ `~/.codex` is OMP's live state (Codex protocol client) — never delete it.

### Worktree & Vault
- Isolate with the built-in `EnterWorktree` before editing a shared checkout.
- Specs → `tasks/spec-*.md`, plans → `tasks/todo-*.md`.
- Vault auto-inject is NOT wired (`inject-vault-context.sh` is registered in no settings file, so
  `CLAUDE_VAULT_FORCE=1` does nothing). Query the vault on demand via `qmd` MCP.
- Details: `~/.claude/rules/common/worktree-and-vault.md` — load on demand.

### Guardrails
- Live hooks in `~/.claude/settings.json`: `worktree-path-guard.js` (writes stay in the active
  worktree), `worktree-branch-guard.js` (no commit to the default branch).
- ⚠️ `worktree-branch-guard.js` timed out on 2/2 observed runs and hooks fail open — verify the
  branch yourself before any git write. Do not trust the guard.
- Do NOT weaken linter/formatter configs (eslint, biome, prettier, tsconfig strictness) to pass errors.

## Dedicated Tools

<!-- Project-specific tool wrappers go here. For each, link to its skill or script
     file (e.g. `tools/reddit_fetch.py`). Orchestration logic lives in those files,
     not here — this section is just the index. Populate as recurring fetch/parse
     patterns get wrapped per the Tool Preference Ladder rule above. -->

<!-- code intelligence MCP routing -->
## Code intelligence: Graft + CodeGraph + code-review-graph

**Routing rule lives in `~/.claude/CLAUDE.md` §Code intelligence** — not restated here.
That file is always loaded, so duplicating it cost tokens in every session. The tables
below are the detail the canonical rule does not carry.

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

## Operating Principles

Constraints for every non-trivial task. Trivial tasks: use judgment.
Delegation model — I give the goal; you run it and verify, not step-by-step steering.

- **Goal-driven, not step-driven.** Define success criteria, loop until verified.
  Don't wait for the next instruction — iterate to the goal.
- **Simplicity + surgical.** Minimum code that solves it, nothing speculative.
  Touch only what the task needs; don't refactor or reformat adjacent code. Match existing style.
- **Read before you write.** Before changing code, read its exports, immediate callers,
  shared utilities. Don't assume orthogonality.
- **Code answers when code can.** Use me for judgment — classification, drafting, extraction.
  Not for routing, retries, deterministic transforms.
- **Surface conflicts, don't average.** Contradicting patterns → pick one (more recent /
  more tested), say why, flag the other. Never blend.
- **Fail loud, prove it done.** Never mark complete without proving it works — would a staff
  engineer approve this? "Done" is false if anything was skipped silently; "tests pass" is
  false if any were skipped. Surface uncertainty, don't bury it. Tests must encode *why*
  behavior matters, not just *what* it does.
- **Spend to finish.** No token self-throttling; don't stop or ask-to-continue on cost
  grounds. Avoid obvious waste (re-reading unchanged files).

On error, don't just get re-prompted — record the fix per **Self-Improvement** above so the
gap closes once, in code.
