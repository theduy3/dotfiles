#!/usr/bin/env bash
# Stop hook — append minimal session breadcrumb to Obsidian vault.
# Scoped to projects listed in project-registry.md. Silent no-op elsewhere.
# Never blocks Stop: always exits 0.

set +e

VAULT="$HOME/theduyvault"
REGISTRY="$VAULT/Notes/Claude-Context/project-registry.md"
SESSIONS_DIR="$VAULT/Notes/Claude-Context/sessions"
CWD=$(pwd)

[[ ! -f "$REGISTRY" ]] && exit 0

PROJECT_NOTE=$(grep -F "$CWD" "$REGISTRY" 2>/dev/null \
  | grep -oE '\[\[Projects/[^]]+\]\]' \
  | tr -d '[]' \
  | head -1)

[[ -z "$PROJECT_NOTE" ]] && exit 0

mkdir -p "$SESSIONS_DIR" 2>/dev/null

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
LOG="$SESSIONS_DIR/$DATE.md"

BRANCH=""
LAST_COMMIT=""
MODIFIED=""
if git rev-parse --is-inside-work-tree &>/dev/null; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  LAST_COMMIT=$(git log -1 --pretty=format:'%h %s' 2>/dev/null)
  MODIFIED=$(git diff --name-only HEAD 2>/dev/null | head -20)
fi

PROJECT_NAME=$(basename "$CWD")

if [[ ! -f "$LOG" ]]; then
  cat > "$LOG" <<EOF
---
type: session-log
created: $DATE
---

# Session Log — $DATE

EOF
fi

{
  echo ""
  echo "## $TIME — $PROJECT_NAME"
  echo ""
  echo "- **Project:** [[$PROJECT_NOTE]]"
  echo "- **CWD:** \`$CWD\`"
  [[ -n "$BRANCH" ]]      && echo "- **Branch:** \`$BRANCH\`"
  [[ -n "$LAST_COMMIT" ]] && echo "- **Last commit:** $LAST_COMMIT"
  if [[ -n "$MODIFIED" ]]; then
    echo "- **Modified files:**"
    while IFS= read -r f; do
      [[ -n "$f" ]] && echo "    - \`$f\`"
    done <<< "$MODIFIED"
  fi
} >> "$LOG"

exit 0
