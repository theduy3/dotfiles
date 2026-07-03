# Status Line & Hooks

## Status Line
- Script: `~/.claude/statusline.sh` (bash, uses jq)
- Config in `~/.claude/settings.json` under `statusLine`
- 2-line layout:
  - Line 1: Model | Directory | Git branch + staged/modified counts
  - Line 2: Context bar (20-char, color-coded) | Cost | Duration | Output style
- Color thresholds: green (<70%), yellow (70-89%), red (90%+)
- Git info cached for 5s at `/tmp/claude-statusline-git-cache`

## Write Hook (Documentation File Blocker)
- Located in: `everything-claude-code` plugin hooks.json (both cache + marketplaces copies)
- Blocks creation of `.md` and `.txt` files except:
  - Standard docs: README.md, CLAUDE.md, AGENTS.md, CONTRIBUTING.md (anywhere)
  - `.claude/plans/` directory
  - `.claude/commands/` directory
  - `.claude/projects/*/memory/` directory (added 2026-02-28)
- Both copies must be kept in sync:
  - `.claude/plugins/cache/everything-claude-code/everything-claude-code/1.4.1/hooks/hooks.json`
  - `.claude/plugins/marketplaces/everything-claude-code/hooks/hooks.json`
- Hook changes require new session to take effect (cached in-memory)

## Tested Scenarios (all passing)
| Path | Result |
|------|--------|
| Random `.md` | Blocked |
| Random `.txt` | Blocked |
| `.claude/commands/*.md` | Allowed |
| `.claude/commands/*.txt` | Allowed |
| `.claude/plans/*.md` | Allowed |
| `.claude/plans/*.txt` | Allowed |
| `README.md` (anywhere) | Allowed |
| `CLAUDE.md` (anywhere) | Allowed |
| `AGENTS.md` (anywhere) | Allowed |
| `CONTRIBUTING.md` (anywhere) | Allowed |
