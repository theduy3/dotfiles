#!/usr/bin/env bash
# PostToolUse hook — audit trail logger (Boris tip #24)
# Matcher: Write|Edit|Bash (async: true — never blocks Claude)
# Appends one line per tool call to ~/.claude/logs/YYYY-MM-DD.log

JQ=$(command -v jq 2>/dev/null) || exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | "$JQ" -r '.tool_name // "unknown"' 2>/dev/null)

# Extract key detail per tool type
case "$TOOL" in
  Bash)
    DETAIL=$(echo "$INPUT" | "$JQ" -r '.tool_input.command // ""' 2>/dev/null | head -c 200)
    ;;
  Write|Edit)
    DETAIL=$(echo "$INPUT" | "$JQ" -r '.tool_input.file_path // ""' 2>/dev/null)
    ;;
  *)
    DETAIL=$(echo "$INPUT" | "$JQ" -r '.tool_input | keys | join(", ") // ""' 2>/dev/null)
    ;;
esac

# Ensure log directory exists
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

# Append log entry
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"
echo "[$(date +%H:%M:%S)] $TOOL: $DETAIL" >> "$LOG_FILE" 2>/dev/null

exit 0
