# Global Configuration

> Applied to all sessions from `~`. Project-specific commands and architecture belong in each repo's CLAUDE.md. When project instructions conflict with this file, **project wins**.

## Permission Model

Read-only tools are auto-approved (no prompt): `Read`, `Glob`, `Grep`, `WebSearch`, `WebFetch`.
Safe read-only Bash commands are also auto-approved: `ls`, `cat`, `head`, `tail`, `wc`, `which`, `supabase status`, `supabase db diff`.

**Still gated (requires approval):** `Write`, `Edit`, `Agent`, destructive Bash, MCP tools (Slack/Notion sends).

## Package Manager

Prefer `bun run` over `npm run` for speed. For `install`, follow the project's lockfile (`package-lock.json` → `npm`, `bun.lock` → `bun`). Defer to project CLAUDE.md if it specifies otherwise.

## Behavioral Principles

### Plan First
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan — don't keep pushing
- Write detailed specs upfront to reduce ambiguity

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

**Recurring patterns**: Notice recurring fetch/parse patterns and propose wrapping them as dedicated tools. When the same fetch/parse logic comes up more than once, suggest wrapping it as a named tool (skill file or `.py` script with extraction baked in for that source). Add the entry to the `## Dedicated Tools` registry below and reference it by name on future calls. For 3+ repetitions in a single session, wrap immediately via Bash one-liner or `everything-claude-code:learn-eval`.

### Demand Elegance
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip for simple, obvious fixes — don't over-engineer

### Autonomous Execution
- When given a bug report: just fix it — no hand-holding
- Go fix failing CI tests without being told how
- Zero context switching required from the user

### Verification Before Done
- Never mark complete without proving it works
- Ask yourself: "Would a staff engineer approve this?"

### Self-Improvement
- After ANY correction: update `tasks/lessons.md` in the **active project**
- Write rules that prevent the same mistake recurring
- Format: category header, one-line rule, commit hash. Keep it scannable.

## Remote Mode (`CLAUDE_REMOTE=1`)

- Shipping workflows auto-merge after CI passes (no interactive confirmation)
- ExitPlanMode patched to auto-approve via hook — prefer direct implementation over plan mode
- AskUserQuestion with options still blocks — commands use defaults instead
- Patch script: `~/.local/bin/patch-claude-remote.sh` (auto-runs on `claude-remote` startup)

## Workflow Orchestration — GSD owns the loop (updated 2026-06-19)

> **One loop owner per task.** GSD (global install) owns plan→execute→verify→ship and all
> enforcement hooks. ECC + Superpowers stay ENABLED but as **explicit-call leaf libraries**
> (reviewers, build-resolvers, individual discipline skills) — never their workflow loops.
> The `/s*` suite is **deprecated for daily use** (kept on disk): it is a second full loop
> owner that duplicates GSD. Never drive one task with both `/gsd-*` and `/s*`. Full record:
> `tasks/spec-consolidation.md`; hook audit 2026-06-19 below.

### The loop → GSD
- Plan/execute/verify/ship via `/gsd-*` (`gsd-new-project`, `gsd-plan-phase`, `gsd-execute-phase`,
  `gsd-verify-work`, `gsd-progress`, `gsd-resume-work`, `gsd-workspace`). GSD's own hooks enforce it.
- `/s*` equivalents (`s0`–`s9`, `ship`, `deploy`) are the deprecated parallel loop — don't invoke for new work.

### Leaf libraries — invoke explicitly, never as a loop
- **Superpowers skills:** `brainstorming`, `systematic-debugging`, `test-driven-development`,
  `verification-before-completion`, `receiving-code-review`, `dispatching-parallel-agents`.
  Call at the trigger point; they no longer auto-fire (SessionStart injector gone).
- **ECC agents:** language reviewers (`ecc:python-reviewer`, `ecc:typescript-reviewer`, …),
  build-resolvers, `ecc:security-reviewer`. Avoid `/ecc:plan` / `/ecc:feature-dev` — those are rival loops.
- **One TDD enforcer per task:** inside GSD use `gsd-verify-work` + `nyquist-auditor`; standalone use
  `superpowers:test-driven-development`. Don't stack the user-level `/s1` TDD chain on top of GSD.

### Harvested agents (`~/.claude/agents/`) — neutral, use under any loop
- Review: `code-reviewer`, `security-reviewer`, `silent-failure-hunter`, `typescript-reviewer`
- Verify/debug: `verifier`, `debugger`, `integration-checker`, `nyquist-auditor`
- Build/perf: `build-error-resolver`, `performance-optimizer`, `refactor-cleaner`
- Plan/map/security: `planner`, `codebase-mapper`, `security-auditor`
- Pass `tasks/` paths explicitly (`tasks/spec-*.md`, `tasks/todo-*.md`) — their prose still says `.planning/`.

