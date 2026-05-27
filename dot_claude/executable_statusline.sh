#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
STYLE=$(echo "$input" | jq -r '.output_style.name // "default"')

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
BLUE='\033[34m'
DIM='\033[2m'
RESET='\033[0m'

# Auth source: API key (pay-per-token) vs Subscription (Max/Pro)
# macOS stores subscription OAuth in Keychain, not a file — so absence of API key
# is a reliable signal for subscription auth. Claude cannot run without one.
if [ -n "$ANTHROPIC_API_KEY" ] || [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
    AUTH_BADGE="${MAGENTA}API${RESET}"
else
    AUTH_BADGE="${BLUE}SUB${RESET}"
fi

# Context bar color based on usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

# Build progress bar (20 chars wide for finer granularity)
BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '█')
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# Duration formatting
MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

# Cost formatting
COST_FMT=$(printf '$%.2f' "$COST")

# Git info (cached to avoid lag)
CACHE_FILE="/tmp/claude-statusline-git-cache"
CACHE_MAX_AGE=5

cache_is_stale() {
    [ ! -f "$CACHE_FILE" ] || \
    [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}

if cache_is_stale; then
    if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
        STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        echo "$BRANCH|$STAGED|$MODIFIED" > "$CACHE_FILE"
    else
        echo "||" > "$CACHE_FILE"
    fi
fi

IFS='|' read -r BRANCH STAGED MODIFIED < "$CACHE_FILE"

# Line 1: Model | Directory | Git branch + status
GIT_INFO=""
if [ -n "$BRANCH" ]; then
    GIT_STATUS=""
    [ "$STAGED" -gt 0 ] && GIT_STATUS=" ${GREEN}+${STAGED}${RESET}"
    [ "$MODIFIED" -gt 0 ] && GIT_STATUS="${GIT_STATUS} ${YELLOW}~${MODIFIED}${RESET}"
    GIT_INFO=" ${DIM}|${RESET} ${GREEN} ${BRANCH}${RESET}${GIT_STATUS}"
fi

echo -e "${CYAN}${MODEL}${RESET} ${DIM}|${RESET} ${DIR##*/}${GIT_INFO} ${DIM}|${RESET} ${BAR_COLOR}${BAR}${RESET} ${PCT}% ${DIM}[${RESET}${AUTH_BADGE}${DIM}]${RESET} ${DIM}|${RESET} ${YELLOW}${COST_FMT}${RESET} ${DIM}|${RESET} ${MINS}m ${SECS}s ${DIM}|${RESET} ${DIM}${STYLE}${RESET}"

# Line 2: prompt-cache hit rate — hidden until usage data exists (fresh session).
CACHE_READ=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
CACHE_WRITE=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
FRESH_INPUT=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
TOTAL_INPUT=$((CACHE_READ + CACHE_WRITE + FRESH_INPUT))
if [ "$TOTAL_INPUT" -gt 0 ]; then
    HIT_RATE=$((CACHE_READ * 100 / TOTAL_INPUT))
    if [ "$HIT_RATE" -ge 85 ]; then HR_COLOR="$GREEN"
    elif [ "$HIT_RATE" -ge 60 ]; then HR_COLOR="$YELLOW"
    else HR_COLOR="$RED"; fi
    fmt_k() { awk -v n="$1" 'BEGIN{ if (n>=1000) printf "%.1fk", n/1000; else printf "%d", n }'; }
    CR=$(fmt_k "$CACHE_READ"); CW=$(fmt_k "$CACHE_WRITE"); FI=$(fmt_k "$FRESH_INPUT")
    echo -e "${DIM}cache${RESET} ${HR_COLOR}${HIT_RATE}%${RESET} hit ${DIM}|${RESET} read ${GREEN}${CR}${RESET} ${DIM}·${RESET} write ${YELLOW}${CW}${RESET} ${DIM}·${RESET} fresh ${RED}${FI}${RESET}"
fi

# Line 3: context-mode savings — hidden until real data exists.
# Reuses $input (already drained at top); context-mode self-resolves its session
# via parent-process walk. Bundle lives in the versioned cache install (the only
# one with the native better-sqlite3 dep); resolve newest by mtime.
CM_BIN=$(ls -dt "$HOME"/.claude/plugins/cache/context-mode/context-mode/*/cli.bundle.mjs 2>/dev/null | head -n1)
if [ -n "$CM_BIN" ] && command -v node >/dev/null 2>&1; then
    CM_LINE=$(printf '%s' "$input" | node "$CM_BIN" statusline 2>/dev/null)
    # Empty-state placeholder contains "saves ~98%"; show only real savings.
    if [ -n "$CM_LINE" ] && [[ "$CM_LINE" != *"saves ~98%"* ]]; then
        echo -e "$CM_LINE"
    fi
fi
