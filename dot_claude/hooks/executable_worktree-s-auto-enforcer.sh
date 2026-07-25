#!/usr/bin/env bash
# worktree-s-auto-enforcer.sh — PostToolUse hook on EnterWorktree.
# Injects the /s-auto routing mandate into model context whenever a worktree
# is entered: all worktree work must run the full S2→S5 pipeline.
#
# Precedence — the most explicit signal wins:
#   1. Worktree already claimed by an active /s-auto run (~/tasks/.s-run/*.md)
#   2. An /s* plan at plan-approved|implementing inside this worktree
#   3. A LIVE GSD loop                                    -> GSD exemption
#   4. Anything else                                      -> /s-auto mandate
#
# Why not `[ -d .planning ]` (the test used until 2026-07-25): a bare
# `.planning/` directory is not a live loop. Archived STATE.md files, debug
# notes and finished milestones outlive the loop that produced them, so every
# /s-auto run in such a repo was handed a "GSD owns this — run
# gsd-execute-phase → gsd-verify-work → gsd-ship" instruction it then had to
# overrule by hand (salonx: 5 such overrules recorded in ~/tasks/.s-run/).
# "Live" now means a top-level .planning/STATE.md whose frontmatter `status:`
# is executing|verifying|planning AND whose last recorded activity is within
# GSD_LIVE_LOOP_MAX_AGE_DAYS (default 7).
#
# Freshness comes from the frontmatter dates, never from file mtime:
# `git worktree add` stamps every checked-out file with the current time, so
# mtime reports a long-dead loop as fresh in exactly the case this hook runs.
#
# The ordering matters as much as the predicate. The GSD check used to run
# first, which made the active-/s-auto-run exemption below unreachable in any
# repo holding a stale `.planning/` — ambient leftovers outranked an explicit
# run-state claim.
#
# Fail-open: any error exits 0 with no output.

set -u

MAX_AGE_DAYS="${GSD_LIVE_LOOP_MAX_AGE_DAYS:-7}"
ACTIVE_GSD_STATUSES='executing|verifying|planning'

input=$(cat 2>/dev/null || true)

wt_dir=$(printf '%s' "$input" | /usr/bin/env jq -r '.cwd // empty' 2>/dev/null)
if [ -z "$wt_dir" ] || [ ! -d "$wt_dir" ]; then
  wt_dir=$(pwd)
fi

emit() {
  /usr/bin/env jq -cn --arg ctx "$1" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}' 2>/dev/null || true
}

# ------------------------------------------------------- 1. active /s-auto run
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

# --------------------------------------------------------- 2. /s* plan present
s_plan=""
for todo in "$wt_dir"/tasks/todo-*.md; do
  [ -f "$todo" ] || continue
  if sed -n '1,25p' "$todo" 2>/dev/null \
     | grep -qE '^status:[[:space:]]*(plan-approved|implementing)[[:space:]]*$'; then
    s_plan="$todo"
    break
  fi
done

# ----------------------------------------------------------- 3. live GSD loop?
# Only consulted when /s* has made no claim on this worktree.
to_epoch() {
  # YYYY-MM-DD -> epoch seconds. BSD date first, then GNU date.
  [ -n "${1:-}" ] || return 1
  date -j -f '%Y-%m-%d' "$1" '+%s' 2>/dev/null && return 0
  date -d "$1" '+%s' 2>/dev/null && return 0
  return 1
}

gsd_verdict="none"          # none | live | unknown-age
gsd_status=""
last=""
state="$wt_dir/.planning/STATE.md"

if [ -z "$s_plan" ] && [ -f "$state" ]; then
  fm=$(sed -n '1,60p' "$state" 2>/dev/null)
  gsd_status=$(printf '%s\n' "$fm" | grep -m1 -E '^status:' \
    | sed -E 's/^status:[[:space:]]*//; s/[[:space:]]*$//' | tr -d "\"'")

  if printf '%s' "$gsd_status" | grep -qE "^($ACTIVE_GSD_STATUSES)$"; then
    # Newest date the loop recorded about itself.
    last=$(printf '%s\n' "$fm" \
      | grep -E '^(last_updated|last_activity):' \
      | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1)
    last_epoch=$(to_epoch "$last" || true)
    if [ -n "${last_epoch:-}" ]; then
      age_days=$(( ( $(date '+%s') - last_epoch ) / 86400 ))
      if [ "$age_days" -le "$MAX_AGE_DAYS" ]; then
        gsd_verdict="live"
      fi
    else
      gsd_verdict="unknown-age"
    fi
  fi
fi

if [ "$gsd_verdict" = "live" ]; then
  emit "WORKTREE RULE: this repo is running a LIVE GSD loop (.planning/STATE.md status: $gsd_status, last activity $last). GSD owns its own plan→execute→verify→ship loop, so the /s-auto mandate does not apply here. Do not auto-invoke any pipeline — /s-auto included — and do not start a GSD phase on your own; defer to the operator for routing."
  exit 0
fi

if [ "$gsd_verdict" = "unknown-age" ]; then
  emit "WORKTREE RULE: .planning/STATE.md reports status: $gsd_status but records no usable last_updated/last_activity date, so this hook cannot tell a live GSD loop from an abandoned one. Routing is ambiguous: do not auto-invoke any pipeline. Ask the operator whether this worktree is /s* work (then /s-auto) or a GSD phase."
  exit 0
fi

# --------------------------------------------------------- 4. /s-auto mandate
mandate="WORKTREE RULE (user-mandated): ALL work in this worktree MUST go through the full /s-auto pipeline — S2 implement (test-first) → S3 real gate ladder → S4 blocking review panel → S5 ship (push, PR, CI watch, squash auto-merge). Stay inside the /s* agents (s-implementer, s-gate-runner, s-code-reviewer plus the conditional panel members, s-code-fixer, s-shipper) — they already distil the upstream reviewers, so do not route any stage to another workflow's commands or agents. Do NOT hand-edit, commit, or ship outside the pipeline. Per-stage commands (/s2-implement../s5-ship) are operator debug tools, not a substitute for /s-auto."

if [ -n "$s_plan" ]; then
  mandate="$mandate Approved plan present: ${s_plan#"$wt_dir"/} — invoke /s-auto now."
else
  mandate="$mandate No tasks/todo-<topic>.md at status: plan-approved here — stop and run /s0-spec → /s1-plan first."
fi

# Only report on STATE.md when step 3 actually read it. An /s* plan
# short-circuits that check, so claiming its status here would be invention.
if [ -z "$s_plan" ] && [ -f "$state" ]; then
  mandate="$mandate (A .planning/ directory is present, but its STATE.md is not a live loop — status: ${gsd_status:-unreadable}, last activity ${last:-unknown} — so it does not change routing.)"
fi

emit "$mandate"

exit 0
