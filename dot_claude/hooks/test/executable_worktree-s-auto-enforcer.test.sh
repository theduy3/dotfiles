#!/usr/bin/env bash
# Branch coverage for worktree-s-auto-enforcer.sh.
#
# Run:  bash ~/.claude/hooks/test/worktree-s-auto-enforcer.test.sh
#
# Each case builds a throwaway $HOME + worktree, feeds the hook the PostToolUse
# stdin payload it would get from EnterWorktree, and asserts on the emitted
# additionalContext. HOME is overridden per case so the ~/tasks/.s-run lookup
# is isolated from the real machine.

set -u

# Resolve the hook under both names: `worktree-...` once chezmoi has applied it,
# `executable_worktree-...` when running straight out of the chezmoi source tree.
HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${HOOK_OVERRIDE:-}"
if [ -z "$HOOK" ]; then
  for candidate in \
    "$HOOK_DIR/worktree-s-auto-enforcer.sh" \
    "$HOOK_DIR/executable_worktree-s-auto-enforcer.sh"; do
    [ -f "$candidate" ] && { HOOK="$candidate"; break; }
  done
fi
[ -n "$HOOK" ] && [ -f "$HOOK" ] || { echo "FATAL: hook not found under $HOOK_DIR"; exit 1; }
echo "hook under test: $HOOK"

pass=0; fail=0

days_ago() { # N -> YYYY-MM-DD
  date -v-"$1"d '+%Y-%m-%d' 2>/dev/null && return 0
  date -d "$1 days ago" '+%Y-%m-%d' 2>/dev/null && return 0
  return 1
}

# Builds a sandbox, runs the hook, echoes the additionalContext string.
# $1 = case name; remaining env set by caller via SANDBOX_* helpers.
run_hook() {
  local home="$1" wt="$2"
  printf '{"cwd":"%s"}' "$wt" | HOME="$home" bash "$HOOK" 2>/dev/null \
    | /usr/bin/env jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null
}

assert_contains() { # name haystack needle
  if printf '%s' "$2" | grep -qF -- "$3"; then
    pass=$((pass+1)); echo "  ok   $1"
  else
    fail=$((fail+1)); echo "  FAIL $1"; echo "       expected to contain: $3"; echo "       got: $2"
  fi
}

assert_absent() { # name haystack needle
  if printf '%s' "$2" | grep -qF -- "$3"; then
    fail=$((fail+1)); echo "  FAIL $1"; echo "       expected NOT to contain: $3"; echo "       got: $2"
  else
    pass=$((pass+1)); echo "  ok   $1"
  fi
}

new_sandbox() { # -> prints "HOME WT"
  local root; root=$(mktemp -d)
  mkdir -p "$root/home/tasks/.s-run" "$root/wt/tasks"
  printf '%s %s' "$root/home" "$root/wt"
}

# Writes a .planning/STATE.md with the given status / last_updated.
write_state() { # wt status last_updated_or_empty
  mkdir -p "$1/.planning"
  {
    echo "---"
    echo "gsd_state_version: 1.0"
    echo "status: $2"
    [ -n "${3:-}" ] && echo "last_updated: \"$3T12:00:00.000Z\""
    echo "---"
    echo ""
    echo "# Project State"
  } > "$1/.planning/STATE.md"
}

write_todo() { # wt status
  cat > "$1/tasks/todo-demo.md" <<EOF
---
task: demo
status: $2
---
# Plan
EOF
}

echo "worktree-s-auto-enforcer.sh"

# --- 1. REGRESSION: active /s-auto run must outrank a stale .planning/ --------
# Before the fix the GSD check ran first, so this branch was unreachable in any
# repo holding leftover planning files.
read -r H W <<<"$(new_sandbox)"
write_state "$W" "verifying" "$(days_ago 18)"
echo "worktree: $W" > "$H/tasks/.s-run/demo-slug.md"
out=$(run_hook "$H" "$W")
assert_contains "active run claims worktree despite stale .planning/" "$out" "active /s-auto run 'demo-slug'"
assert_absent   "  ...and emits no GSD handoff"                        "$out" "GSD owns"

# --- 2. /s* plan present alongside a stale .planning/ ------------------------
read -r H W <<<"$(new_sandbox)"
write_state "$W" "verifying" "$(days_ago 18)"
write_todo  "$W" "plan-approved"
out=$(run_hook "$H" "$W")
assert_contains "plan-approved todo wins over stale .planning/" "$out" "invoke /s-auto now"
assert_absent   "  ...names no gsd-* command"                   "$out" "gsd-execute-phase"
# Step 3 never reads STATE.md when a plan short-circuits it, so the message
# must not report a status it did not look up.
assert_absent   "  ...invents no STATE.md status"               "$out" "status: unreadable"

# --- 3. LIVE GSD loop keeps its exemption -----------------------------------
read -r H W <<<"$(new_sandbox)"
write_state "$W" "executing" "$(days_ago 1)"
out=$(run_hook "$H" "$W")
assert_contains "fresh executing loop is exempt"      "$out" "LIVE GSD loop"
assert_absent   "  ...but is not told to run GSD"     "$out" "gsd-execute-phase"

# --- 4. THE salonx CASE: active status, long stale -> mandate ----------------
read -r H W <<<"$(new_sandbox)"
write_state "$W" "verifying" "$(days_ago 18)"
out=$(run_hook "$H" "$W")
assert_contains "18-day-stale verifying loop yields /s-auto mandate" "$out" "MUST go through the full /s-auto pipeline"
assert_contains "  ...and explains the dormant .planning/"          "$out" "not a live loop"
assert_absent   "  ...with no GSD exemption"                        "$out" "LIVE GSD loop"

# --- 5. Terminal status, even fresh, is not a live loop ----------------------
read -r H W <<<"$(new_sandbox)"
write_state "$W" "complete" "$(days_ago 0)"
out=$(run_hook "$H" "$W")
assert_contains "fresh 'complete' status yields mandate" "$out" "MUST go through the full /s-auto pipeline"

# --- 6. Active status but undatable -> ambiguous, no auto-routing ------------
read -r H W <<<"$(new_sandbox)"
write_state "$W" "executing" ""
out=$(run_hook "$H" "$W")
assert_contains "undatable active loop is ambiguous" "$out" "Routing is ambiguous"
assert_absent   "  ...and mandates nothing"          "$out" "MUST go through the full"

# --- 7. Plain repo, no .planning/ -------------------------------------------
read -r H W <<<"$(new_sandbox)"
out=$(run_hook "$H" "$W")
assert_contains "plain repo gets the mandate"       "$out" "MUST go through the full /s-auto pipeline"
assert_contains "  ...and is told to spec/plan"     "$out" "/s0-spec"
assert_absent   "  ...mentions no .planning/"       "$out" ".planning/ directory is present"

# --- 8. Mandate always pins the panel to /s* agents --------------------------
assert_contains "mandate names the /s* agents" "$out" "s-implementer"
assert_absent   "mandate routes to no other workflow" "$out" "gsd-"

# --- 9. Fail-open on garbage stdin ------------------------------------------
if printf 'not json' | HOME="$H" bash "$HOOK" >/dev/null 2>&1; then
  pass=$((pass+1)); echo "  ok   garbage stdin exits 0 (fail-open)"
else
  fail=$((fail+1)); echo "  FAIL garbage stdin should exit 0"
fi

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
