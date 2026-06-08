#!/usr/bin/env bash
# PostToolUse hook — auto-copy .env* files into new worktrees
# Matcher: EnterWorktree
# Copies untracked .env* files from the main repo root into the new
# worktree so the app can start without manual cp.
# Never blocks Claude: every error path exits 0.

# Require jq for JSON parsing
JQ=$(command -v jq 2>/dev/null) || exit 0

INPUT=$(cat)

# ─── Parse worktree path ──────────────────────────
# Try tool_response fields first (path, worktreePath), then construct from cwd + name
WORKTREE_PATH=$(echo "$INPUT" | "$JQ" -r '
  .tool_response.path //
  .tool_response.worktreePath //
  empty' 2>/dev/null)

if [[ -z "$WORKTREE_PATH" ]]; then
  # Fallback: construct from cwd + .claude/worktrees/ + name
  CWD=$(echo "$INPUT" | "$JQ" -r '.cwd // empty' 2>/dev/null)
  NAME=$(echo "$INPUT" | "$JQ" -r '.tool_input.name // empty' 2>/dev/null)
  if [[ -n "$CWD" && -n "$NAME" ]]; then
    WORKTREE_PATH="$CWD/.claude/worktrees/$NAME"
  fi
fi

[[ -z "$WORKTREE_PATH" || ! -d "$WORKTREE_PATH" ]] && exit 0

# ─── Find main repo root ─────────────────────────
COMMON_GIT_DIR=$(git -C "$WORKTREE_PATH" rev-parse --git-common-dir 2>/dev/null) || exit 0

# Resolve to absolute path (--git-common-dir may return relative)
COMMON_GIT_DIR=$(cd "$WORKTREE_PATH" && cd "$COMMON_GIT_DIR" && pwd)
MAIN_REPO_ROOT=$(dirname "$COMMON_GIT_DIR")

# Guard: skip if worktree IS the main repo (not actually a worktree)
[[ "$MAIN_REPO_ROOT" == "$WORKTREE_PATH" ]] && exit 0

# ─── Copy untracked .env* files (root + nested package dirs) ──────
# Recurses the repo but prunes node_modules/.git/worktrees, and keeps
# the package-relative path so monorepo packages/*/.env land correctly
# (basename alone would collapse multiple .env files onto each other).
COPIED=0
SKIPPED=0

while IFS= read -r ENV_FILE; do
  REL="${ENV_FILE#"$MAIN_REPO_ROOT"/}"

  # Skip if file is tracked by git
  if git -C "$MAIN_REPO_ROOT" ls-files --error-unmatch "$REL" &>/dev/null; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Skip if file already exists in worktree (don't overwrite manual edits)
  if [[ -f "$WORKTREE_PATH/$REL" ]]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Copy (not symlink) for isolation, recreating package subdirs
  mkdir -p "$(dirname "$WORKTREE_PATH/$REL")" 2>/dev/null
  cp "$ENV_FILE" "$WORKTREE_PATH/$REL" 2>/dev/null && COPIED=$((COPIED + 1))
done < <(find "$MAIN_REPO_ROOT" \
  \( -name node_modules -o -name .git -o -path "$MAIN_REPO_ROOT/.claude/worktrees" \) -prune \
  -o -name '.env*' -type f -print 2>/dev/null)

echo "worktree-env-copy: copied $COPIED, skipped $SKIPPED .env* file(s)" >&2

exit 0
