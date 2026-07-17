---
name: plugin-routing-priorities
description: "Which plugin/skill system to use per task type — GSD owns the loop; ECC + Superpowers are explicit leaf libraries; /s* REMOVED 2026-07-17"
metadata:
  node_type: memory
  type: feedback
  originSessionId: c5a3a6a4-3ceb-43f6-a89a-e2ac62b750ea
---

## One loop owner per task → GSD

> **Supersedes the 2026-06-08 "GSD removed, /s* owns loop" version.** GSD was reinstalled
> globally 2026-06-10 and the user now prefers it (2026-06-19). GSD owns plan→execute→verify→ship
> and all enforcement hooks. ECC + Superpowers stay ENABLED as **explicit-call leaf libraries** —
> never their workflow loops. `/s*` was a rival full loop — **removed from disk 2026-07-17**
> (dotfiles `23931ed`, see [[consolidation-into-s-star]]). Canonical rule: `~/CLAUDE.md` §Workflow
> Orchestration. See [[gsd-reinstall-global]], [[consolidation-into-s-star]], [[gsd-orphan-project-hooks-crash]].

### The loop → GSD only
- Plan/execute/verify/ship: `/gsd-*` (`gsd-new-project`, `gsd-plan-phase`, `gsd-execute-phase`, `gsd-verify-work`, `gsd-progress`, `gsd-resume-work`, `gsd-workspace`).
- **Skip (rival loops):** `/ecc:plan`, `/ecc:feature-dev`; Superpowers workflow loop. (`/s0`–`/s9`, `ship`, `deploy`, `full-ship`, `auto-ship` deleted 2026-07-17 — don't suggest them.)

### Leaf libraries — invoke explicitly, never as a loop
- **Superpowers skills** (no longer auto-fire): `brainstorming`, `systematic-debugging`, `test-driven-development`, `verification-before-completion`, `receiving-code-review`, `dispatching-parallel-agents`.
- **ECC stack-specific** (cherry-pick — the real value): `ecc:python-reviewer`/`typescript-reviewer`/`go-reviewer`/`database-reviewer`, build-resolvers, `ecc:security-review`, stack skills (django-*, springboot-*, postgres-patterns, docker-patterns, clickhouse-io).
- **One TDD enforcer per task:** inside GSD → `gsd-verify-work` + `nyquist-auditor`; standalone → `superpowers:test-driven-development`. Don't stack both.

### Neutral (no loop ownership — use under GSD freely)
- Frontend: ui-ux-pro-max (design) → frontend-design (build).
- SEO clients: `/seo-audit` | `/seo-page` | `/seo-technical`. Ad clients: `/ads-audit` | `/ads-google` | `/ads-meta`.
- Tooling: code-review-graph MCP, caveman, claude-mem (`/mem-search` for prior-session context).

### Hook conflict — resolved 2026-07-17
`worktree-required-guard.js` (falsely blocked GSD edits off stale `/s*` task state) deleted with the `/s*` suite. `worktree-path-guard.js` + `worktree-branch-guard.js` are neutral safety — keep.

## Quick Reference
```
DAILY / BIG PROJECT:  /gsd-plan-phase → /gsd-execute-phase → /gsd-verify-work → ship
BUG FIX:              superpowers:systematic-debugging → fix → verify
CODE REVIEW:          gsd-code-review (own) | pr-review-toolkit:review-pr (others' PRs)
TDD:                  inside GSD = gsd-verify-work+nyquist | standalone = superpowers:test-driven-development
FRONTEND:             ui-ux-pro-max (design) → frontend-design (build)
SEO / ADS CLIENT:     /seo-* | /ads-*
PAST DECISIONS:       /mem-search
```

## Blocklisted Plugins (disabled in settings.json, 2026-04-05)
| Plugin | Replaced By |
|--------|-------------|
| code-review@claude-plugins-official | gsd-code-review |
| code-simplifier@claude-plugins-official | ecc:code-simplifier (explicit) |
| security-guidance@claude-plugins-official | ecc:security-review |
