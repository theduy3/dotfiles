#!/usr/bin/env bash
# claude-plugins-reconcile.sh — self-heal plugin installs after a Claude Code
# reinstall/wipe. settings.json (synced via chezmoi) is the source of truth for
# enabledPlugins + extraKnownMarketplaces; this reinstalls any enabled plugin
# whose on-disk cache dir is missing. Idempotent: no-op when all are present.
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:/usr/bin:/bin"

SETTINGS="$HOME/.claude/settings.json"
CACHE="$HOME/.claude/plugins/cache"
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
command -v claude >/dev/null || { echo "claude CLI missing"; exit 1; }
[ -f "$SETTINGS" ] || { echo "no settings.json"; exit 1; }

# enabled plugin ids: "plugin@marketplace" (while-read for bash 3.2 portability)
enabled_ids() {
  python3 -c "
import json
d=json.load(open('$SETTINGS'))
for k,v in d.get('enabledPlugins',{}).items():
    if v: print(k)
"
}

missing=0 ok=0 failed=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  plugin="${id%@*}"; mkt="${id##*@}"
  # installed if installed_plugins.json lists it AND its installPath exists
  present=$(python3 -c "
import json,os,sys
try: d=json.load(open('$INSTALLED'))
except Exception: print('no'); sys.exit()
for e in d.get('plugins',{}).get('$id',[]):
    if os.path.isdir(e.get('installPath','')): print('yes'); sys.exit()
print('no')
")
  if [ "$present" = "yes" ]; then ok=$((ok+1)); continue; fi
  # claude-plugins-official ships with the app — skip (no marketplace install)
  if [ "$mkt" = "claude-plugins-official" ]; then continue; fi
  missing=$((missing+1))
  echo "reinstalling $id ..."
  if claude plugin install "$id" >/dev/null 2>&1; then
    echo "  ✔ $id"
  else
    failed=$((failed+1)); echo "  ✘ $id failed (marketplace name drift? check 'claude plugin marketplace list')"
  fi
done < <(enabled_ids)
echo "reconcile: $ok present, $missing missing, $((missing-failed)) restored, $failed failed"
[ "$failed" -eq 0 ]
