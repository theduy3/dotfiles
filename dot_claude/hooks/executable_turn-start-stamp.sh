#!/bin/sh
# UserPromptSubmit hook — record the turn's start time for turn-done-timestamp.sh.
#
# CRITICAL: this hook must emit NOTHING on stdout. On exit 0 a UserPromptSubmit
# hook's stdout is injected into Claude's context, so any stray output silently
# contaminates every prompt. Everything below is wrapped in a /dev/null block.
#
# A failed start writes an error marker so the sleep watcher can fail closed.

JQ=/opt/homebrew/bin/jq

{
  if input=$(cat) &&
    sid=$(printf '%s' "$input" | "$JQ" -r '.session_id // empty') &&
    [ -n "$sid" ] &&
    timestamp=$(date +%s) &&
    printf '%s\n' "$timestamp" > "/tmp/claude-turn-start-$sid"
  then
    rm -f /tmp/claude-turn-marker-error
  else
    date +%s > /tmp/claude-turn-marker-error
  fi
  # Opportunistic prune so abandoned sessions don't accumulate markers.
  find /tmp -maxdepth 1 -name 'claude-turn-start-*' -mtime +1 -delete
} >/dev/null 2>&1

exit 0
