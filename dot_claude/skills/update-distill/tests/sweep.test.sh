#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sweep_script="$script_dir/../scripts/sweep.sh"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/update-distill-test.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

fixture_home="$fixture_root/home"
manifest_root="$fixture_home/.claude"
mkdir -p \
  "$manifest_root/skills/example" \
  "$manifest_root/plugins/cache/market/plugin/1.0.0/skills/example" \
  "$manifest_root/plugins/cache/market/plugin/2.0.0/skills/example" \
  "$manifest_root/plugins"

printf 'old source\n' > "$manifest_root/plugins/cache/market/plugin/1.0.0/skills/example/SKILL.md"
printf 'new source\n' > "$manifest_root/plugins/cache/market/plugin/2.0.0/skills/example/SKILL.md"
old_hash="$(shasum -a 256 "$manifest_root/plugins/cache/market/plugin/1.0.0/skills/example/SKILL.md" | awk '{print $1}')"

cat > "$manifest_root/plugins/installed_plugins.json" <<JSON
{
  "version": 2,
  "plugins": {
    "plugin@market": [
      {
        "installPath": "$manifest_root/plugins/cache/market/plugin/2.0.0"
      }
    ]
  }
}
JSON

cat > "$manifest_root/skills/example/.manifest.yaml" <<YAML
artifact: example
type: skill
sources:
  - path: ~/.claude/plugins/cache/market/plugin/1.0.0/skills/example/SKILL.md
    hash: $old_hash
    took: test fixture
  - path: ~/.claude/skills/missing/SKILL.md
    hash: deadbeef
    took: missing fixture
YAML

set +e
output="$(bash "$sweep_script" --home "$fixture_home" --manifest-root "$manifest_root" 2>&1)"
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  printf 'expected sweep to require attention\n%s\n' "$output" >&2
  exit 1
fi

grep -Fq $'NEWER_VERSION\t~/.claude/plugins/cache/market/plugin/1.0.0/skills/example/SKILL.md' <<<"$output"
grep -Fq $'MISSING\t~/.claude/skills/missing/SKILL.md' <<<"$output"

printf 'sweep tests passed\n'
