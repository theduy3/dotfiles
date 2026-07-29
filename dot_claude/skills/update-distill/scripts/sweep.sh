#!/usr/bin/env bash
set -euo pipefail

task_home="${HOME}"
manifest_root=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home)
      task_home="$2"
      shift 2
      ;;
    --manifest-root)
      manifest_root="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

manifest_root="${manifest_root:-$task_home/.claude}"
installed_plugins="$manifest_root/plugins/installed_plugins.json"
attention_required=0

resolve_path() {
  local source_path="$1"
  printf '%s\n' "${source_path/#\~/$task_home}"
}

current_plugin_source() {
  local resolved_path="$1"
  local cache_prefix="$manifest_root/plugins/cache/"
  local relative market plugin version suffix plugin_id install_path

  [[ "$resolved_path" == "$cache_prefix"* ]] || return 1
  relative="${resolved_path#"$cache_prefix"}"
  IFS='/' read -r market plugin version suffix <<<"$relative"
  [[ -n "$market" && -n "$plugin" && -n "$version" && -n "$suffix" ]] || return 1
  suffix="${relative#"$market/$plugin/$version/"}"
  plugin_id="$plugin@$market"
  [[ -f "$installed_plugins" ]] || return 1

  install_path="$(jq -r --arg id "$plugin_id" '.plugins[$id][0].installPath // empty' "$installed_plugins")"
  [[ -n "$install_path" ]] || return 1
  printf '%s/%s\n' "$install_path" "$suffix"
}

check_source() {
  local manifest_file="$1"
  local source_path="$2"
  local expected_hash="$3"
  local resolved_path current_path actual_hash

  resolved_path="$(resolve_path "$source_path")"
  current_path="$(current_plugin_source "$resolved_path" 2>/dev/null || true)"

  if [[ -n "$current_path" && "$current_path" != "$resolved_path" && -f "$current_path" ]]; then
    printf 'NEWER_VERSION\t%s\t%s\t%s\n' "$source_path" "$current_path" "$manifest_file"
    attention_required=1
    return
  fi

  if [[ ! -f "$resolved_path" ]]; then
    printf 'MISSING\t%s\t%s\n' "$source_path" "$manifest_file"
    attention_required=1
    return
  fi

  actual_hash="$(shasum -a 256 "$resolved_path" | awk '{print $1}')"
  if [[ "$actual_hash" == "$expected_hash" ]]; then
    printf 'OK\t%s\t%s\n' "$source_path" "$manifest_file"
  else
    printf 'CHANGED\t%s\t%s\n' "$source_path" "$manifest_file"
    attention_required=1
  fi
}

while IFS=$'\t' read -r manifest_file source_path expected_hash; do
  check_source "$manifest_file" "$source_path" "$expected_hash"
done < <(
  find "$manifest_root/skills" "$manifest_root/agents" \
    -type f -name '.manifest.yaml' -o -type f -name '.s-*.manifest.yaml' 2>/dev/null |
    sort |
    while read -r manifest_file; do
      awk -v manifest="$manifest_file" '
        /^  - path: / {
          path=$0
          sub(/^  - path: /, "", path)
        }
        /^    hash: / {
          hash=$0
          sub(/^    hash: /, "", hash)
          print manifest "\t" path "\t" hash
        }
      ' "$manifest_file"
    done
)

exit "$attention_required"
