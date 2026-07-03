---
name: ExitPlanMode unconditionally non-interactive
description: ExitPlanMode's requiresUserInteraction() is patched to always return false in cli.js — works on Android, desktop, and remote without needing CLAUDE_REMOTE env var
type: feedback
---

ExitPlanMode is unconditionally non-interactive via a **CLI patch**. The patch at `~/.local/bin/patch-claude-remote.sh` modifies `requiresUserInteraction()` in `cli.js` to always `return!1`. The existing `auto-approve-exit-plan.sh` PreToolUse hook then auto-approves it.

**Why:** The CLI's interactive tools (`requiresUserInteraction=true`) always render React/Ink selector UI regardless of hooks or allow lists. The previous CLAUDE_REMOTE-conditional patch only worked for sessions started via the `claude-remote` wrapper — sessions started normally then connected from Android still blocked. Making it unconditional fixes all scenarios.

**How to apply:**
- The patch is auto-applied by `claude-remote` wrapper on startup, but also works manually: `bash ~/.local/bin/patch-claude-remote.sh`
- Handles three input states: original unpatched, CLAUDE_REMOTE-conditional (old), and already unconditional (no-op)
- If CLI updates break the pattern, script exits 1 with clear error — re-check `requiresUserInteraction` patterns in updated `cli.js`
- AskUserQuestion is NOT patched (its interactive UI IS the question). Commands use sensible defaults when `CLAUDE_REMOTE=1` instead.
- Without the hook, ExitPlanMode falls through to a simple yes/no permission prompt (navigable on Android) instead of the TUI selector

**Key distinction:**
- ExitPlanMode → unconditionally non-interactive (plan is already written, approval is formality)
- AskUserQuestion → needs actual input → handled by making commands remote-aware instead
