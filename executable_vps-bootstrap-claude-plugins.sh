#!/usr/bin/env bash
#
# vps-bootstrap-claude-plugins.sh
# ---------------------------------------------------------------------------
# Rebuild this Mac's Claude Code plugin + marketplace set on a fresh box.
#
# WHY THIS EXISTS: plugins live in ~/.claude/plugins/, which chezmoi does NOT
# track (0 managed files). They cannot be git-synced — they must be RE-INSTALLED
# from their marketplaces. This script does that in one shot, idempotently.
#
# The lists below are a SNAPSHOT of theduy's MacBook taken 2026-07-19.
# Re-generate them on any machine that still has the JSON manifests:
#
#   # MARKETPLACES  ("name|owner-repo")
#   jq -r 'to_entries[]|"\(.key)|\(.value.source.repo // .value.source.url)"' \
#       ~/.claude/plugins/known_marketplaces.json
#
#   # PLUGINS  ("plugin@marketplace|scope")
#   jq -r '.plugins|to_entries[]|"\(.key)|\(.value[0].scope)"' \
#       ~/.claude/plugins/installed_plugins.json
#
#   # DISABLED ("plugin@marketplace")
#   claude plugin list | awk '/@/{n=$2} /Status:/{if($0~/disabled/)print n}'
#
# USAGE:
#   bash vps-bootstrap-claude-plugins.sh              # do it
#   DRY_RUN=1 bash vps-bootstrap-claude-plugins.sh    # print actions only
#   SKIP_GSD=1 bash vps-bootstrap-claude-plugins.sh   # skip GSD reinstall
#   AUTO_INSTALL_NODE=1 bash vps-bootstrap-...        # apt/dnf-install Node if missing
# ---------------------------------------------------------------------------
set -uo pipefail   # NOT -e: one failed install must not abort the whole run

log()  { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }
run()  { if [ "${DRY_RUN:-0}" = 1 ]; then printf '  DRY: %s\n' "$*"; else "$@"; fi; }

# Install a plugin; on failure, refresh its marketplace once and retry.
# A pre-existing marketplace can carry a STALE cache (present != current) whose
# plugin ids no longer resolve — `marketplace update` re-syncs it. Idempotent.
install_plugin() {
  local key="$1" scope="$2" mkt
  if run claude plugin install "$key" --scope "$scope"; then return 0; fi
  mkt="${key#*@}"
  warn "install failed for $key — refreshing marketplace '$mkt' (stale cache?) and retrying"
  run claude plugin marketplace update "$mkt" || true
  run claude plugin install "$key" --scope "$scope"
}

