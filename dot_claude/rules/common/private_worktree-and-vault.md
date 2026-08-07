---
paths:
  - ".claude/**"
  - "**/CLAUDE.md"
  - "**/settings*.json"
---

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
⚠️ **NOT WIRED (verified 2026-08-07).** `~/.claude/hooks/inject-vault-context.sh` exists on disk
but is registered in no settings file, so it never runs — and `CLAUDE_VAULT_FORCE=1` does nothing.
Query the vault via `qmd` MCP on demand instead.

The script itself is sound and cheap: it self-gates on an active `tasks/todo-*.md` at
`status: plan-approved` in cwd, spawns no network calls, and no-ops otherwise. To enable it,
register it as a `SessionStart` hook in `~/.claude/settings.json` — but remember that file is a
chezmoi **template**, so the edit must go in `dot_claude/settings.json.tmpl` or the hourly
`claude-sync` will revert it.

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
