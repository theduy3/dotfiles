#!/usr/bin/env bash
# PostToolUse hook — rename terminal tab to worktree name
# Matcher: EnterWorktree
# Writes OSC 2 escape sequence to /dev/tty to set Ghostty tab title.
# Never blocks Claude: every error path exits 0.

JQ=$(command -v jq 2>/dev/null) || exit 0
INPUT=$(cat)

# Parse worktree name from tool input
NAME=$(echo "$INPUT" | "$JQ" -r '.tool_input.name // empty' 2>/dev/null)
[[ -z "$NAME" ]] && exit 0

# Set terminal tab title via OSC 2 escape sequence
# Format: ESC ] 2 ; <title> ST
printf '\033]2;🌿 %s\033\\' "$NAME" > /dev/tty 2>/dev/null

exit 0
