#!/usr/bin/env bash
# worktree-s-auto-enforcer.sh — PostToolUse hook on EnterWorktree.
# Injects the /s-auto routing mandate into model context whenever a worktree
# is entered: all worktree work must run the full S2→S5 pipeline.
# Exemptions: GSD-managed repos (.planning/ present — GSD owns that loop) and
# worktrees already claimed by an active /s-auto run (~/tasks/.s-run/*.md).
# Fail-open: any error exits 0 with no output.

set -u

input=$(cat 2>/dev/null || true)

wt_dir=$(printf '%s' "$input" | /usr/bin/env jq -r '.cwd // empty' 2>/dev/null)
if [ -z "$wt_dir" ] || [ ! -d "$wt_dir" ]; then
  wt_dir=$(pwd)
fi

emit() {
  /usr/bin/env jq -cn --arg ctx "$1" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}' 2>/dev/null || true
}

# GSD exemption: GSD owns its own plan→execute→verify→ship loop.
if [ -d "$wt_dir/.planning" ]; then
  emit "WORKTREE RULE: repo is GSD-managed (.planning/ present) — the GSD loop owns it (gsd-execute-phase → gsd-verify-work → gsd-ship). The /s-auto mandate does not apply here."
  exit 0
fi

# Worktree already claimed by an active /s-auto run → confirm, don't re-mandate.
run_dir="$HOME/tasks/.s-run"
active=""
if [ -d "$run_dir" ]; then
  active=$(grep -l -F "$wt_dir" "$run_dir"/*.md 2>/dev/null | head -1)
fi

if [ -n "$active" ]; then
  slug=$(basename "$active" .md)
  emit "WORKTREE RULE: this worktree belongs to active /s-auto run '$slug' ($run_dir/$slug.md). Continue the S2→S5 pipeline; after any context reset resume with /s-auto $slug."
  exit 0
fi

emit "WORKTREE RULE (user-mandated): ALL work in this worktree MUST go through the full /s-auto pipeline — S2 implement (test-first) → S3 real gate ladder → S4 blocking review panel → S5 ship (push, PR, CI watch, squash auto-merge). Do NOT hand-edit, commit, or ship outside the pipeline. If an approved tasks/todo-<topic>.md at status: plan-approved exists for this task, invoke /s-auto now. If no approved plan exists, stop and run /s0-spec → /s1-plan first. Per-stage commands (/s2-implement../s5-ship) are operator debug tools, not a substitute for /s-auto."

exit 0
