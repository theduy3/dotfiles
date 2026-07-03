---
name: Remote Control Session Persistence & Permission Model
description: Complete analysis of /remote-control blocking from Android — three-layer permission system, CLI patch for ExitPlanMode, remote-aware commands for AskUserQuestion
type: project
---

## Remote Control Architecture

/remote-control uses Anthropic's WebSocket bridge. Android Claude Code app can send **text input** and **slash commands** only — it **cannot** interact with interactive TUI elements (arrow-key menus, yes/no prompts, selection dialogs).

## Three-Layer Permission System

```
Layer 1: Allow List (settings.json → permissions.allow)
  ↓ not matched
Layer 2: PreToolUse Hooks (shell scripts → {"decision": "approve"})
  ↓ not approved
Layer 3: Native Permission Prompt (interactive TUI on Mac terminal)
  ↓ BLOCKED on Android — session hangs
```

## Session Disconnection (Solved 2026-03-23)

**Why:** Mac sleep → WiFi drops → WebSocket breaks → server reaps idle session.

**How to apply:**
- On AC power: `sudo pmset -c sleep 0 -c displaysleep 0` (user runs manually)
- Use `claude-remote` wrapper: tmux + caffeinate + `CLAUDE_REMOTE=1` env var
- `networkoversleep 1` must be set: `sudo pmset -a networkoversleep 1`
- Stop hook `cleanup-caffeinate.sh` kills caffeinate when session ends
- Recovery from terminal crash: `tmux attach -t claude-remote`

## Permission Blocking (Solved 2026-03-24)

### Already Mitigated
- Read, Glob, Grep, WebSearch, WebFetch, Agent → allow list (L1)
- EnterPlanMode, EnterWorktree, ExitWorktree → allow list (L1)
- Safe Bash (git, gh, bun, ls, etc.) → allow list + permission-check.sh (L1+L2)
- **Write and Edit tools** → auto-approve-write-edit.sh hook with path blocklist (L2)
- **ExitPlanMode** → CLI patch: `requiresUserInteraction()` unconditionally returns `false`, then hook auto-approves (L2). Works on Android, desktop, and remote — no env var required. Patch script: `~/.local/bin/patch-claude-remote.sh`, auto-runs on `claude-remote` startup.
- **AskUserQuestion in commands** → commands modified to check `CLAUDE_REMOTE=1` and use sensible defaults (auto-merge after CI, auto-fix HIGH issues, retry CI on timeout)

### Still Blocking (~3% of cases)
- AskUserQuestion from non-command sources (e.g., brainstorming skill) — rare in remote sessions
- MCP write tools (Slack/Notion sends) — use phone's native apps instead
- Interactive bash mode (`!` prefix) — architectural, unfixable
- MCP OAuth re-auth forms — rare, requires Mac

### Safety Guardrails on Write/Edit Auto-Approve
The hook blocks writes to sensitive paths:
- `~/.ssh/`, `~/.aws/`, `~/.gnupg/`, `~/.config/gh/`
- `.env` files (except `.env.example`/`.env.template`)
- Files with "secret", "credential", "token", "password" in name
- System paths: `/etc/`, `/usr/`, `/System/`, `/Library/`

### Remote Mode Detection
`claude-remote` exports `CLAUDE_REMOTE=1`. Workflow commands can check this to skip interactive questions and use default behaviors.

### CLI Patch Maintenance
- Patch script: `~/.local/bin/patch-claude-remote.sh`
- Auto-runs on `claude-remote` wrapper startup
- Idempotent: detects already-patched state
- If CLI updates change the minified pattern: script exits 1 with clear error
- Handles 3 states: original (`if($Y())return!1;return!0`), old CLAUDE_REMOTE conditional, and already-unconditional (no-op)
- Target pattern: `requiresUserInteraction(){return!1}` (unconditional)
