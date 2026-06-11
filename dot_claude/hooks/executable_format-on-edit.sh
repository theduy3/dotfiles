#!/usr/bin/env bash
# format-on-edit — PostToolUse hook (Edit|Write|MultiEdit)
# Auto-formats the edited file IF a formatter already resolves locally/globally.
# Fail-open by design: never blocks, never auto-installs, silent on miss.
# Harvested idea from ECC post:quality-gate during /s* consolidation 2026-06-11.

# Read hook JSON from stdin; extract file_path. Exit 0 on any parse trouble.
input="$(cat 2>/dev/null)" || exit 0
file="$(printf '%s' "$input" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))
except Exception:
    pass' 2>/dev/null)"

[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

dir="$(dirname "$file")"
ext="${file##*.}"

# Resolve a binary: project node_modules/.bin (walk up) > global PATH. Empty if none.
resolve_bin() {
  local name="$1" d="$dir"
  while [ "$d" != "/" ]; do
    if [ -x "$d/node_modules/.bin/$name" ]; then printf '%s' "$d/node_modules/.bin/$name"; return 0; fi
    d="$(dirname "$d")"
  done
  command -v "$name" 2>/dev/null || true
}

case "$ext" in
  js|jsx|ts|tsx|mjs|cjs|json|css|scss|md)
    bin="$(resolve_bin biome)"
    if [ -n "$bin" ]; then "$bin" format --write "$file" >/dev/null 2>&1; exit 0; fi
    bin="$(resolve_bin prettier)"
    if [ -n "$bin" ]; then "$bin" --write "$file" >/dev/null 2>&1; exit 0; fi
    ;;
  go)
    bin="$(command -v gofmt)"; [ -n "$bin" ] && "$bin" -w "$file" >/dev/null 2>&1
    ;;
  py)
    bin="$(resolve_bin ruff)"
    if [ -n "$bin" ]; then "$bin" format "$file" >/dev/null 2>&1; exit 0; fi
    bin="$(command -v black)"; [ -n "$bin" ] && "$bin" -q "$file" >/dev/null 2>&1
    ;;
esac
exit 0
