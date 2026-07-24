#!/usr/bin/env bash
# sync-claude-inventory.sh — mirror the Claude Code skill/command library into Codex.
#
# COPIES, not symlinks: Codex ignores symlinked entries in ~/.codex/prompts and
# is unreliable with symlinked skill dirs (openai/codex #3637, #4383, #5040).
# Managed copies carry a `.synced-from-claude` marker (skills) or are listed in
# `~/.codex/prompts/.synced-from-claude` (prompts); manual files are never touched.
#
# Codex enforces a skills context budget (~2% of context): syncing all ~460 Claude
# skills strips every description and silently drops most of the list. So the
# DEFAULT mode copies a curated high-value set that fits the budget; the full
# library stays readable on demand at ~/.claude/skills and the plugin caches
# (see ~/.codex/AGENTS.md "Skills" section).
#
# Usage:
#   sync-claude-inventory.sh          # curated set (default, fits budget)
#   sync-claude-inventory.sh --all    # copy everything (NOT recommended: blows budget)
#
# Idempotent: prunes stale symlinks/copies and re-copies on every run.
# Also copies ~/.claude/commands/*.md -> ~/.codex/prompts (custom prompts),
# stripping Claude-only frontmatter keys Codex doesn't understand.

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
CODEX_SKILLS="$HOME/.codex/skills"
CODEX_PROMPTS="$HOME/.codex/prompts"
SKILL_MARKER=".synced-from-claude"
PROMPT_MANIFEST="$CODEX_PROMPTS/.synced-from-claude"
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

# --- selected set for this run ---
declare -A SELECTED
if [ "$MODE" = "--all" ]; then
  echo "WARNING: --all copies ${#CANDIDATES[@]} skills; Codex will truncate the list." >&2
  for name in "${!CANDIDATES[@]}"; do SELECTED[$name]=1; done
else
  for name in "${CURATED[@]}"; do SELECTED[$name]=1; done
fi

# --- prune: old symlinks (pre-copy era) and managed copies no longer selected ---
pruned=0
while IFS= read -r -d '' link; do
  rm -- "$link"; pruned=$((pruned + 1))
done < <(find "$CODEX_SKILLS" -maxdepth 1 -type l -print0)
for existing in "$CODEX_SKILLS"/*/; do
  [ -d "${existing%/}" ] || continue
  name="$(basename "${existing%/}")"
  [ -f "${existing%/}/$SKILL_MARKER" ] || continue   # manual dir (or .system): leave alone
  if [ -z "${SELECTED[$name]:-}" ]; then
    rm -rf -- "${existing%/}"; pruned=$((pruned + 1))
  fi
done

# --- copy skills (dereference internal symlinks; manual dirs never clobbered) ---
copied=0 missing=0 skipped_manual=0
copy_skill() {
  local name="$1" src="${CANDIDATES[$1]:-}" dst="$CODEX_SKILLS/$1"
  if [ -z "$src" ]; then missing=$((missing + 1)); echo "  missing: $name" >&2; return; fi
  if [ -d "$dst" ] && [ ! -f "$dst/$SKILL_MARKER" ]; then
    skipped_manual=$((skipped_manual + 1)); echo "  skip (manual): $name" >&2; return
  fi
  rm -rf -- "$dst"
  cp -RL -- "$src" "$dst"
  printf '%s\n' "$src" > "$dst/$SKILL_MARKER"
  copied=$((copied + 1))
}
for name in "${!SELECTED[@]}"; do copy_skill "$name"; done

# --- slash commands -> custom prompts (copy + strip Claude-only frontmatter) ---
# Codex understands only `description` / `argument-hint`; keys like `context: fork`,
# `allowed-tools`, `model` are Claude-only and are dropped from the copy.
while IFS= read -r -d '' link; do
  rm -- "$link"                                      # pre-copy-era symlinks
done < <(find "$CODEX_PROMPTS" -maxdepth 1 -type l -print0)
if [ -f "$PROMPT_MANIFEST" ]; then
  while IFS= read -r old; do
    [ -n "$old" ] || continue
    [ -f "$CLAUDE_DIR/commands/$old" ] || rm -f -- "$CODEX_PROMPTS/$old"
  done < "$PROMPT_MANIFEST"
fi

prompts=0
: > "$PROMPT_MANIFEST"
for f in "$CLAUDE_DIR"/commands/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  python3 - "$f" "$CODEX_PROMPTS/$name" <<'PY'
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8") as fh:
    text = fh.read()

ALLOWED = {"description", "argument-hint"}
out = text
if text.startswith("---\n"):
    end = text.find("\n---", 4)
    if end != -1:
        head, body = text[4:end], text[end + 4:].lstrip("\n")
        kept, keep = [], False
        for line in head.splitlines():
            if line[:1] in (" ", "\t"):          # continuation of previous key
                if keep:
                    kept.append(line)
                continue
            key = line.split(":", 1)[0].strip().lower()
            keep = key in ALLOWED
            if keep:
                kept.append(line)
        out = "---\n" + "\n".join(kept) + "\n---\n\n" + body if kept else body

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(out)
PY
  printf '%s\n' "$name" >> "$PROMPT_MANIFEST"
  prompts=$((prompts + 1))
done

echo "mode=$MODE copied=$copied missing=$missing skipped_manual=$skipped_manual pruned_old=$pruned prompts=$prompts"