### Hook audit (2026-06-19) — GSD vs /s* overlap in `~/.claude/settings.json`
- **KEEP (orchestrator-neutral safety):** `worktree-path-guard.js` (writes stay in active worktree),
  `worktree-branch-guard.js` (no commit to default branch in a worktree).
- **CONFLICTS with GSD — `worktree-required-guard.js`:** blocks Write/Edit whenever a `tasks/todo-*.md`
  sits at `status: plan-approved|implementing` (that's `/s*` state). Under a GSD task with a stale s*
  plan file present it falsely blocks edits demanding `EnterWorktree`. Disable it if fully GSD-only,
  or clear stale `tasks/todo-*.md` files.
- **Redundant, not contradictory:** `gsd-validate-commit.sh` + `worktree-branch-guard.js` both gate
  `git commit` (different checks, both fail-open) — fine to leave.

### Deploy gate / config protection (neutral)
- `npx ecc-agentshield scan --min-severity high` before ship — scans `.claude` + MCP for exposed keys,
  over-permissive hooks, injection surface. (Was wired into `/s6`; run manually under GSD.)
- Do NOT weaken linter/formatter configs (eslint, biome, prettier, tsconfig strictness) to pass errors.

### Worktree & Vault
Details in `~/.claude/rules/common/worktree-and-vault.md` — load on demand. Key points:
- Worktree entry via built-in `EnterWorktree` (or `gsd-workspace` under GSD); the `/s1-plan` entry path is deprecated.
- Vault auto-inject is lazy (active task only); `CLAUDE_VAULT_FORCE=1` to force.
- Specs → `tasks/spec-*.md`, plans → `tasks/todo-*.md`.

## Dedicated Tools

<!-- Project-specific tool wrappers go here. For each, link to its skill or script
     file (e.g. `tools/reddit_fetch.py`). Orchestration logic lives in those files,
     not here — this section is just the index. Populate as recurring fetch/parse
     patterns get wrapped per the Tool Preference Ladder rule above. -->

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.

## 12-Rule Operating Template

These rules apply to every task in this project unless explicitly overridden.
Bias: caution over speed on non-trivial work. Use judgment on trivial tasks.

### Rule 1 — Think Before Coding
State assumptions explicitly. If uncertain, ask rather than guess.
Present multiple interpretations when ambiguity exists.
Push back when a simpler approach exists.
Stop when confused. Name what's unclear.

### Rule 2 — Simplicity First
Minimum code that solves the problem. Nothing speculative.
No features beyond what was asked. No abstractions for single-use code.
Test: would a senior engineer say this is overcomplicated? If yes, simplify.

### Rule 3 — Surgical Changes
Touch only what you must. Clean up only your own mess.
Don't "improve" adjacent code, comments, or formatting.
Don't refactor what isn't broken. Match existing style.

### Rule 4 — Goal-Driven Execution
Define success criteria. Loop until verified.
Don't follow steps. Define success and iterate.
Strong success criteria let you loop independently.

### Rule 5 — Use the model only for judgment calls
Use me for: classification, drafting, summarization, extraction.
Do NOT use me for: routing, retries, deterministic transforms.
If code can answer, code answers.

### Rule 6 — Spend to finish the task
No hard per-task or per-session token budget. Prioritize completing the work
over minimizing tokens; do not stop, summarize, or ask to continue purely on
cost grounds. Still avoid obvious waste (re-reading unchanged files, redundant
tool calls) — efficiency yes, self-throttling no.

### Rule 7 — Surface conflicts, don't average them
If two patterns contradict, pick one (more recent / more tested).
Explain why. Flag the other for cleanup.
Don't blend conflicting patterns.

### Rule 8 — Read before you write
Before adding code, read exports, immediate callers, shared utilities.
"Looks orthogonal" is dangerous. If unsure why code is structured a way, ask.

### Rule 9 — Tests verify intent, not just behavior
Tests must encode WHY behavior matters, not just WHAT it does.
A test that can't fail when business logic changes is wrong.

### Rule 10 — Checkpoint after every significant step
Summarize what was done, what's verified, what's left.
Don't continue from a state you can't describe back.
If you lose track, stop and restate.

### Rule 11 — Match the codebase's conventions, even if you disagree
Conformance > taste inside the codebase.
If you genuinely think a convention is harmful, surface it. Don't fork silently.

### Rule 12 — Fail loud
"Completed" is wrong if anything was skipped silently.
"Tests pass" is wrong if any were skipped.
Default to surfacing uncertainty, not hiding it.
