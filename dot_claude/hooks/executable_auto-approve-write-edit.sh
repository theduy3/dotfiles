#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook for Write and Edit tools.
# Auto-approves file operations except to sensitive paths.
# Required for Android remote control which cannot interact with
# the native permission prompt TUI on the Mac terminal.
#
# Exit codes: 0 = approve (with JSON), 2 = deny
#
# Reads JSON from stdin:
#   { "tool_name": "Write|Edit", "tool_input": { "file_path": "..." } }

# Require jq
if ! command -v /usr/bin/jq &>/dev/null && ! command -v jq &>/dev/null; then
  # fail-open: no jq, approve anyway (remote user can't respond to prompt)
  echo '{"decision": "approve"}'
  exit 0
fi

JQ=$(command -v /usr/bin/jq || command -v jq)

# Read stdin
INPUT=$(cat)

# Extract the file path
FILE_PATH=$(echo "$INPUT" | "$JQ" -r '.tool_input.file_path // empty' 2>/dev/null)

# If we can't parse the path, approve (fail-open for remote usability)
if [[ -z "$FILE_PATH" ]]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# ─── SENSITIVE PATH BLOCKLIST ────────────────────
# These paths should NEVER be auto-approved.
# Writes here require physical Mac-side approval.

sensitive_patterns=(
  "$HOME/.ssh/"
  "$HOME/.aws/"
  "$HOME/.gnupg/"
  "$HOME/.config/gh/"
  "$HOME/.npmrc"
  "$HOME/.netrc"
  "$HOME/.git-credentials"
  "/etc/"
  "/usr/"
  "/System/"
  "/Library/"
)

# Block .env files anywhere (credentials risk)
if [[ "$FILE_PATH" == *".env"* && "$FILE_PATH" != *".env.example"* && "$FILE_PATH" != *".env.template"* ]]; then
  echo "BLOCKED: write to .env file requires manual approval" >&2
  exit 2
fi

# Block files with "secret", "credential", or "token" in the name
BASENAME=$(basename "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
LOWER_BASENAME=$(echo "$BASENAME" | tr '[:upper:]' '[:lower:]')
if [[ "$LOWER_BASENAME" == *"secret"* || "$LOWER_BASENAME" == *"credential"* || "$LOWER_BASENAME" == *"token"* || "$LOWER_BASENAME" == *"password"* ]]; then
  echo "BLOCKED: write to sensitive-named file requires manual approval" >&2
  exit 2
fi

# Check against sensitive path patterns
for pattern in "${sensitive_patterns[@]}"; do
  if [[ "$FILE_PATH" == "$pattern"* ]]; then
    echo "BLOCKED: write to sensitive path requires manual approval — $pattern" >&2
    exit 2
  fi
done

# ─── APPROVED ────────────────────────────────────
echo '{"decision": "approve"}'
