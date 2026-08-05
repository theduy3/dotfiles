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
  # Some repos ARE the tasks directory (e.g. ~/tasks) and keep todo-*.md at the root,
  # so the ./tasks/ probe above can never match there. Additive fallback: never fires
  # less than before, only more. (Added 2026-08-04 — the ./tasks/ assumption silently
  # skipped ~/tasks, which had 3 plan-approved todos at the time.)
  if [ -z "$ACTIVE_TASK" ]; then
    ACTIVE_TASK=$(grep -l "status: plan-approved" ./todo-*.md 2>/dev/null | head -1)
  fi
  if [ -z "$ACTIVE_TASK" ]; then
    exit 0
  fi
fi

# Check for project-specific vault note
if [ -f "$REGISTRY" ]; then
  # Match the cwd against the registry's BACKTICK-QUOTED path, not as a bare substring.
  # A bare `grep -F "$CWD"` matches every row whose path CONTAINS the cwd, so a short path
  # matches all its descendants and `head -1` returns whichever is listed first — running in
  # /Users/theduy resolved to SalonX rather than codex-setup. Anchoring on the closing
  # backtick makes the match exact: `/Users/theduy/repo/salonx` does not contain
  # `/Users/theduy` followed by a backtick. (Fixed 2026-08-04.)
  # NOTE: this requires registry paths to stay backtick-quoted, which they are.
  # A nested cwd (e.g. <project>/apps/web) still resolves to nothing, as before — walking up
  # to the nearest registered ancestor would be a behaviour change, deliberately not made here.
  PROJECT_NOTE=$(grep -F "\`$CWD\`" "$REGISTRY" 2>/dev/null | grep -oE '\[\[Projects/[^]]+\]\]' | tr -d '[[]]' | head -1)
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
