#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
shift || true

task_home="${HOME}"
state_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home)
      task_home="$2"
      shift 2
      ;;
    --state)
      state_file="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

state_file="${state_file:-$task_home/.claude/update-distill/source-catalog.tsv}"

component_paths() {
  local component_root

  component_root="$task_home/.claude/skills-archive"
  [[ ! -d "$component_root" ]] || find "$component_root" -type f -iname 'skill.md'

  component_root="$task_home/.claude/agents-archive"
  [[ ! -d "$component_root" ]] || find "$component_root" -type f -name '*.md'

  component_root="$task_home/.agents/skills"
  [[ ! -d "$component_root" ]] || find "$component_root" -type f -iname 'skill.md'

  component_root="$task_home/.claude/gsd-core/workflows"
  [[ ! -d "$component_root" ]] || find "$component_root" -type f -name '*.md'

  catalog_roots="$task_home/.claude/update-distill/catalog-roots.txt"
  if [[ -f "$catalog_roots" ]]; then
    while read -r component_root; do
      [[ -n "$component_root" && -d "$component_root" ]] || continue
      find "$component_root" -type f -iname 'skill.md'
    done < "$catalog_roots"
  fi

  installed_plugins="$task_home/.claude/plugins/installed_plugins.json"
  [[ -f "$installed_plugins" ]] || return 0

  jq -r '.plugins | to_entries[] | .value[0].installPath' "$installed_plugins" |
    while read -r component_root; do
      [[ -d "$component_root" ]] || continue
      [[ ! -d "$component_root/skills" ]] ||
        find "$component_root/skills" -mindepth 2 -maxdepth 2 -type f -iname 'skill.md'
      [[ ! -d "$component_root/agents" ]] ||
        find "$component_root/agents" -maxdepth 1 -type f -name '*.md'
      [[ ! -d "$component_root/commands" ]] ||
        find "$component_root/commands" -maxdepth 1 -type f -name '*.md'
    done
}

inventory() {
  local source_file logical_path source_hash

  component_paths |
    sort -u |
    while read -r source_file; do
      [[ -f "$source_file" ]] || continue
      logical_path="${source_file/#"$task_home"/\~}"
      source_hash="$(shasum -a 256 "$source_file" | awk '{print $1}')"
      printf '%s\t%s\n' "$source_hash" "$logical_path"
    done
}

snapshot() {
  local state_dir temp_file

  state_dir="$(dirname "$state_file")"
  mkdir -p "$state_dir"
  temp_file="$(mktemp "$state_dir/source-catalog.XXXXXX")"
  trap "rm -f '$temp_file'" EXIT
  inventory > "$temp_file"
  mv "$temp_file" "$state_file"
  trap - EXIT
  printf 'catalog snapshot: %s entries\n' "$(wc -l < "$state_file" | tr -d ' ')"
}

diff_catalog() {
  local temp_file delta_file delta_count

  [[ -f "$state_file" ]] || {
    printf 'catalog snapshot missing: %s\n' "$state_file" >&2
    exit 2
  }

  temp_file="$(mktemp "${TMPDIR:-/tmp}/source-catalog-current.XXXXXX")"
  delta_file="$(mktemp "${TMPDIR:-/tmp}/source-catalog-delta.XXXXXX")"
  trap "rm -f '$temp_file' '$delta_file'" EXIT
  inventory > "$temp_file"

  awk -F '\t' '
    NR == FNR {
      old_hash[$2]=$1
      next
    }
    {
      current[$2]=1
      if (!($2 in old_hash)) {
        print "NEW\t" $2
      } else if (old_hash[$2] != $1) {
        print "CHANGED\t" $2
      }
    }
    END {
      for (path in old_hash) {
        if (!(path in current)) {
          print "REMOVED\t" path
        }
      }
    }
  ' "$state_file" "$temp_file" | sort > "$delta_file"

  delta_count="$(wc -l < "$delta_file" | tr -d ' ')"
  if [[ "$delta_count" -eq 0 ]]; then
    printf 'catalog unchanged\n'
    return
  fi

  cat "$delta_file"
  return 1
}

case "$action" in
  snapshot)
    snapshot
    ;;
  diff)
    diff_catalog
    ;;
  *)
    printf 'usage: catalog.sh snapshot|diff [--home PATH] [--state PATH]\n' >&2
    exit 2
    ;;
esac
