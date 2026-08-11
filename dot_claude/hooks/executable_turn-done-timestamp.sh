#!/bin/sh
# Stop hook — show wall-clock completion time (and turn duration) to the user.
#
#   ✓ done Tue Aug 11, 11:27 AM · took 2m 11s
#
# Renders above the `recap:` away-summary, which the CLI generates lazily only
# after 5+ minutes idle.
#
# A Stop hook's plain stdout is DISCARDED on exit 0 — the message has to travel
# in the JSON `systemMessage` field. That is the CLI's own documented pattern.
#
# Fails open: no marker (or a corrupt one) just drops the "· took" clause.

JQ=/opt/homebrew/bin/jq

input=$(cat 2>/dev/null)
sid=$(printf '%s' "$input" | "$JQ" -r '.session_id // empty' 2>/dev/null)

# %-d / %-I drop zero-padding; verified supported by this macOS BSD date.
stamp="✓ done $(date '+%a %b %-d, %-I:%M %p')"

dir=${TMPDIR:-/tmp}
marker="$dir/claude-turn-start-$sid"

if [ -n "$sid" ] && [ -f "$marker" ]; then
  start=$(cat "$marker" 2>/dev/null)
  rm -f "$marker" 2>/dev/null

  case "$start" in
    '' | *[!0-9]*) ;;  # missing or non-numeric — skip the duration clause
    *)
      elapsed=$(( $(date +%s) - start ))
      if [ "$elapsed" -ge 0 ]; then
        if [ "$elapsed" -lt 60 ]; then
          human="${elapsed}s"
        elif [ "$elapsed" -lt 3600 ]; then
          human="$((elapsed / 60))m $((elapsed % 60))s"
        else
          human="$((elapsed / 3600))h $(((elapsed % 3600) / 60))m"
        fi
        stamp="$stamp · took $human"
      fi
      ;;
  esac
fi

# jq builds the JSON so quoting/escaping can't break; printf is the last resort.
"$JQ" -n --arg m "$stamp" '{systemMessage:$m}' 2>/dev/null \
  || printf '{"systemMessage":"%s"}\n' "$stamp"

exit 0
