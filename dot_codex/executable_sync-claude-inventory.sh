#!/usr/bin/env bash
# sync-claude-inventory.sh — mirror the Claude Code skill/command library into Codex.
#
# Codex enforces a skills context budget (~2% of context): linking all ~460 Claude
# skills strips every description and silently drops most of the list. So the
# DEFAULT mode links a curated high-value set that fits the budget; the full
# library stays readable on demand at ~/.claude/skills and the plugin caches
# (see ~/.codex/AGENTS.md "Skills" section).
#
# Usage:
#   sync-claude-inventory.sh          # curated set (default, fits budget)
#   sync-claude-inventory.sh --all    # link everything (NOT recommended: blows budget)
#
# Idempotent: prunes stale/broken links and relinks on every run.
# Also links ~/.claude/commands/*.md -> ~/.codex/prompts (custom prompts).

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
CODEX_SKILLS="$HOME/.codex/skills"
CODEX_PROMPTS="$HOME/.codex/prompts"
MODE="${1:-curated}"

# Claude-only loop owners — never sync even with --all (subagent/hook dependent).
EXCLUDE_REGEX='^(gsd-.*|s0-spec|s1-plan|s2-implement|s3-gates|s4-review|s5-ship|s-auto)$'

# Curated set: process discipline, code quality, and the domains in active use.
CURATED=(
  # process / quality
  brainstorming systematic-debugging tdd test-driven-development
  verification-before-completion writing-plans executing-plans
  grilling grill-with-docs unknowns diagnosing-bugs decision-mapping
  receiving-code-review requesting-code-review review
  resolving-merge-conflicts finishing-a-development-branch
  codebase-design domain-modeling setup-pre-commit
  # repo intelligence
  gitnexus-guide gitnexus-exploring gitnexus-impact-analysis gitnexus-pr-review
  # web / research
  defuddle last30days
  # obsidian vault
  obsidian-markdown obsidian-bases obsidian-cli obsidian-vault json-canvas
  # active business domains
  seo seo-audit seo-geo seo-technical seo-schema
  ads ads-audit ads-plan
  # misc
  caveman supabase-postgres-best-practices frontend-design
)

mkdir -p "$CODEX_SKILLS" "$CODEX_PROMPTS"

# --- collect all candidate skill dirs (name -> first path wins; user skills first) ---
declare -A CANDIDATES
add_candidates() {
  local root="$1" d name
  [ -d "$root" ] || return 0
  for d in "$root"/*/; do
    [ -f "${d%/}/SKILL.md" ] || continue
    name="$(basename "${d%/}")"
    [[ "$name" =~ $EXCLUDE_REGEX ]] && continue
    [ -n "${CANDIDATES[$name]:-}" ] || CANDIDATES[$name]="${d%/}"
  done
}

add_candidates "$CLAUDE_DIR/skills"
if [ -f "$CLAUDE_DIR/plugins/installed_plugins.json" ]; then
  while IFS= read -r skills_root; do
    add_candidates "$skills_root"
  done < <(python3 - <<'PY'
import json, os
home = os.path.expanduser("~")
with open(f"{home}/.claude/plugins/installed_plugins.json") as f:
    data = json.load(f)
for entries in data.get("plugins", {}).values():
    for e in entries:
        path = os.path.join(e["installPath"], "skills")
        if os.path.isdir(path):
            print(path)
PY
)
fi

# --- reset: drop every existing symlink we manage (keep .system and real dirs) ---
pruned=0
while IFS= read -r -d '' link; do
  rm -- "$link"; pruned=$((pruned + 1))
done < <(find "$CODEX_SKILLS" -maxdepth 1 -type l -print0)

# --- link ---
linked=0 missing=0
link_name() {
  local name="$1"
  local src="${CANDIDATES[$name]:-}"
  if [ -z "$src" ]; then missing=$((missing + 1)); echo "  missing: $name" >&2; return; fi
  ln -s "$src" "$CODEX_SKILLS/$name"
  linked=$((linked + 1))
}

if [ "$MODE" = "--all" ]; then
  echo "WARNING: --all links ${#CANDIDATES[@]} skills; Codex will truncate the list." >&2
  for name in "${!CANDIDATES[@]}"; do link_name "$name"; done
else
  for name in "${CURATED[@]}"; do link_name "$name"; done
fi

# --- slash commands -> custom prompts ---
while IFS= read -r -d '' link; do
  [ -e "$link" ] || rm -- "$link"
done < <(find "$CODEX_PROMPTS" -maxdepth 1 -type l -print0)
prompts=0
for f in "$CLAUDE_DIR"/commands/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  [ -e "$CODEX_PROMPTS/$name" ] || ln -s "$f" "$CODEX_PROMPTS/$name"
  prompts=$((prompts + 1))
done

echo "mode=$MODE linked=$linked missing=$missing pruned_old=$pruned prompts=$prompts"
