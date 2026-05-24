#!/usr/bin/env bash
# Stop hook — lightweight end-of-turn sanity check (Boris tips #13 + #24)
# Catches debug statements and conflict markers in modified files.
# Silent when clean. Outputs warnings for Claude to see and act on.

# Skip if not in a git repo
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

# Get modified files (staged + unstaged, tracked only)
MODIFIED=$(git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached 2>/dev/null)
MODIFIED=$(echo "$MODIFIED" | sort -u | grep -v '^$')

[[ -z "$MODIFIED" ]] && exit 0

WARNINGS=""

# ─── Debug statement scan ──────────────────────
DEBUG_HITS=""
while IFS= read -r file; do
  [[ ! -f "$file" ]] && continue
  case "$file" in
    # Only scan source files
    *.ts|*.tsx|*.js|*.jsx)
      HITS=$(grep -n -E '^\s*(console\.(log|debug|warn|info)\(|debugger\b)' "$file" 2>/dev/null | head -5)
      [[ -n "$HITS" ]] && DEBUG_HITS+=$(echo "$HITS" | while IFS= read -r line; do echo "  $file:$line"; done)$'\n'
      ;;
    *.py)
      HITS=$(grep -n -E '^\s*(print\(|breakpoint\(\)|import pdb|pdb\.set_trace)' "$file" 2>/dev/null | head -5)
      [[ -n "$HITS" ]] && DEBUG_HITS+=$(echo "$HITS" | while IFS= read -r line; do echo "  $file:$line"; done)$'\n'
      ;;
    *.go)
      HITS=$(grep -n -E '^\s*fmt\.Print(ln|f)?\(' "$file" 2>/dev/null | head -5)
      [[ -n "$HITS" ]] && DEBUG_HITS+=$(echo "$HITS" | while IFS= read -r line; do echo "  $file:$line"; done)$'\n'
      ;;
  esac
done <<< "$MODIFIED"

if [[ -n "$DEBUG_HITS" ]]; then
  WARNINGS+="WARNING: Debug statements found in modified files:"$'\n'
  WARNINGS+="$DEBUG_HITS"
fi

# ─── Conflict marker scan ──────────────────────
CONFLICT_HITS=""
while IFS= read -r file; do
  [[ ! -f "$file" ]] && continue
  HITS=$(grep -n -E '^(<{7}|>{7}|={7})' "$file" 2>/dev/null | head -3)
  if [[ -n "$HITS" ]]; then
    CONFLICT_HITS+=$(echo "$HITS" | while IFS= read -r line; do echo "  $file:$line"; done)$'\n'
  fi
done <<< "$MODIFIED"

if [[ -n "$CONFLICT_HITS" ]]; then
  WARNINGS+="WARNING: Conflict markers found in modified files:"$'\n'
  WARNINGS+="$CONFLICT_HITS"
fi

# Only output if there are warnings (silent majority of turns)
if [[ -n "$WARNINGS" ]]; then
  echo "$WARNINGS"
fi

exit 0
