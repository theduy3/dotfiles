#!/usr/bin/env bash
# PostToolUse hook — materialize untracked-but-needed files into new worktrees
# Matcher: EnterWorktree
# `git worktree add` only materializes TRACKED content, so untracked files
# never reach a new worktree. Two classes need copying:
#   1. .env* — so the app can start without a manual cp
#   2. worktree config (.mcp.json, .claude/settings.local.json) — so
#      project-scoped MCP servers are registered AND opted into. Missing
#      .mcp.json means the server is not registered at all; missing
#      settings.local.json means it is registered but not enabled. Both
#      are required for the server to load (e.g. code-review-graph in salonx,
#      which /s4-review depends on).
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

# ─── Shared copy path ────────────────────────────
# Takes a repo-relative path; echoes "copied" or "skipped" so callers stay
# side-effect free apart from their own counters. Copies (not symlinks) for
# worktree isolation, and never overwrites an existing file.
copy_if_needed() {
  local rel="$1"
  local src="$MAIN_REPO_ROOT/$rel"

  # Nothing to copy
  [[ -f "$src" ]] || { echo skipped; return; }

  # Tracked files already arrive via `git worktree add`
  git -C "$MAIN_REPO_ROOT" ls-files --error-unmatch "$rel" &>/dev/null && { echo skipped; return; }

  # Don't overwrite manual edits in the worktree
  [[ -f "$WORKTREE_PATH/$rel" ]] && { echo skipped; return; }

  mkdir -p "$(dirname "$WORKTREE_PATH/$rel")" 2>/dev/null
  cp "$src" "$WORKTREE_PATH/$rel" 2>/dev/null && { echo copied; return; }
  echo skipped
}

# ─── Pass 1: untracked .env* files (root + nested package dirs) ──────
# Recurses the repo but prunes node_modules/.git/worktrees, and keeps
# the package-relative path so monorepo packages/*/.env land correctly
# (basename alone would collapse multiple .env files onto each other).
ENV_COPIED=0
ENV_SKIPPED=0

while IFS= read -r ENV_FILE; do
  REL="${ENV_FILE#"$MAIN_REPO_ROOT"/}"
  if [[ "$(copy_if_needed "$REL")" == copied ]]; then
    ENV_COPIED=$((ENV_COPIED + 1))
  else
    ENV_SKIPPED=$((ENV_SKIPPED + 1))
  fi
done < <(find "$MAIN_REPO_ROOT" \
  \( -name node_modules -o -name .git -o -path "$MAIN_REPO_ROOT/.claude/worktrees" \) -prune \
  -o -name '.env*' -type f -print 2>/dev/null)

# ─── Pass 2: worktree config (fixed list, root-relative) ─────────────
# Explicit list rather than a glob: these are the only untracked configs a
# worktree needs, and a wildcard over .claude/ would drag in state files.
CFG_COPIED=0
CFG_SKIPPED=0

for REL in ".mcp.json" ".claude/settings.local.json"; do
  if [[ "$(copy_if_needed "$REL")" == copied ]]; then
    CFG_COPIED=$((CFG_COPIED + 1))
  else
    CFG_SKIPPED=$((CFG_SKIPPED + 1))
  fi
done

echo "worktree-env-copy: env copied $ENV_COPIED skipped $ENV_SKIPPED | config copied $CFG_COPIED skipped $CFG_SKIPPED" >&2

exit 0
