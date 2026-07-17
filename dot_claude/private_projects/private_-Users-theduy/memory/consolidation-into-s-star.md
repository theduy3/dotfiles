---
name: consolidation-into-s-star
description: RESOLVED OPPOSITE WAY — /s* suite deleted 2026-07-17; GSD kept as sole loop owner. Historical record of the abandoned fold-into-/s* plan.
metadata:
  node_type: memory
  type: project
  originSessionId: 0e84b4bb-d50a-4709-87e0-f70ddca381f0
---

**Outcome (2026-07-17):** The consolidation plan reversed. Instead of folding GSD+ECC+Superpowers into `/s*` and deleting them, the `/s*` suite itself was removed entirely (dotfiles commit `23931ed`): s0–s9 commands, ship/deploy wrappers (`full-ship`, `auto-ship`, `ship-agents`, `deploy-agents`), archived s7/s8, `workflow-model-routing.md`, `session-resume.md`, and the orphan `worktree-required-guard.js` hook. GSD is the sole loop owner; ECC + Superpowers remain explicit-call leaf libraries per [[plugin-routing-priorities]].

**History:** Original plan (spec `~/tasks/spec-consolidation.md`) was to fold best parts of GSD+ECC+Superpowers into `/s*`, then delete all three. Phases 1-2 done 2026-06-11 (16 agents + 9 skills harvested to `~/.claude/agents/` and `~/.claude/skills/` — those harvested copies SURVIVE the /s* removal and stay useful); Phases 3-4 deferred for soak, then abandoned. The 2026-06-19 routing decision ("GSD owns the loop", [[gsd-reinstall-global]]) deprecated `/s*`; the 2026-07-17 removal finished it.

**Why:** Two full loop owners caused hook conflicts (worktree-required-guard falsely blocking GSD edits) and routing ambiguity. More-recent, more-tested loop (GSD) won — surfaced conflict resolved, not averaged.

**How to apply:** Never suggest `/s0`–`/s9`, `/ship`, `/quick-ship`, `/deploy`, `full-ship`, `auto-ship` — deleted. Plan→execute→verify→ship goes through `/gsd-*`. Standalone discipline skills (`spec`, `plan`, `tdd-gates`, `superpowers:*`) and harvested agents remain available as leaves. `session-resume.md` is gone: resume via `/gsd-resume-work`, not `tasks/todo-*.md` status scanning.
