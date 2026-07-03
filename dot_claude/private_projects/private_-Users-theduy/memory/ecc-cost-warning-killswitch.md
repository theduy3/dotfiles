---
name: ecc-cost-warning-killswitch
description: "How to silence ECC harness \"COST NOTICE/WARNING\" prompts — env var in settings.json"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 392968f0-9b83-4fd8-b4f2-61846634e273
---

User does not want cost-per-session nagging — wants to get work done, not save tokens.

The `$`-based prompts ("COST NOTICE: Session cost is $X. Consider whether the
current approach is efficient.") come from the ECC PostToolUse hook
`ecc-context-monitor.js`, which fires at $5 / $10 / $50 thresholds. It is
disabled by env var `ECC_CONTEXT_MONITOR_COST_WARNINGS=off`.

**Why:** the hook reads `process.env.ECC_CONTEXT_MONITOR_COST_WARNINGS` (default
`true`) at `costWarningsEnabled()`. The env switch is copy-agnostic — disables
whichever plugin copy (`marketplaces/` vs `cache/`) is registered, and survives
plugin updates (editing the `.js` would not).

**How to apply:** set in `dot_claude/settings.json.tmpl` env block (chezmoi
template → `chezmoi apply`), committed to dotfiles 2026-06-10 (`69dbf2b`). Keeps
the hook's other channels (context-exhaustion / scope-creep / loop) alive.

Companion change: `~/CLAUDE.md` Rule 6 rewritten from a hard 4k/30k-token budget
("surface the breach / start fresh") to "Spend to finish the task — no hard
budget, don't self-throttle on cost." `~/CLAUDE.md` brought under chezmoi
2026-06-10 (`84328a1`) → source `CLAUDE.md` (plain, not templated), now syncs to
all machines. Related: [[claude-config-chezmoi-sync]], [[statusline-and-hooks]].
