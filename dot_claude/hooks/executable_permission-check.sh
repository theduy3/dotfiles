#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook for Bash commands
# Exit codes: 0 = allow, 2 = deny, other = pass to Claude native prompt
#
# Reads JSON from stdin with structure:
#   { "tool_name": "Bash", "tool_input": { "command": "..." } }

# Require jq
if ! command -v /usr/bin/jq &>/dev/null && ! command -v jq &>/dev/null; then
  exit 0  # fail-open: no jq, let Claude handle it
fi

JQ=$(command -v /usr/bin/jq || command -v jq)

# Read stdin
INPUT=$(cat)

# Extract the command string
CMD=$(echo "$INPUT" | "$JQ" -r '.tool_input.command // empty' 2>/dev/null)

# If we can't parse the command, fail-open
if [[ -z "$CMD" ]]; then
  exit 0
fi

# ─── BLOCK LIST ───────────────────────────────────
# Dangerous patterns that should never execute

block_patterns=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf $HOME'
  'git push --force main'
  'git push --force master'
  'git push -f main'
  'git push -f master'
  'git push --force origin main'
  'git push --force origin master'
  'git push -f origin main'
  'git push -f origin master'
  'git reset --hard'
  'sudo rm '
  'sudo chmod '
  'mkfs.'
  'dd if='
  ':(){ :|:& };:'
)

# Pipe-to-shell patterns (escape | as \| to match literal pipe, not regex OR)
pipe_shell_patterns=(
  'curl.*\|.*sh'
  'curl.*\|.*bash'
  'wget.*\|.*sh'
  'wget.*\|.*bash'
)

for pattern in "${block_patterns[@]}"; do
  if [[ "$CMD" == *"$pattern"* ]]; then
    echo "BLOCKED: dangerous command detected — $pattern" >&2
    exit 2
  fi
done

for pattern in "${pipe_shell_patterns[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "BLOCKED: pipe-to-shell execution detected" >&2
    exit 2
  fi
done

# ─── ALLOW LIST ───────────────────────────────────
# Safe commands that don't need user confirmation

allow_patterns=(
  # Package managers
  '^bun '
  '^bunx '
  '^npx '
  # Git operations (non-destructive covered by block list above)
  '^git '
  # GitHub CLI
  '^gh '
  # Claude plugin management
  '^claude plugin:'
  # Common read-only / safe CLI tools
  '^ls'
  '^cat '
  '^head '
  '^tail '
  '^grep '
  '^rg '
  '^find '
  '^wc '
  '^sort '
  '^uniq '
  '^diff '
  '^echo '
  '^printf '
  '^pwd'
  '^which '
  '^whoami'
  '^env$'
  '^printenv'
  '^date'
  '^uname'
  '^file '
  # File operations
  '^mkdir '
  '^cp '
  '^mv '
  '^touch '
  # Build / runtime
  '^node '
  '^deno '
  '^python3? '
  '^ruby '
  # JSON / text processing
  '^jq '
  '^sed '
  '^awk '
  '^tr '
  '^cut '
  # Network (without pipe to shell — already blocked above)
  '^curl '
  '^wget '
  # Docker (read-only)
  '^docker ps'
  '^docker logs'
  '^docker images'
  '^docker compose'
)

# Trim leading whitespace from command for matching
TRIMMED=$(echo "$CMD" | sed 's/^[[:space:]]*//')

for pattern in "${allow_patterns[@]}"; do
  if echo "$TRIMMED" | grep -qE "$pattern"; then
    exit 0
  fi
done

# ─── UNKNOWN ──────────────────────────────────────
# Not blocked, not explicitly allowed — pass to Claude native prompt
exit 0
