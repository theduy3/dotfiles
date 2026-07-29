#!/usr/bin/env bash
set -euo pipefail

task_home="${1:-$HOME}"
failed=0

for stage in s2-implement s3-gates s4-review s5-ship; do
  manifest="$task_home/.claude/skills/$stage/.manifest.yaml"
  source_count="$(awk '/^  - path: / {count++} END {print count+0}' "$manifest")"
  if [[ "$source_count" -eq 0 ]]; then
    printf '%s has no hash-tracked internal dependencies\n' "$manifest" >&2
    failed=1
  fi
done

exit "$failed"
