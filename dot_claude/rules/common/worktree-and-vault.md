# Worktree Workflow & Vault Integration

> Lazy-loaded from `~/CLAUDE.md`. Reference only when session involves worktree creation, task resumption, or vault queries.

## Worktree Workflow

- **Entry**: `/s1-plan` (calls built-in `EnterWorktree`). GSD removed *from this workflow* — worktree entry/exit use built-in `EnterWorktree`/`ExitWorktree`, not `/gsd-*` commands. (The GSD *plugin* skills `/gsd-*` are still installed and registry-listed; they are a separate system, not part of the worktree flow. Note: the `gsd-plan-phase` skill is currently broken — its `~/.claude/get-shit-done/` runtime dir is missing, so its `@`-imports resolve to nothing.)
- **Setup hooks** (PostToolUse on `EnterWorktree`):
  - `~/.claude/hooks/worktree-env-copy.sh` — copies `.env*` from main into worktree
  - `~/.claude/hooks/worktree-tab-rename.sh` — sets terminal tab title
- **Cleanup**: `/s9-cleanup` (calls `ExitWorktree` + `git worktree remove`).
- **Resume**: `~/.claude/rules/common/session-resume.md` detects `status: plan-approved` in `tasks/todo-*.md`, includes stale-age gate at >14 days.

## Output Paths

- Specs: `tasks/spec-<task-name>.md` (not `docs/superpowers/specs/`)
- Plans: `tasks/todo-<task-name>.md` (not `docs/superpowers/plans/`)
- User can override complexity: "this is a small task" or "use subagents for this"

## Vault Integration

Obsidian vault at `~/theduyvault` is Claude's persistent memory. The `qmd` MCP server provides hybrid BM25+vector search across 340+ notes.

### On session start
Vault auto-injection is lazy: `~/.claude/hooks/inject-vault-context.sh` only runs if an active `tasks/todo-*.md` with `status: plan-approved` exists in cwd. Otherwise vault is silent — query via `qmd` MCP on demand.

Force-inject in any session: `CLAUDE_VAULT_FORCE=1 claude`.

### During work
- Major architecture decisions → write ADR to `Notes/ADR/YYYY-MM-DD-title.md`
- Reusable patterns discovered → update `Notes/Claude-Context/patterns.md`
- Project-specific context changes → update the project note in `Projects/`

### On session end
- Run `/vault-save` to persist session summary and any ADRs to vault

### Vault write paths (allowed by LLM per vault CLAUDE.md)
- `Notes/` — wiki pages, ADRs, Claude-managed context (Read+Write)
- `Notes/Claude-Context/sessions/` — session logs
- `Notes/ADR/` — architecture decision records
- Do NOT write to `Daily/` or `Tasks/` (read-only for LLM)
