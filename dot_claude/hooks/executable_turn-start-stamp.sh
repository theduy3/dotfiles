#!/bin/sh
# UserPromptSubmit hook — record the turn's start time for turn-done-timestamp.sh.
#
# CRITICAL: this hook must emit NOTHING on stdout. On exit 0 a UserPromptSubmit
# hook's stdout is injected into Claude's context, so any stray output silently
# contaminates every prompt. Everything below is wrapped in a /dev/null block.
#
# Fails open: any error leaves no marker, and the Stop hook just omits duration.

JQ=/opt/homebrew/bin/jq

{
  input=$(cat)
  sid=$(printf '%s' "$input" | "$JQ" -r '.session_id // empty')

  [ -n "$sid" ] && date +%s > "/tmp/claude-turn-start-$sid"

  # Opportunistic prune so abandoned sessions don't accumulate markers.
  find /tmp -maxdepth 1 -name 'claude-turn-start-*' -mtime +1 -delete
} >/dev/null 2>&1

exit 0
