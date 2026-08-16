#!/usr/bin/env bash
# claude-sync.sh — sync ~/.claude config via chezmoi + git.
# Role-driven: push (Mac, authoritative) or pull (VPS replica). Default: pull.
# Deployed to both machines via chezmoi. Failures alert via Telegram (optional).
set -uo pipefail
# $HOME/bin added 2026-08-12: Bluehost installs chezmoi to /root/bin, which was
# absent here — the `command -v chezmoi` guard below aborted every run with
# "chezmoi missing", so that box had never synced once.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/bin:/usr/bin:/bin"

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
  # Discover NEW memory notes before re-add. `chezmoi re-add` only re-adds files
  # chezmoi ALREADY manages — it never picks up new ones — and `chezmoi status`
  # reports drift in managed files only, so an unmanaged note is invisible to both
  # the sync and the command you'd check with. 23 notes accumulated that way while
  # the MEMORY.md index linking them synced normally, leaving every replica a broken
  # index (audited and fixed in 97191e3). Memory recall is cross-machine by design,
  # so a note that never leaves the Mac cannot do its job.
  # Scoped to the HOME project's memory only — that is the always-loaded index and
  # the only memory dir chezmoi has ever tracked. Deliberately NOT projects/*/memory:
  # that glob matches 8 dirs / ~400 notes (298 from salonx alone), which is per-repo
  # working state, not portable config.
  # NB: an unmatched glob expands to the literal pattern under bash, hence the -e guard.
  # Credential gate. Calibrated against the 57-note corpus audited 2026-08-15, where
  # it produced zero hits: prose ABOUT secrets (the filename `internal-secret`, a
  # warning that Syncthing's /rest/config leaks gui.apiKey) must not trip it, and
  # neither may frontmatter originSessionId UUIDs or Syncthing device IDs, which are
  # public pairing identifiers. It matches a VALUE, not a mention.
  CRED_RE="ghp_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{32,}|-----BEGIN [A-Z ]*PRIVATE KEY|[0-9]{9,10}:[A-Za-z0-9_-]{30,}|(api[_-]?key|password|token)[\"']?[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9/+_-]{20,}"
  memdir="$HOME/.claude/projects/$(printf '%s' "$HOME" | tr '/' '-')/memory"
  if [ -d "$memdir" ]; then
    memfiles=("$memdir"/*.md)
    if [ -e "${memfiles[0]}" ]; then
      memsafe=()
      for memf in "${memfiles[@]}"; do
        if grep -qiE "$CRED_RE" "$memf" 2>/dev/null; then
          # Detection covers every note; prevention only covers NEW ones. A note
          # chezmoi already manages gets re-added by `chezmoi re-add` below no matter
          # what we do here, so that case alerts loudly instead of pretending to block.
          if chezmoi source-path "$memf" >/dev/null 2>&1; then
            log "CREDENTIAL PATTERN in TRACKED note $(basename "$memf") — re-add WILL still sync it"
            notify "⚠️ credential pattern in tracked memory note $(basename "$memf") — already in git, rotate + scrub"
          else
            log "CREDENTIAL PATTERN in new note $(basename "$memf") — skipped, left untracked"
            notify "⚠️ credential pattern in new memory note $(basename "$memf") — NOT synced"
          fi
          continue
        fi
        memsafe+=("$memf")
      done
      if [ ${#memsafe[@]} -gt 0 ]; then
        chezmoi add "${memsafe[@]}" >>"$LOG" 2>&1 || log "memory add warn ($memdir)"
      fi
    fi
  fi
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
