#!/usr/bin/env bash
set -euo pipefail

task_home="${1:-$HOME}"
failed=0

compare_inventory() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  if ! diff -u <(printf '%s\n' "$expected") <(printf '%s\n' "$actual"); then
    printf '%s inventory differs from minimal runtime\n' "$label" >&2
    failed=1
  fi
}

expected_skills="$(printf '%s\n' \
  graph-engineering \
  s-auto \
  s0-spec \
  s1-plan \
  s2-implement \
  s3-gates \
  s4-review \
  s5-ship \
  update-distill |
  sort)"

actual_skills="$(
  find "$task_home/.claude/skills" -mindepth 2 -maxdepth 2 -type f -name 'SKILL.md' \
    -exec dirname {} \; |
    xargs -n1 basename |
    sort
)"
compare_inventory "skill" "$expected_skills" "$actual_skills"

expected_agents="$(printf '%s\n' \
  s-code-fixer \
  s-code-reviewer \
  s-gate-runner \
  s-implementer \
  s-plan-reviewer \
  s-security-reviewer \
  s-shipper \
  s-silent-failure-hunter \
  s-typescript-reviewer |
  sort)"

actual_agents="$(
  find "$task_home/.claude/agents" -maxdepth 1 -type f -name '*.md' \
    -exec basename {} .md \; |
    sort
)"
compare_inventory "agent" "$expected_agents" "$actual_agents"

command_count="$(
  find "$task_home/.claude/commands" -maxdepth 1 -type f -name '*.md' |
    wc -l |
    tr -d ' '
)"
if [[ "$command_count" -ne 0 ]]; then
  printf 'expected no active user commands, found %s\n' "$command_count" >&2
  failed=1
fi

expected_plugins="$(printf '%s\n' \
  explanatory-output-style@claude-plugins-official \
  learning-output-style@claude-plugins-official \
  typescript-lsp@claude-plugins-official |
  sort)"

actual_plugins="$(
  jq -r '.enabledPlugins | to_entries[] | select(.value == true) | .key' \
    "$task_home/.claude/settings.json" |
    sort
)"
compare_inventory "plugin" "$expected_plugins" "$actual_plugins"

exit "$failed"
