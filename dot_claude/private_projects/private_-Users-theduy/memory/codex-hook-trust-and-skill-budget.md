---
name: codex-hook-trust-and-skill-budget
description: "Codex hooks need persisted trust in [hooks.state] — clearing it silently disables every hook; hash is index-independent so entries can be re-mapped by (event, command). Skills budget is hardcoded 2%, no knob."
metadata: 
  node_type: memory
  type: reference
  originSessionId: a40de334-bf7a-4627-a1ea-c124f8decebc
  modified: 2026-08-07T11:55:01.941Z
---

`~/.codex/config.toml` `[hooks.state."<path>:<event>:<group>:<hook>"]` entries are **required** for a hook to run. Codex treats a hook with no matching state entry as untrusted and **silently skips it** — no warning, no log line. `codex exec` cannot prompt, so non-interactive runs just lose all hooks.

Verified 2026-08-07: deleting all `[hooks.state]` blocks made all 9 hooks stop firing, including `worktree-path-guard.js` and `worktree-branch-guard.js`. `codex doctor` still reported `0 warn · 0 fail` — it does not check hook trust. The only reliable signal is the presence of `hook: <Event>` lines in a `codex exec` run.

**`trusted_hash` is NOT derivable from hooks.json.** Brute-forced thousands of formulations (command, event, matcher, timeout, indices, JSON/TOML serializations, separators) against 24 known-good pairs — no match. It is index-**independent** though: re-mapping an existing hash onto a shifted key by matching `(event, command)` works. That is the recovery path after editing `hooks.json` — never regenerate, always carry the old hash forward.

Interactive recovery if hashes are lost: run `codex` (TUI) → Hooks manager → "trust all". The flag `--dangerously-bypass-hook-trust` runs hooks *without persisting* trust — not a fix.

**Skills context budget is hardcoded at 2%** (binary strings: `budget of 2%`, `2% skills context budget`). There is no Codex equivalent of Claude's `skillListingBudgetFraction`. The only levers are fewer/smaller skills: `[[skills.config]]` with `name` or `path` + `enabled = false` (per-skill), or `[plugins."x@marketplace"] enabled = false`. Measured 2026-08-07: 93 local skills in `~/.codex/skills` = 15,452 description chars (~85% of load); all 12 enabled plugin skills = 2,839 chars. Disabling plugins alone does not clear the truncation warning.

`~/.codex/config.toml` and `hooks.json` are **not** chezmoi-managed (only `.codex/AGENTS.md` and `.codex/sync-claude-inventory.sh` are), so direct edits stick — unlike [[claude-config-chezmoi-sync]].

Related: [[plugin-routing-priorities]], [[codex-claude-inventory-mirror]]
