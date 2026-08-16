---
name: scifi-panel-wall
description: "Ten-panel animated terminal wall at ~/bin/scifi (launch `scifi-grid`), plus the herdr pane-API gotchas learned building it"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 90d41cf0-3476-4b09-9c23-4a1da2420a36
  modified: 2026-08-12T05:18:54.825Z
---

Built 2026-08-11. `~/bin/scifi/panels.py` = 10 animated panels (matrix, sys, net,
radar, hex, log, scope, chrono, procs, globe), python3 stdlib + ANSI truecolor only,
no external deps. `~/bin/scifi/grid.sh` builds them into a herdr tab as 4 columns ×
(3,3,2,2) rows. Wrapper on PATH: `scifi-grid` / `scifi-grid --here` / `scifi-grid --close`.
Docs in `~/bin/scifi/README.md`. Costs ~15% of one core for all ten.

`~/bin` is NOT chezmoi-managed (verified: `chezmoi managed | grep '^bin/'` = 0), so
files there are safe from the hourly `chezmoi apply` that reverts `~/.claude` edits —
see [[claude-config-chezmoi-sync]].

**herdr 0.7.4 API facts not in `--help`:**
- No `herdr --skill` flag exists; `herdr <sub> --help` IS the contract. `herdr api schema`
  returns only 5 event schemas, not a command surface.
- `herdr pane split --ratio R` → R is the fraction kept by the **original** pane.
- `herdr pane read` returns **plain text**, not JSON. Piping it to `jq` silently yields
  empty output and looks like "the pane is blank".
- `herdr tab create` returns `.result.root_pane.pane_id` — split that, no pane-list scan.
- `herdr pane run <id> "<cmd>"` runs in that pane's shell; to restart a busy pane,
  `pkill -f "panels.py <name>"` first, then `pane run` again.

Nothing sci-fi was installed via brew — the box had zero TUI toys (no cmatrix/btop/
htop/neofetch/lolcat), so the panels were written from scratch instead.
