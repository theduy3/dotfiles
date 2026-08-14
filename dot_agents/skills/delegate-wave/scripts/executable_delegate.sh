#!/usr/bin/env bash
# delegate-wave helper: spawn, monitor, and clean up `pi` workers running
# inside dedicated tmux sessions, one worker per delegated task.
#
# Every worker is a plain `pi -p` (print-mode, non-interactive) invocation.
# Print mode exits the process when the turn is done, so completion is a
# real process exit, not something inferred from parsing TUI output. tmux's
# `wait-for` primitive turns that exit into a synchronization point the
# orchestrator can block on without polling or scraping panes.
#
# Usage:
#   delegate.sh spawn    <id> <model> <cwd> <prompt-file>
#   delegate.sh followup <id> <model> <prompt-file>   # same --session-id, new pane
#   delegate.sh wait     <id> [timeout_seconds]
#   delegate.sh log      <id>
#   delegate.sh exit-code <id>
#   delegate.sh status
#   delegate.sh kill     <id>
#   delegate.sh cleanup
#
# Env:
#   DELEGATE_WAVE_DIR   scratch dir for logs/sessions/prompts (default /tmp/delegate-wave)
#   DELEGATE_WAVE_PROVIDER  provider passed to `pi --provider` (default: deepseek)

set -euo pipefail

WAVE_DIR="${DELEGATE_WAVE_DIR:-/tmp/delegate-wave}"
PROVIDER="${DELEGATE_WAVE_PROVIDER:-deepseek}"
mkdir -p "$WAVE_DIR/sessions"

usage() {
  sed -n '2,25p' "$0"
}

session_name() { echo "dw-$1"; }

require_pi() {
  command -v pi >/dev/null 2>&1 || {
    echo "delegate-wave: 'pi' is not on PATH. Install @earendil-works/pi-coding-agent first." >&2
    exit 1
  }
  command -v tmux >/dev/null 2>&1 || {
    echo "delegate-wave: 'tmux' is not on PATH." >&2
    exit 1
  }
}

api_key_flag() {
  # tmux's server process keeps the environment it started with; a plain
  # `export` in the orchestrator's shell after that point will NOT reach
  # panes spawned later, so ambient env vars set right before `spawn` can
  # silently fail to reach `pi`. Pass the key explicitly via `pi --api-key`
  # instead. Prefer `~/.pi/agent/auth.json` for a permanent credential --
  # this flag is the reliable one-off fallback.
  if [ -n "${DELEGATE_WAVE_API_KEY:-}" ]; then
    printf ' --api-key %q' "$DELEGATE_WAVE_API_KEY"
  fi
}

# spawn <id> <model> <cwd> <prompt-file>
spawn() {
  local id="$1" model="$2" cwd="$3" prompt_file="$4"
  local sess; sess="$(session_name "$id")"
  local log="$WAVE_DIR/$id.log"
  local marker="dw-done-$id-$$-$RANDOM"

  if tmux has-session -t "$sess" 2>/dev/null; then
    echo "delegate-wave: session $sess already running; use 'followup' or pick a new id" >&2
    return 1
  fi
  [ -f "$prompt_file" ] || { echo "delegate-wave: prompt file not found: $prompt_file" >&2; return 1; }

  echo "$marker" > "$WAVE_DIR/$id.marker"
  tmux new-session -d -s "$sess" -c "$cwd" -x 220 -y 50
  tmux send-keys -t "$sess" \
    "pi --provider '$PROVIDER' --model '$model'$(api_key_flag) -p \"\$(cat '$prompt_file')\" \
      --session-id '$id' --session-dir '$WAVE_DIR/sessions' --approve \
      >'$log' 2>&1; echo \$? > '$WAVE_DIR/$id.exit'; tmux wait-for -S '$marker'" \
    Enter
  echo "$sess"
}

# followup <id> <model> <prompt-file>  -- resumes the same pi --session-id
# in a fresh pane so the conversation (and its context) continues instead
# of restarting from scratch.
followup() {
  local id="$1" model="$2" prompt_file="$3"
  local n=2
  while tmux has-session -t "$(session_name "$id-f$n")" 2>/dev/null; do n=$((n + 1)); done
  local sub="$id-f$n"
  local sess; sess="$(session_name "$sub")"
  local log="$WAVE_DIR/$sub.log"
  local marker="dw-done-$sub-$$-$RANDOM"

  [ -f "$prompt_file" ] || { echo "delegate-wave: prompt file not found: $prompt_file" >&2; return 1; }
  echo "$marker" > "$WAVE_DIR/$sub.marker"
  tmux new-session -d -s "$sess" -x 220 -y 50
  tmux send-keys -t "$sess" \
    "pi --provider '$PROVIDER' --model '$model'$(api_key_flag) -p \"\$(cat '$prompt_file')\" \
      --session-id '$id' --session-dir '$WAVE_DIR/sessions' --approve \
      >'$log' 2>&1; echo \$? > '$WAVE_DIR/$sub.exit'; tmux wait-for -S '$marker'" \
    Enter
  echo "$sess"
}

wait_worker() {
  local id="$1" timeout="${2:-0}"
  local marker; marker="$(cat "$WAVE_DIR/$id.marker" 2>/dev/null || true)"
  [ -n "$marker" ] || { echo "delegate-wave: no marker recorded for $id" >&2; return 1; }
  if [ "${timeout:-0}" -gt 0 ] 2>/dev/null; then
    timeout "$timeout" tmux wait-for "$marker" || { echo "delegate-wave: timeout waiting for $id" >&2; return 1; }
  else
    tmux wait-for "$marker"
  fi
}

show_log() { cat "$WAVE_DIR/$1.log" 2>/dev/null || echo "delegate-wave: no log for $1" >&2; }
exit_code() { cat "$WAVE_DIR/$1.exit" 2>/dev/null || echo "delegate-wave: worker $1 has not finished" >&2; }

status() {
  tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^dw-' || echo "(no active delegate-wave sessions)"
}

kill_worker() {
  local id="$1"
  tmux kill-session -t "$(session_name "$id")" 2>/dev/null || true
}

cleanup() {
  tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^dw-' | while read -r s; do
    tmux kill-session -t "$s" 2>/dev/null || true
  done
}

require_pi
cmd="${1:-}"; shift || true
case "$cmd" in
  spawn) spawn "$@" ;;
  followup) followup "$@" ;;
  wait) wait_worker "$@" ;;
  log) show_log "$@" ;;
  exit-code) exit_code "$@" ;;
  status) status ;;
  kill) kill_worker "$@" ;;
  cleanup) cleanup ;;
  *) usage; exit 1 ;;
esac
