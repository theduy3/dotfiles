#!/bin/bash
# Inject Obsidian vault context at session start.
# Shows recent ADRs and project-specific notes based on cwd.
# Lazy-loads: only fires if an active plan-approved task exists in ./tasks/
# or the user opted in via CLAUDE_VAULT_FORCE=1.
VAULT="$HOME/theduyvault"
ADR_DIR="$VAULT/Notes/ADR"
REGISTRY="$VAULT/Notes/Claude-Context/project-registry.md"
CWD=$(pwd)

# Gate: skip vault context unless session is resuming an active task.
# Vault remains queryable on-demand via qmd MCP.
if [ "${CLAUDE_VAULT_FORCE:-0}" != "1" ]; then
  ACTIVE_TASK=""
  if [ -d "./tasks" ]; then
    ACTIVE_TASK=$(grep -l "status: plan-approved" ./tasks/todo-*.md 2>/dev/null | head -1)
  fi
  if [ -z "$ACTIVE_TASK" ]; then
    exit 0
  fi
fi

# Check for project-specific vault note
if [ -f "$REGISTRY" ]; then
  PROJECT_NOTE=$(grep -F "$CWD" "$REGISTRY" 2>/dev/null | grep -oE '\[\[Projects/[^]]+\]\]' | tr -d '[[]]' | head -1)
  if [ -n "$PROJECT_NOTE" ]; then
    NOTE_PATH="$VAULT/$PROJECT_NOTE.md"
    if [ -f "$NOTE_PATH" ]; then
      CONTENT=$(grep -v '^[[:space:]]*$' "$NOTE_PATH" | head -60)
      if [ -n "$CONTENT" ]; then
        echo "=== Vault: Project Context ($PROJECT_NOTE) ==="
        echo "$CONTENT"
        echo ""
      fi
    fi
  fi
fi

# Show recent ADRs if any exist
if [ -d "$ADR_DIR" ] && ls "$ADR_DIR"/*.md > /dev/null 2>&1; then
  echo "=== Vault: Recent Architecture Decisions ==="
  for f in $(ls -t "$ADR_DIR"/*.md 2>/dev/null | head -3); do
    echo "--- $(basename "$f" .md) ---"
    grep -v '^[[:space:]]*$' "$f" | head -8
    echo ""
  done
fi