# --- node prerequisite ----------------------------------------------------
# Claude Code plugin RUNTIMES + GSD (npx @opengsd/gsd-core) need Node >= 18.
NODE_MIN=18
node_major() { node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'; }

install_node_system() {
  command -v curl >/dev/null 2>&1 || { err "curl required to fetch Node; install curl first."; return 1; }
  local SUDO=""
  if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else
      err "not root and no sudo — cannot system-install Node."; return 1
    fi
  fi
  if command -v apt-get >/dev/null 2>&1; then
    log "installing Node LTS via NodeSource (apt) ..."
    run ${SUDO} apt-get update -y || true
    run ${SUDO} apt-get install -y curl ca-certificates || true
    run bash -c "curl -fsSL https://deb.nodesource.com/setup_lts.x | ${SUDO} -E bash -" &&
    run ${SUDO} apt-get install -y nodejs
  elif command -v dnf >/dev/null 2>&1; then
    log "installing Node LTS via NodeSource (dnf) ..."
    run bash -c "curl -fsSL https://rpm.nodesource.com/setup_lts.x | ${SUDO} bash -" &&
    run ${SUDO} dnf install -y nodejs
  elif command -v yum >/dev/null 2>&1; then
    log "installing Node LTS via NodeSource (yum) ..."
    run bash -c "curl -fsSL https://rpm.nodesource.com/setup_lts.x | ${SUDO} bash -" &&
    run ${SUDO} yum install -y nodejs
  else
    err "no supported package manager (apt/dnf/yum) for auto Node install."; return 1
  fi
  hash -r 2>/dev/null || true
  command -v node >/dev/null 2>&1 && command -v npx >/dev/null 2>&1
}

ensure_node() {
  local maj; maj="$(node_major)"
  if command -v node >/dev/null 2>&1 && command -v npx >/dev/null 2>&1 \
     && [ -n "$maj" ] && [ "$maj" -ge "$NODE_MIN" ] 2>/dev/null; then
    log "node $(node -v) + npx present (>= v${NODE_MIN})"; return 0
  fi
  if command -v node >/dev/null 2>&1; then
    warn "node $(node -v 2>/dev/null) inadequate (need >= v${NODE_MIN} with npx)"
  else
    warn "node not found on PATH"
  fi

  # 1) user-scope nvm if available (no root)
  if [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]; then
    log "found nvm — installing Node LTS (user scope) ..."
    # shellcheck disable=SC1091
    . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    run nvm install --lts && run nvm use --lts
    command -v node >/dev/null 2>&1 && command -v npx >/dev/null 2>&1 && { log "node $(node -v) via nvm"; return 0; }
  fi

  # 2) opt-in system install
  if [ "${AUTO_INSTALL_NODE:-0}" = "1" ]; then
    install_node_system && { log "node $(node -v) installed"; return 0; }
  fi

  # 3) fail loud with copy-paste fixes
  err "Node >= v${NODE_MIN} is a prerequisite (GSD + plugin runtimes) and is not available."
  cat >&2 <<EOF
Fix it with ONE of these, then re-run this script:

  # let this script install it (Debian/Ubuntu/RHEL, needs root or sudo):
  AUTO_INSTALL_NODE=1 bash "$0"

  # Debian/Ubuntu by hand, NodeSource LTS (as root):
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs

  # user scope, no root, via nvm:
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  . "\$HOME/.nvm/nvm.sh" && nvm install --lts
EOF
  return 1
}

# --- preflight ------------------------------------------------------------
command -v claude >/dev/null 2>&1 || {
  err "claude CLI not on PATH. Install Claude Code first, then re-run."; exit 1; }
command -v git >/dev/null 2>&1 || \
  warn "git not found — marketplace 'add' clones via git; installs may fail without it."
log "claude $(claude --version 2>/dev/null || echo '?')"

if ensure_node; then
  NODE_OK=1
else
  NODE_OK=0
  if [ "${DRY_RUN:-0}" = "1" ]; then
    warn "DRY_RUN: continuing preview despite missing Node."
  else
    exit 1   # hard gate: Node is a real prerequisite
  fi
fi

# --- snapshot: marketplaces  (name|github-repo) ---------------------------
MARKETPLACES=(
  "claude-plugins-official|anthropics/claude-plugins-official"
  "superpowers-marketplace|obra/superpowers-marketplace"
  "last30days-skill|mvanhorn/last30days-skill"
  "caveman|JuliusBrussee/caveman"
  "ecc|affaan-m/everything-claude-code"
  "obsidian-skills|kepano/obsidian-skills"
  "thedotmack|thedotmack/claude-mem"
  "addy-agent-skills|addyosmani/agent-skills"
  "ponytail|DietrichGebert/ponytail"
  "minimalist-entrepreneur|slavingia/skills"
  "cli-anything|HKUDS/CLI-Anything"
  "anthropic-agent-skills|anthropics/skills"
  "social-media-skills|charlie947/social-media-skills"
)

# --- snapshot: plugins  (plugin@marketplace|scope) ------------------------
PLUGINS=(
  "ecc@ecc|user"
  "claude-mem@thedotmack|user"
  "last30days@last30days-skill|user"
  "caveman@caveman|user"
  "obsidian@obsidian-skills|user"
  "commit-commands@claude-plugins-official|user"
  "explanatory-output-style@claude-plugins-official|user"
  "feature-dev@claude-plugins-official|user"
  "frontend-design@claude-plugins-official|user"
  "learning-output-style@claude-plugins-official|user"
  "pr-review-toolkit@claude-plugins-official|user"
  "typescript-lsp@claude-plugins-official|user"
  "superpowers@claude-plugins-official|user"
  "chrome-devtools-mcp@claude-plugins-official|user"
  "playwright@claude-plugins-official|user"
  "agent-skills@addy-agent-skills|user"
  "ponytail@ponytail|user"
  "minimalist-entrepreneur@minimalist-entrepreneur|user"
  "cli-anything@cli-anything|user"
  "document-skills@anthropic-agent-skills|user"
  "social-media-skills@social-media-skills|project"   # scoped to a Mac path; skipped
)

# --- snapshot: plugins that were DISABLED on the Mac ----------------------
DISABLED=(
  "agent-skills@addy-agent-skills"
  "cli-anything@cli-anything"
  "document-skills@anthropic-agent-skills"
  "minimalist-entrepreneur@minimalist-entrepreneur"
  "ponytail@ponytail"
)

FAILED=()

# --- 1. add marketplaces --------------------------------------------------
log "== marketplaces =="
EXISTING_MK="$(claude plugin marketplace list 2>/dev/null || true)"
for entry in "${MARKETPLACES[@]}"; do
  name="${entry%%|*}"; repo="${entry#*|}"
  if printf '%s\n' "$EXISTING_MK" | grep -qE "❯ ${name}([[:space:]]|$)"; then
    log "marketplace present: $name"
  else
    log "adding marketplace: $name ($repo)"
    run claude plugin marketplace add "$repo" || { warn "add failed: $name"; FAILED+=("mk:$name"); }
  fi
done

# --- 2. install plugins ---------------------------------------------------
log "== plugins =="
EXISTING_PL="$(claude plugin list 2>/dev/null || true)"
for entry in "${PLUGINS[@]}"; do
  key="${entry%%|*}"; scope="${entry#*|}"
  if [ "$scope" = "project" ]; then
    warn "skip project-scoped $key — on the VPS, cd into that project and run:"
    warn "    claude plugin install $key --scope project"
    continue
  fi
  if printf '%s\n' "$EXISTING_PL" | grep -qF "$key"; then
    log "already installed: $key"
  else
    log "installing: $key (scope=$scope)"
    install_plugin "$key" "$scope" || { warn "install failed: $key"; FAILED+=("pl:$key"); }
  fi
done

# --- 3. restore disabled state --------------------------------------------
log "== restore disabled state =="
for key in "${DISABLED[@]}"; do
  log "disabling: $key"
  run claude plugin disable "$key" || warn "could not disable $key (may not be installed)"
done

# --- 4. GSD (npx-managed, also not chezmoi-tracked) -----------------------
if [ "${SKIP_GSD:-0}" != "1" ]; then
  log "== GSD (@opengsd/gsd-core) =="
  if [ "${NODE_OK:-0}" = "1" ] && command -v npx >/dev/null 2>&1; then
    run npx -y @opengsd/gsd-core --claude --global || { warn "GSD install failed"; FAILED+=("gsd"); }
  else
    warn "Node/npx unavailable — skipping GSD. Later: npx @opengsd/gsd-core --claude --global"
  fi
fi

# --- summary --------------------------------------------------------------
echo
if [ "${#FAILED[@]}" -eq 0 ]; then
  log "DONE — all marketplaces + plugins reconstructed. Restart Claude Code to load them."
else
  warn "DONE with ${#FAILED[@]} failure(s): ${FAILED[*]}"
  warn "Re-run the script (it is idempotent) or install the failed items by hand."
fi
cat <<'NOTE'

Caveats to check manually on the VPS:
  * Restart Claude Code (plugins load at startup).
  * Runtimes are NOT installed here — a plugin's MCP server / npx binary / python
    venv is fetched on first use or needs its own install (node, python, jq...).
  * postiz@skills-dir is a LOCAL skill (not from a marketplace); it loads only if
    ~/.claude/skills/postiz exists (arrives via chezmoi from ~/.agents/skills, if managed).
  * social-media-skills was project-scoped to a Mac path — re-scope it per repo.
  * Marketplace NAME DRIFT: if "plugin@mkt" fails and `marketplace update <mkt>` says
    "Marketplace '<mkt>' not found", a pre-existing copy of that repo is registered under
    an OLD manifest name. Fix once, by hand:
      claude plugin marketplace remove <old-name>   # e.g. everything-claude-code
      claude plugin marketplace add <owner/repo>     # re-registers under current name
      claude plugin install <plugin>@<mkt> --scope user
NOTE
