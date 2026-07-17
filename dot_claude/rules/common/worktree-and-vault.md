# Worktree Workflow & Vault Integration

> Lazy-loaded from `~/CLAUDE.md`. Reference only when session involves worktree creation, task resumption, or vault queries.

## Worktree Workflow

- **Entry**: built-in `EnterWorktree` (or `gsd-workspace` under GSD). GSD owns the plan→execute→verify→ship loop.
- **Setup hooks** (PostToolUse on `EnterWorktree`):
  - `~/.claude/hooks/worktree-env-copy.sh` — copies `.env*` from main into worktree
  - `~/.claude/hooks/worktree-tab-rename.sh` — sets terminal tab title
- **Cleanup**: `ExitWorktree` in the parent, then `git worktree remove` (see `worktree-safety.md` for the CWD-ENOENT ordering contract).
- **Resume**: `/gsd-resume-work` restores context from `.planning/` state.

## Output Paths

- Specs: `tasks/spec-<task-name>.md`
- Plans: `tasks/todo-<task-name>.md`
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
