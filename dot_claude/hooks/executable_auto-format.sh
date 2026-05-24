#!/usr/bin/env bash
# PostToolUse hook — auto-format edited files (Boris tip #7)
# Matcher: Write|Edit
# Reads tool_input.file_path from stdin JSON, formats per language.
# Never blocks Claude: every path exits 0.

# Require jq for JSON parsing
JQ=$(command -v jq 2>/dev/null) || exit 0

INPUT=$(cat)
FILE=$(echo "$INPUT" | "$JQ" -r '.tool_input.file_path // empty' 2>/dev/null)

# Nothing to format if no file path or file doesn't exist
[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

# Skip non-source files (lockfiles, configs, build artifacts, markdown)
case "$FILE" in
  *.lock|*.json|*.md|*.yml|*.yaml|*.toml|*.txt|*.csv|*.svg|*.png|*.jpg|*.gif)
    exit 0 ;;
esac

# Resolve project root (nearest package.json / go.mod / pyproject.toml)
PROJECT_ROOT=$(cd "$(dirname "$FILE")" 2>/dev/null && while [[ "$PWD" != "/" ]]; do
  [[ -f package.json || -f go.mod || -f pyproject.toml || -f setup.py ]] && echo "$PWD" && break
  cd ..
done)

# ─── Format by extension ───────────────────────
EXT="${FILE##*.}"

case "$EXT" in
  ts|tsx|js|jsx|css|scss|html)
    # Prefer project-local prettier, then global
    if [[ -n "$PROJECT_ROOT" && -x "$PROJECT_ROOT/node_modules/.bin/prettier" ]]; then
      "$PROJECT_ROOT/node_modules/.bin/prettier" --write "$FILE" 2>/dev/null || true
    elif command -v prettier &>/dev/null; then
      prettier --write "$FILE" 2>/dev/null || true
    fi
    ;;
  py)
    # Prefer ruff (faster), fall back to black
    if command -v ruff &>/dev/null; then
      ruff format "$FILE" 2>/dev/null || true
    elif command -v black &>/dev/null; then
      black --quiet "$FILE" 2>/dev/null || true
    fi
    ;;
  go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE" 2>/dev/null || true
    fi
    ;;
esac

exit 0
