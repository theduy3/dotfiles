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
  local removed_flag="${4:-}"
  local rejected_hash="${5:-}"
  # "-" is the emitted placeholder for an absent optional field; normalize it away here so
  # every downstream test is a plain empty-string check. Written as `if` rather than
  # `[[ … ]] && x=""` because under `set -e` a top-level AND-list whose condition is false
  # returns non-zero and would abort the sweep on the common path.
  if [[ "$removed_flag" == "-" ]]; then removed_flag=""; fi
  if [[ "$rejected_hash" == "-" ]]; then rejected_hash=""; fi
  local resolved_path current_path actual_hash

  resolved_path="$(resolve_path "$source_path")"
  current_path="$(current_plugin_source "$resolved_path" 2>/dev/null || true)"

  if [[ -n "$current_path" && "$current_path" != "$resolved_path" && -f "$current_path" ]]; then
    printf 'NEWER_VERSION\t%s\t%s\t%s\n' "$source_path" "$current_path" "$manifest_file"
    attention_required=1
    return
  fi

  if [[ ! -f "$resolved_path" ]]; then
    # A row carrying `removed:` records a decision already taken about THIS absence.
    # Report it so the sweep never hides a row, but do not demand attention again —
    # re-raising a settled decision every month is how a recorded decision becomes noise.
    # Scoped to absence only: if the Source ever returns, the branches below fire normally,
    # because a Source coming back is news.
    if [[ -n "$removed_flag" ]]; then
      printf 'REMOVED_ACK\t%s\t%s\n' "$source_path" "$manifest_file"
      return
    fi
    printf 'MISSING\t%s\t%s\n' "$source_path" "$manifest_file"
    attention_required=1
    return
  fi

  actual_hash="$(shasum -a 256 "$resolved_path" | awk '{print $1}')"
  if [[ "$actual_hash" == "$expected_hash" ]]; then
    printf 'OK\t%s\t%s\n' "$source_path" "$manifest_file"
    return
  fi

  # `rejected:` is deliberately HASH-SCOPED, per the skill's own wording: skip an
  # "unchanged-since-rejection hash". A rejection settles one VERSION of a Source, never
  # the Source itself — drift past the rejected hash must fire again, or one rejection
  # silences that row forever, which is strictly worse than the noise it was meant to fix.
  if [[ -n "$rejected_hash" && "$actual_hash" == "$rejected_hash" ]]; then
    printf 'REJECTED_ACK\t%s\t%s\n' "$source_path" "$manifest_file"
    return
  fi

  printf 'CHANGED\t%s\t%s\n' "$source_path" "$manifest_file"
  attention_required=1
}

while IFS=$'\t' read -r manifest_file source_path expected_hash removed_flag rejected_hash; do
  check_source "$manifest_file" "$source_path" "$expected_hash" "$removed_flag" "$rejected_hash"
done < <(
  find "$manifest_root/skills" "$manifest_root/agents" \
    -type f -name '.manifest.yaml' -o -type f -name '.s-*.manifest.yaml' 2>/dev/null |
    sort |
    while read -r manifest_file; do
      # Records are BUFFERED and flushed at the next `- path:` (and at END), not printed on
      # sight of `hash:`. `removed:`/`rejected:` follow `hash:` inside a row, so printing at
      # `hash:` would emit the record before those lines had been read — and dropping the
      # END flush would silently discard the last row of every manifest.
      awk -v manifest="$manifest_file" '
        # Empty optional fields are emitted as "-", never as an empty column. Bash treats
        # TAB as IFS whitespace and collapses runs of it, so a row with removed empty and
        # rejected set would emit two adjacent tabs, they would collapse to one, and the
        # rejected hash would be read into removed_flag. That is the COMMON combination
        # (a rejection without a removal) and it fails silently.
        function flush() {
          if (path == "") return
          print manifest "\t" path "\t" hash "\t" (removed == "" ? "-" : removed) "\t" (rejected == "" ? "-" : rejected)
          path=""; hash=""; removed=""; rejected=""
        }
        /^  - path: / {
          flush()
          path=$0
          sub(/^  - path: /, "", path)
        }
        /^    hash: / {
          hash=$0
          sub(/^    hash: /, "", hash)
        }
        /^    removed:/ { removed="1" }
        /^    rejected: / {
          rejected=$0
          sub(/^    rejected: /, "", rejected)
          sub(/[ \t].*$/, "", rejected)
        }
        END { flush() }
      ' "$manifest_file"
    done
)

exit "$attention_required"
