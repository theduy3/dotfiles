#!/bin/bash
# Stop/Notification hook: release caffeinate when claude is idle
# (turn done, awaiting permission, or 60s+ input idle) so Mac can sleep.

parent="$PPID"
for _ in 1 2 3 4 5; do
  [[ -z "$parent" || "$parent" == "1" ]] && break
  pname=$(ps -o comm= -p "$parent" 2>/dev/null | awk -F/ '{print $NF}')
  if [[ "$pname" == "claude" ]]; then
    pkill -P "$parent" -x caffeinate 2>/dev/null
    break
  fi
  parent=$(ps -o ppid= -p "$parent" 2>/dev/null | tr -d ' ')
done

# Legacy claude-remote wrapper pattern
[[ "$CLAUDE_REMOTE" == "1" ]] && pkill -u "$(whoami)" -f "caffeinate -dims" 2>/dev/null

exit 0
