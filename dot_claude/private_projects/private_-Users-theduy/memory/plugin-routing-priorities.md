---
name: plugin-routing-priorities
description: "Which plugin/skill system to use per task type — GSD owns PROD loop; NEW distilled /s* owns LOCAL loop (rebuilt 2026-07-17, same day old suite deleted); ECC + Superpowers are explicit leaf libraries"
metadata:
  node_type: memory
  type: feedback
  originSessionId: c5a3a6a4-3ceb-43f6-a89a-e2ac62b750ea
  modified: 2026-07-18T13:53:13.940Z
---

## One loop owner per ARENA — GSD = prod, /s* = local (2026-07-17)

> **Updated 2026-07-17 evening:** the OLD s0–s9 suite was deleted that morning (dotfiles
> `23931ed`), then a NEW `/s*` was **rebuilt the same day by distillation** (spec
> `~/tasks/spec-s-star.md`, ADRs 0001–0007 in `~/tasks/s-star/docs/adr/`). GSD owns
> plan→execute→verify→ship **for production** (Hermes/Wylios). **`/s*` owns local
> single-track work**: `/s0-spec` → `/s1-plan` → `/s-auto` (autonomous S2→S5, squash auto-merge,
> 5-halt ping surface, Run-State `~/tasks/.s-run/<slug>.md`). Distillates are self-contained
> owned copies w/ sidecar `.manifest.yaml`; refresh via `/update-distill` (per-Source approval).
> **Seam precedence (ADR 0007): todo at `status: plan-approved` → `/s-auto`; `tdd-gates` is
> explicit-call-only.** ECC + Superpowers stay ENABLED as **explicit-call leaf libraries** —
> never their workflow loops. Canonical rule: `~/CLAUDE.md` §Workflow Orchestration. See
> [[gsd-reinstall-global]], [[consolidation-into-s-star]], [[spec-plan-tdd-ownership]].

### The loops
- **Local:** `/s0-spec` → `/s1-plan` → `/s-auto` (owned `s-*` agents: implementer/gate-runner/shipper + review panel of 4 + fixer; models pinned per ADR 0006 — Fable interactive, Opus S2/S4, Sonnet S3/S5).
- **Per-stage manual (2026-07-18):** `/s` renamed `/s-auto`; added `/s2-implement`, `/s3-gates`, `/s4-review [fix]`, `/s5-ship` — operator rerun/debug wrappers over the same pinned agents. No Seam ownership, no auto-chain, no ping; `/s5-ship` refuses without S3/S4 evidence.
- **Prod:** `/gsd-*` (`gsd-new-project`, `gsd-plan-phase`, `gsd-execute-phase`, `gsd-verify-work`, `gsd-progress`, `gsd-resume-work`, `gsd-workspace`).
- **Skip (rival loops):** `/ecc:plan`, `/ecc:feature-dev`; Superpowers workflow loop. (Old `/s0`–`/s9`, `ship`, `deploy` wrappers deleted 2026-07-17 — different artifacts from today's `/s*`.)

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
