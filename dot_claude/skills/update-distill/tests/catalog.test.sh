#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
catalog_script="$script_dir/../scripts/catalog.sh"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/update-distill-catalog-test.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

fixture_home="$fixture_root/home"
state_file="$fixture_root/catalog.tsv"
skill_a="$fixture_home/.claude/skills-archive/a/SKILL.md"
skill_b="$fixture_home/.claude/skills-archive/b/SKILL.md"
project_skill="$fixture_root/project/.claude/skills-archive/local/skill.md"

mkdir -p "$(dirname "$skill_a")" "$(dirname "$skill_b")" "$(dirname "$project_skill")"
printf 'a-v1\n' > "$skill_a"
printf 'b-v1\n' > "$skill_b"
printf 'project-v1\n' > "$project_skill"
mkdir -p "$fixture_home/.claude/update-distill"
printf '%s\n' "$fixture_root/project/.claude/skills-archive" \
  > "$fixture_home/.claude/update-distill/catalog-roots.txt"

bash "$catalog_script" snapshot --home "$fixture_home" --state "$state_file"

printf 'a-v2\n' > "$skill_a"
printf 'project-v2\n' > "$project_skill"
mv "$skill_b" "$fixture_root/b-retired.md"
mkdir -p "$fixture_home/.claude/skills-archive/c"
printf 'c-v1\n' > "$fixture_home/.claude/skills-archive/c/SKILL.md"

set +e
output="$(bash "$catalog_script" diff --home "$fixture_home" --state "$state_file" 2>&1)"
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  printf 'expected catalog diff to require review\n%s\n' "$output" >&2
  exit 1
fi

grep -Fq $'CHANGED\t~/.claude/skills-archive/a/SKILL.md' <<<"$output"
grep -Fq $'CHANGED\t'"$project_skill" <<<"$output"
grep -Fq $'REMOVED\t~/.claude/skills-archive/b/SKILL.md' <<<"$output"
grep -Fq $'NEW\t~/.claude/skills-archive/c/SKILL.md' <<<"$output"

printf 'catalog tests passed\n'
