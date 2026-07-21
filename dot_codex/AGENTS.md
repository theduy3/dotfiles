# Global Instructions (mirrored from Claude Code setup)

> Source of truth: `~/CLAUDE.md`, `~/.claude/rules/common/*.md`, `~/.claude/CLAUDE.md`.
> This file is a compiled digest for Codex. Re-sync inventory with
> `~/.codex/sync-claude-inventory.sh` after Claude-side changes.
> Project AGENTS.md wins on conflict.

## Persistent Memory (shared with Claude Code)

- **Index**: read `~/.claude/projects/-Users-theduy/memory/MEMORY.md` at session start
  for cross-session facts (infra topology, safety rules, active projects). One file per
  fact in the same directory.
- **Obsidian vault**: `~/theduyvault` (340+ notes). Writable: `Notes/`, `Notes/ADR/`,
  `Notes/Claude-Context/`. READ-ONLY: `Daily/`, `Tasks/`. Major architecture decisions →
  ADR at `Notes/ADR/YYYY-MM-DD-title.md`.
- **Specs/plans**: `tasks/spec-<name>.md`, `tasks/todo-<name>.md` in the active project.
- After any correction from the user: append the lesson to `tasks/lessons.md` in the
  active project (category header, one-line rule, commit hash).

## Role Playbooks

`~/.claude/agents/*.md` contains 86 role definitions (code-reviewer, security-reviewer,
planner, debugger, verifier, silent-failure-hunter, typescript-reviewer, …). When acting
in one of those capacities, read the matching file and follow its checklist inline.
Codex has no subagent registry — do the work in-session instead of spawning agents.

## Workflow Ownership (do not violate)

- **GSD** (`/gsd-*`) and the **`/s*` pipeline** are Claude Code loop owners with their own
  enforcement hooks. Do NOT run their skills from Codex; treat any `.planning/` or
  `tasks/todo-*.md` at `status: plan-approved` as owned by Claude-side `/s-auto`.
- Codex may: read state, answer questions, do standalone tasks the user assigns directly.

## Operating Principles

- Goal-driven, not step-driven: define success criteria, loop until verified.
- Simplicity + surgical: minimum code that solves it; touch only what the task needs;
  no drive-by refactors or reformatting; match existing style.
- Read before you write: exports, immediate callers, shared utilities.
- Surface conflicts, don't average: pick the more recent / better tested pattern, say why.
- Fail loud, prove it done: never claim complete without running verification. "Tests
  pass" is false if any were skipped. Evidence before assertions.
- Demand elegance on non-trivial changes; skip for simple obvious fixes.
- Spend to finish: no self-throttling on cost; avoid obvious waste.

## Coding Style (CRITICAL)

- **Immutability**: always return new objects, never mutate in place.
- **Files**: many small files > few large. 200–400 lines typical, 800 max. Organize by
  feature/domain. Functions < 50 lines, nesting ≤ 4 levels.
- **Errors**: handle explicitly at every level; user-friendly messages UI-side, detailed
  context server-side; never silently swallow.
- **Validation**: validate all input at system boundaries; schema-based where available;
  fail fast; never trust external data.
- No hardcoded values — constants or config.

## Testing

- TDD: write the failing test first (RED), minimal implementation (GREEN), refactor.
- Minimum 80% coverage; unit + integration + E2E for critical flows.
- Fix the implementation, not the test (unless the test is wrong).
- Tests must encode WHY behavior matters, not just what it does.

## Git Workflow

- Commit format: `<type>: <description>` — types: feat, fix, refactor, docs, test,
  chore, perf, ci. No AI attribution lines (disabled globally).
- PRs: analyze full commit history, `git diff base...HEAD`, comprehensive summary,
  test plan, push with `-u` for new branches.
- NEVER commit to main/master from a linked worktree. Verify branch before any git
  write operation.

## Worktree Safety (no hook enforcement in Codex — follow as hard rules)

1. Writes stay inside the active worktree; never write absolute paths that resolve to
   the main checkout while working in a worktree.
2. Before `git worktree remove`: `git worktree list`, ensure CWD is NOT inside the
   worktree being removed (cd to main repo root first), then remove. A shell whose CWD
   is unlinked dies with `posix_spawn '/bin/sh'` ENOENT on every subsequent command.
3. One worktree enter + one exit per task.

## Security (before ANY commit)

- No hardcoded secrets; env vars or secret manager; rotate anything exposed.
- Validate inputs, parameterized queries, sanitized HTML, authn/authz verified,
  no sensitive data in error messages.
- Do NOT weaken linter/formatter/tsconfig strictness to pass errors.

## Tool Preferences

- Package manager: prefer `bun run` for scripts; `install` follows the lockfile
  (`package-lock.json` → npm, `bun.lock` → bun). Project AGENTS.md overrides.
- PDFs: `pdftotext` via shell, not vision-based reading.
- Repo search: ripgrep for known scope; codegraph MCP (`codegraph_explore`) for
  architecture/trace questions — it is the pre-built index, prefer it over grep loops.
- code-review-graph MCP: check `list_graph_stats` first; if Nodes: 0 for the repo,
  fall back to grep (graph unbuilt).

## Skills

`~/.codex/skills/` holds a curated symlink set (~42) from the Claude Code skill
library — Codex's skills context budget truncates anything larger. The FULL library
(~460 skills) remains readable on demand:

- `~/.claude/skills/<name>/SKILL.md` — user library (gitnexus, seo, ads, gsd, …)
- `~/.claude/plugins/cache/*/*/*/skills/<name>/SKILL.md` — plugin libraries
  (ecc catalog: patterns/testing/security references for ~30 languages/stacks)

When a task matches a known skill that isn't in the visible list, read its SKILL.md
from the library and follow it. Re-curate with `~/.codex/sync-claude-inventory.sh`
(edit the CURATED array). Some skill bodies reference Claude-only mechanics
(Task/Agent tool, subagent spawning, Claude hooks) — do the equivalent work inline.

## Infra Quick Facts (verify in memory files before acting)

- Hostinger srv1300679 = always-on herdr/Claude box + Traefik edge; restic→B2 hourly.
- Bluehost 129.121.100.233 = hermes (Telegram) + hermes-wylios (Discord) containers,
  Syncthing master. RAM-tight — do not add services.
- Wylios coding pipeline FROZEN 2026-07-20: bots are read-only Q&A; pollers gated off.
- `entrypoint.wylios.sh`: any edit via mv/sed -i strips +x → crash loop. `chmod 755`
  after ANY edit, before `docker restart`.
