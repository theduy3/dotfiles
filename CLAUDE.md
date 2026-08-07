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
- Remote/Android note: plan mode's ExitPlanMode blocks there (interactive UI can't be
  auto-approved), so defaulting to direct execution avoids a known stall.

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

### Self-Improvement
- After ANY correction: update `tasks/lessons.md` in the **active project**
- Write rules that prevent the same mistake recurring
- Format: category header, one-line rule, commit hash. Keep it scannable.

## Remote Mode (`CLAUDE_REMOTE=1`)

- Shipping workflows auto-merge after CI passes (no interactive confirmation)
- ExitPlanMode patched to auto-approve via hook — prefer direct implementation over plan mode
- AskUserQuestion with options still blocks — commands use defaults instead
- Patch script: `~/.local/bin/patch-claude-remote.sh` (auto-runs on `claude-remote` startup)

## Workflow Orchestration — one loop owner per arena (updated 2026-07-17)

> **One loop owner per task.** **GSD owns production** (Hermes/Wylios) plan→execute→verify→ship
> and all enforcement hooks. **`/s*` owns local single-track work** (rebuilt 2026-07-17 by
> distillation — spec `~/tasks/spec-s-star.md`, ADRs `~/tasks/s-star/docs/adr/`). **Superpowers
> stays ENABLED** as an **explicit-call leaf library** — never its workflow loops. **ECC is
> DISABLED** (2026-08-04) — see Leaf libraries below.
> (The old s0–s9 suite was deleted 2026-07-17 and replaced the same day by the distilled `/s*`.)

### The local loop → `/s*`
- `/s0-spec` (interview→spec→grill, Fable) → `/s1-plan` (todo + adversarial check, Fable) →
  **`/s-auto`** (autonomous S2→S5: implement→gates→review-panel→squash-auto-merge, unattended).
- **Seam precedence (ADR 0007):** a `tasks/todo-*.md` at `status: plan-approved` belongs to
  **`/s-auto`**. `tdd-gates` is **explicit-call-only** — never auto-select it for that Seam.
- `/s-auto` halts+pings only on: gate red, review stuck (cap-2), CI red, CI timeout 30m, merge
  conflict. Resume: `/s-auto <slug>` reads `~/tasks/.s-run/<slug>.md`.
- **Per-stage manual commands** (operator rerun/debug, added 2026-07-18): `/s2-implement`,
  `/s3-gates`, `/s4-review`, `/s5-ship`. Single stage each, no Seam ownership, never
  auto-chain — the `plan-approved` Seam still belongs to `/s-auto` alone.
- Refresh distillates **weekly** via `/update-distill` (per-Source human approval). Cadence
  changed monthly→weekly 2026-07-31.

### The prod loop → GSD
- Plan/execute/verify/ship via `/gsd-*` (`gsd-new-project`, `gsd-plan-phase`, `gsd-execute-phase`,
  `gsd-verify-work`, `gsd-progress`, `gsd-resume-work`, `gsd-workspace`). GSD's own hooks enforce it.

### Leaf libraries — invoke explicitly, never as a loop
- **Superpowers skills:** `brainstorming`, `systematic-debugging`, `test-driven-development`,
  `verification-before-completion`, `receiving-code-review`, `dispatching-parallel-agents`.
  Call at the trigger point; they no longer auto-fire (SessionStart injector gone).
- **ECC is ENABLED (2026-08-07) — `ecc:`-prefixed names DO resolve again.** Re-enabled as part of
  the global enable-everything pass, together with all other plugins. The original disable rationale
  still holds and is now *mitigated rather than avoided*: ECC's 249 skills would overflow the
  skill-listing budget at its 1% default and silently truncate *every* skill's description, so
  `skillListingBudgetFraction` is pinned to **0.25** in settings. Measured 2026-08-07: 232 skills =
  ~23.2k est. listing tokens, comfortably inside the raised budget.
  ⚠️ **Rival-loop hazard is back:** `/ecc:plan` and `/ecc:feature-dev` are reachable again and
  compete with `/s-auto` and GSD. Do not invoke them — the one-loop-owner rule above still governs.
  `npx ecc-agentshield` is a separate npm CLI and is unaffected.
- **One TDD enforcer per task:** inside GSD use `gsd-verify-work` + **`gsd-nyquist-auditor`**
  (gsd-core ships all 34 of its agents `gsd-`prefixed — the bare `nyquist-auditor` does NOT resolve);
  standalone use `superpowers:test-driven-development`.

