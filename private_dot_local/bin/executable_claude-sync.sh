#!/usr/bin/env bash
# claude-sync.sh — sync ~/.claude config via chezmoi + git.
# Role-driven: push (Mac, authoritative) or pull (VPS replica). Default: pull.
# Deployed to both machines via chezmoi. Failures alert via Telegram (optional).
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:/usr/bin:/bin"

LOG="$HOME/.claude-sync.log"
CFG="$HOME/.config/claude-sync"
[ -f "$CFG/telegram.env" ] && . "$CFG/telegram.env"
ROLE="$(cat "$CFG/role" 2>/dev/null || echo pull)"   # default = pull (never accidental push)
HOST="$(hostname -s)"

log(){ echo "$(date -u +%FT%TZ) [$ROLE] $*" >>"$LOG"; }
notify(){
  [ -n "${TELEGRAM_BOT_TOKEN:-}" ] || return 0
  curl -s -m 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode chat_id="${TELEGRAM_CHAT_ID:-}" \
    --data-urlencode text="[claude-sync $ROLE @ $HOST] $1" >/dev/null 2>&1 || true
}

command -v chezmoi >/dev/null || { log "chezmoi missing"; exit 1; }
SRC="$(chezmoi source-path)" || { log "no source-path"; exit 1; }
cd "$SRC" || { log "cannot cd $SRC"; exit 1; }

if [ "$ROLE" = "push" ]; then
  # Mac: capture live ~/.claude edits into source (templates are preserved by re-add)
  chezmoi re-add >>"$LOG" 2>&1 || log "re-add warn"
  if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -q -m "auto-sync $HOST $(date -u +%FT%TZ)" || true
  fi
  # belt-and-suspenders: integrate any remote (no-op with a single pusher)
  if ! git pull --rebase --autostash origin main >>"$LOG" 2>&1; then
    git rebase --abort 2>/dev/null || true
    log "CONFLICT on rebase"
    notify "❌ push-side conflict — resolve on Mac"
    exit 1
  fi
  git push origin main >>"$LOG" 2>&1 || { notify "❌ push failed"; exit 1; }
  chezmoi apply --force >>"$LOG" 2>&1 || { notify "⚠️ apply failed"; exit 1; }
  log "push ok"
else
  # VPS: faithful read-only mirror (git pull in source + apply to ~/.claude)
  chezmoi update --force >>"$LOG" 2>&1 || { notify "❌ pull/update failed"; exit 1; }
  log "pull ok"
fi
