#!/usr/bin/env bash
# Layer on top of rtk hook claude: rewraps bun run commands not handled by rtk.
# Chains: jq → outputs PreToolUse hookSpecificOutput with rewritten command.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0  # fail-open: no jq, no rewrite
fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$CMD" ]]; then
  exit 0
fi

# Skip if already wrapped
if [[ "$CMD" =~ ^rtk[[:space:]] ]]; then
  exit 0
fi

NEW=""
case "$CMD" in
  "bun run test"*|"bun run vitest"*)
    NEW="rtk test $CMD"
    ;;
  "bun run typecheck"*|"bun run tsc"*)
    NEW="rtk err $CMD"
    ;;
  "bun run build"*)
    NEW="rtk err $CMD"
    ;;
  "bun run lint"*|"bun run eslint"*)
    NEW="rtk err $CMD"
    ;;
  *)
    exit 0
    ;;
esac

jq -n --arg c "$NEW" '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecisionReason":"RTK bun wrap","updatedInput":{"command":$c},"permissionDecision":"allow"}}'