### Harvested agents (`~/.claude/agents/`) — neutral, use under any loop
**INSTALLED (89, verified 2026-08-07)** — the whole archive was restored into `~/.claude/agents/`.
Frontmatter validated: 89/89 have `name` + `description`, zero name collisions.
- Neutral review: `code-reviewer`, `security-reviewer`, `silent-failure-hunter`, `typescript-reviewer`
- Build: `build-error-resolver` · Plan: `planner` (opus-tier — pricier than the sonnet reviewers)
- These six are `.planning/`-free, so pass `tasks/` paths normally; no path caveat applies.
- `/s*` pipeline: the ten `s-*` agents (not general-purpose — do not call directly).
- Restored 2026-08-07: 49 `gsd-*` runtime agents, plus `verifier`, `debugger`,
  `integration-checker`, `nyquist-auditor`, `performance-optimizer`, `refactor-cleaner`,
  `codebase-mapper`, `security-auditor`, 6 `audit-*`, 6 `seo-*`, and 15 display-named
  marketing/engineering/testing agents (`UI Designer`, `Backend Architect`, … — their frontmatter
  `name` contains spaces and differs from the filename; that is legal and they load fine).

⚠️ **Prefer the `gsd-*` variants under GSD.** The bare `verifier`, `debugger`,
`integration-checker`, `nyquist-auditor` are now installed alongside gsd-core's runtime
`gsd-`-prefixed equivalents — under GSD use the `gsd-*` ones.
⚠️ **The restored copies are GSD runtime variants** — their prose says `.planning/`. In particular
the neutral `planner` above is NOT the archived GSD planner; pass `tasks/` paths explicitly to the
restored agents.
- ⚠️ The archived copies are the **GSD runtime** variants — their prose says `.planning/` and some
  are `gsd-*` orchestrator-internal (the archived `planner.md` is a GSD planner, *not* the neutral
  one installed above). Restore deliberately, and pass `tasks/` paths explicitly to those.

### Hook audit (2026-06-19, updated 2026-07-17) — `~/.claude/settings.json`
- **KEEP (orchestrator-neutral safety):** `worktree-path-guard.js` (writes stay in active worktree),
  `worktree-branch-guard.js` (no commit to default branch in a worktree).
- **REMOVED 2026-07-17:** `worktree-required-guard.js` (was armed by `/s*` task state; deleted with
  the `/s*` suite — it was already unwired from settings.json).
- **ADDED 2026-07-21:** `worktree-s-auto-enforcer.sh` (PostToolUse on `EnterWorktree`) — every
  worktree entry injects the mandate to run the full `/s-auto` pipeline (S2→S5). Exempt: GSD repos
  (`.planning/` present) and worktrees already claimed by an active run in `~/tasks/.s-run/*.md`.
- **Redundant, not contradictory:** `gsd-validate-commit.sh` + `worktree-branch-guard.js` both gate
  `git commit` (different checks, both fail-open) — fine to leave.

### Deploy gate / config protection (neutral)
- `npx ecc-agentshield scan --min-severity high` before ship — scans `.claude` + MCP for exposed keys,
  over-permissive hooks, injection surface. Run manually under GSD.
- Do NOT weaken linter/formatter configs (eslint, biome, prettier, tsconfig strictness) to pass errors.

### Worktree & Vault
Details in `~/.claude/rules/common/worktree-and-vault.md` — load on demand. Key points:
- Worktree entry via built-in `EnterWorktree` (or `gsd-workspace` under GSD).
- Vault auto-inject is lazy (active task only); `CLAUDE_VAULT_FORCE=1` to force.
- Specs → `tasks/spec-*.md`, plans → `tasks/todo-*.md`.

## Dedicated Tools

<!-- Project-specific tool wrappers go here. For each, link to its skill or script
     file (e.g. `tools/reddit_fetch.py`). Orchestration logic lives in those files,
     not here — this section is just the index. Populate as recurring fetch/parse
     patterns get wrapped per the Tool Preference Ladder rule above. -->

<!-- code intelligence MCP routing -->
## MCP Tools: code intelligence (CodeGraph + code-review-graph)

**Routing rule lives in `~/.claude/CLAUDE.md` §Code intelligence** — not restated here.
That file is always loaded, so duplicating it cost tokens in every session. The tables
below are the detail the canonical rule does not carry.

### Exploration — CodeGraph FIRST

- **"How does X work" / architecture / survey an area**: `codegraph_explore` (one call, verbatim source)
- **Callers / callees / blast radius**: `codegraph_callers` / `codegraph_callees` / `codegraph_impact`
- **Symbol location**: `codegraph_search`

### Review — code-review-graph FIRST

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Blast radius of the change under review |
| `get_affected_flows` | Execution paths impacted by the diff |
| `query_graph` | Tracing tests_for / dependencies during review |

### Workflow

1. Graphs auto-update on file changes (CodeGraph: built-in watcher; code-review-graph: hooks).
2. Exploration or refactor planning → CodeGraph tools first.
3. Code review → `detect_changes`, then `get_review_context` / `get_affected_flows`.
4. Fall back to Grep/Glob/Read only when the graph doesn't cover what you need.

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
