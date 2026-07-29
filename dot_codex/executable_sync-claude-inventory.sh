#!/usr/bin/env bash
# sync-claude-inventory.sh — mirror the Claude Code skill/command library into Codex.
#
# COPIES, not symlinks: Codex is unreliable with symlinked skill dirs
# (openai/codex #3637, #4383, #5040). Managed skill copies carry a
# `.synced-from-claude` marker; command-derived skills carry a
# `.synced-command-from-claude` marker. Manual skill directories are never touched.
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
# Also converts ~/.claude/commands/*.md into ~/.codex/skills/<command>/SKILL.md.
# Codex 0.145 does not expose deprecated ~/.codex/prompts entries in the TUI.

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
CODEX_SKILLS="$HOME/.codex/skills"
CODEX_PROMPTS="$HOME/.codex/prompts"
SKILL_MARKER=".synced-from-claude"
COMMAND_SKILL_MARKER=".synced-command-from-claude"
PROMPT_MANIFEST="$CODEX_PROMPTS/.synced-from-claude"
MODE="${1:-curated}"

# Claude-only loop owners — never sync even with --all (subagent/hook dependent).
EXCLUDE_REGEX='^(gsd-.*|s0-spec|s1-plan|s2-implement|s3-gates|s4-review|s5-ship|s-auto)$'

# Curated set: Claude-only skills not already supplied by ~/.agents/skills or
# an enabled Codex plugin. Keeping one provider per skill avoids duplicate
# triggers and preserves the Codex skills-description context budget.
CURATED=(
  # process / quality
  unknowns
  # web / research
  last30days
  # active business domains
  seo seo-geo seo-technical seo-schema
  ads ads-audit ads-plan
  # misc
  caveman frontend-design
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

# --- remove deprecated managed prompt copies ---
# Only files recorded in the old manifest are removed; manual prompt files survive.
while IFS= read -r -d '' link; do
  rm -- "$link"                                      # pre-copy-era symlinks
done < <(find "$CODEX_PROMPTS" -maxdepth 1 -type l -print0)
if [ -f "$PROMPT_MANIFEST" ]; then
  while IFS= read -r old; do
    [ -n "$old" ] || continue
    rm -f -- "$CODEX_PROMPTS/$old"
  done < "$PROMPT_MANIFEST"
fi
: > "$PROMPT_MANIFEST"

# --- Claude commands -> Codex skills ---
# Explicit invocation is $<command-name>; /skills opens the discoverable skill list.
declare -A COMMAND_DESCRIPTIONS=(
  [analytics-agent]="Run dbt analytics workflows for model creation, review, testing, and documentation. Use for analytics engineering tasks and dbt model work."
  [db-check]="Check Supabase database health, schema quality, performance, and operational risks. Use when auditing or diagnosing a Supabase database."
  [dep-audit]="Audit project dependencies for security vulnerabilities, freshness, duplication, and unused packages. Use for dependency health reviews."
  [emergency-pr-revert]="Safely revert the most recently merged pull request and redeploy. Use only for an explicitly requested emergency rollback."
  [init-tests]="Bootstrap Vitest, Testing Library, and jsdom in a Vite React TypeScript project. Use when initializing the project's test setup."
  [security-scan]="Scan application source for security vulnerabilities and unsafe patterns. Use for a focused source-code security review."
  [state-diagram]="Generate a Mermaid stateDiagram-v2 from a described workflow or existing implementation. Use when visualizing application state transitions."
  [sync-context]="Summarize recent project activity and restore working context. Use when resuming work or preparing a concise project-context update."
  [vault-save]="Save a session summary and major architecture decisions to the configured Obsidian vault. Use when preserving project context or ADRs."
)

# Prune command-derived skills whose Claude source was deleted.
for existing in "$CODEX_SKILLS"/*/; do
  [ -d "${existing%/}" ] || continue
  [ -f "${existing%/}/$COMMAND_SKILL_MARKER" ] || continue
  name="$(basename "${existing%/}")"
  [ -f "$CLAUDE_DIR/commands/$name.md" ] || {
    rm -rf -- "${existing%/}"
    pruned=$((pruned + 1))
  }
done

command_skills=0
skipped_commands=0
for f in "$CLAUDE_DIR"/commands/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .md)"
  dst="$CODEX_SKILLS/$name"
  if [ -d "$dst" ] && [ ! -f "$dst/$COMMAND_SKILL_MARKER" ]; then
    skipped_commands=$((skipped_commands + 1))
    echo "  skip command skill (existing): $name" >&2
    continue
  fi
  rm -rf -- "$dst"
  mkdir -p "$dst/agents"
  python3 - "$f" "$dst/SKILL.md" "$dst/agents/openai.yaml" "$name" \
    "${COMMAND_DESCRIPTIONS[$name]:-Run the imported Claude command workflow named $name.}" <<'PY'
import json
import sys

src, skill_dst, ui_dst, name, description = sys.argv[1:6]
with open(src, encoding="utf-8") as fh:
    text = fh.read()

# Strip all Claude command frontmatter; synthesize valid Codex skill metadata.
body = text
if text.startswith("---\n"):
    end = text.find("\n---", 4)
    if end != -1:
        body = text[end + 4:].lstrip("\n")
body = body.replace("$ARGUMENTS", "the arguments supplied with this skill invocation")

frontmatter = (
    "---\n"
    f"name: {name}\n"
    f"description: {json.dumps(description)}\n"
    "---\n\n"
)
instructions = (
    f"# {name}\n\n"
    f"Follow this workflow imported from `{src}`. Treat text supplied after "
    f"`${name}` as the command arguments.\n\n"
)
with open(skill_dst, "w", encoding="utf-8") as fh:
    fh.write(frontmatter + instructions + body)

display_name = name.replace("-", " ").title()
short_description = description if len(description) <= 64 else description[:61].rstrip() + "..."
default_prompt = f"Use ${name} to run this workflow for the current project."
with open(ui_dst, "w", encoding="utf-8") as fh:
    fh.write(
        "interface:\n"
        f"  display_name: {json.dumps(display_name)}\n"
        f"  short_description: {json.dumps(short_description)}\n"
        f"  default_prompt: {json.dumps(default_prompt)}\n"
    )
PY
  printf '%s\n' "$f" > "$dst/$COMMAND_SKILL_MARKER"
  command_skills=$((command_skills + 1))
done

echo "mode=$MODE copied=$copied missing=$missing skipped_manual=$skipped_manual pruned_old=$pruned command_skills=$command_skills skipped_commands=$skipped_commands"
