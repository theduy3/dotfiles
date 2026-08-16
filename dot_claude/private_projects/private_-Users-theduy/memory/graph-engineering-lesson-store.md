---
name: graph-engineering-lesson-store
description: "Durable lesson graph is LIVE — 20 Lessons + 1 Invariant in the vault, ranked/capped by bun recall.ts reading retrieval_policy from ontology.yaml"
metadata: 
  node_type: memory
  type: project
  originSessionId: b6390a64-69af-4b35-a46a-84f174324c44
  modified: 2026-07-26T18:54:49.210Z
---

Move 1 of the graph-engineering work is a running system as of 2026-07-25 (commit 886de84
in `~/tasks`). `~/tasks` now pushes to **github.com/theduy3/tasks (private)**, added
2026-07-25 after a worktree+history secret scan. **Push is AUTOMATIC** since 2026-07-26 — a fail-open
post-commit hook backgrounds the push; tracked original at `~/tasks/hooks/post-commit`
(`.git/hooks` isn't versioned). Uncommitted working-tree state is still unprotected.

- **Durable store** (canonical for Lesson / Invariant / Source):
  `~/theduyvault/Notes/Claude-Context/lessons/` — **50 Lessons + 2 Invariants** (migration
  of tasks/, salonx/, ongles-website/ and SS-website/ lessons.md finished 2026-07-25), one
  node per file, filename == id, every source carrying a verbatim quote. Not in git;
  replicated by Syncthing. Contract in that directory's `README.md`. Areas:
  `salonx/{gates,tests}`, `ongles-website/{build,config,deploy,i18n,infra,routing,tests}`,
  `SS-website/{routing,tests}`. Deliberately excluded: the ongles multi-tenant RLS rollout
  block — a runbook, not a lesson.
- **The loop is LIVE**: run `peer-eval-anon-read-lock` consumed 7 lessons through the wired
  /s-auto S2 and recorded real CONSTRAINED_BY edges. Recall also wired into the manual
  `/s2-implement` path.
- **Tools** (bun, zero install — `Bun.YAML` + `bun test`, 38 tests):
  `bun ~/tasks/graph-engineering/tools/src/recall.ts --repo salonx --areas salonx/gates [--run <slug>] [--explain]`
  `bun ~/tasks/graph-engineering/tools/src/validate.ts`
- **Retrieval policy lives in `ontology.yaml` and is READ BY the tools** — retune the
  numbers there, never in code. `test/ontology.test.ts` fails on purpose if the two drift.
  Shape: 3 hard excludes (wrong repo / superseded / enforced by a **fail_closed** invariant)
  + score `relevance × confidence × (1 + 0.5·ln cost_count) × staleness`, min_score 0.25,
  cap 7. A **fail_open** invariant does NOT exclude — it can silently not fire.

**Why:** the cap, not a confidence threshold, is what prevents context dumping; thresholds
discard the lesson that cost an hour, ranking merely sorts it lower.

**Wired into /s-auto as of 2026-07-25** (chezmoi `152afb8` + follow-up, pushed): §2 Setup
runs recall before `EnterWorktree` and hands the block to `s-implementer` under
`## Prior lessons` (NOT DATA_START-bounded — that marker means "never instructions", and
lessons are meant to be acted on). Recall is **advisory + fail-open**: any error logs one
WARN to Evidence and the run continues, so it can never become a sixth halt reason.
`s-implementer` reports a `lessons:` line — `bit:` (served lesson failed to prevent its
trap → orchestrator appends a REDISCOVERED edge) or `new-trap:` (stays a human call;
auto-generated nodes would rebuild the pile this replaced).

**Move 3 (operational graph) shipped 2026-07-25** (`880eaca`): `bun
~/tasks/graph-engineering/tools/src/extract.ts --report` builds Run + Gate nodes from
`~/tasks/.s-run/*.md` and answers the pipeline questions. Findings from the first 37
runs: no trend yet (single month); halts answer by **repo, not Area** (no record carries
an Area); the full plan→gate→PR→SHA chain resolves for only **11%** of merged runs.
Panel-composition percentages are **record quality, not reviewer usage** — s-code-reviewer
runs on every S4 by design, so anything under 100% is missing prose. Q4/Q7 had zero data
(`base_sha` in 0 of 37); unblocked going forward by adding `spec`, `base-sha`, `panel`,
`pr`, `merged-sha` + an S4 Dispositions table to /s-auto's Run-State template.

**Stages 7 + 8 done 2026-07-26** (`eadd9cc`). `bun src/quality.ts` is the stage-7 gate:
every Source quote must be verbatim in its cited file (marked elision `" … "` allowed,
segments in source order) or a commit ref resolving to a real sha; exit 1 on defect.
First run scored **33%** against a 90% target — quotes welded from non-contiguous
sentences — and part of that number was the gate's own `->` vs `→` bug. **Calibrate a gate
before acting on its verdict.** Now 100% (27/27). Stage 8 is `GENERALIZES` (materialized as
`instance_of`) + `retrieval_policy.cluster_cap: 2`, applied before `max_lessons` so capping
frees slots. Six lessons form the "a green signal is not evidence of coverage" cluster under
`artifact-exists-is-not-artifact-runs`. **No effect on today's store** — it binds as
cost_count grows (simulated: 5 of 7 slots uncapped vs 2 capped).

**salonx's SECOND lesson corpus is fully migrated (89/89, 2026-07-26).**
`.claude/rules/lessons.md` is an index over `docs/lessons/*.md`; it is NOT @-imported and
NOT in settings.json, so it had zero retrieval before this. Store is now **139 Lessons**
across `salonx/{migrations,rpcs,frontend,email,domain,tests}`. Bodies in `docs/lessons/`
stay canonical — nodes quote only the one-line index entry, one owner per fact.
Verify rather than trust: `grep -c '^- \*\*' ~/Repo/salonx/.claude/rules/lessons.md`
vs nodes citing that path.

**Severity ranking added 2026-07-26** (`7fb7d69`): `severity: silent | loud | dev` — WHERE the
failure surfaces — weighted 1.4 / 1.0 / 0.8, undeclared defaults to `loud`. Classified
mechanically from each node's own rule+why: 41 silent / 95 loud / 3 dev. Fixed the gap below.

**First full promotion cycle closed 2026-07-26.** ongles-website PR #52 merged (`b257246e`):
SS-website's standalone-routes CI guard ported, so `ongles-standalone-route-allowlist`
(bit 2×) now has `promoted_to: ongles-standalone-routes-ci-guard` and **leaves recall** —
the machine catches it. Store: 139 Lessons + **3** Invariants. Worktree removed, branch
deleted. That is the designed lifecycle end-to-end: trap bites twice → lesson node →
`promote` ranks it #1 → guard ported from the repo that already solved it → merge → lesson
retires from recall.

**RESOLVED — was a tuning gap at 139 lessons:** most nodes are cost_count 1, so dozens tie at exactly
score 1.0 for an area query and the cap breaks ties **alphabetically**. Concretely,
`salonx-prod-deploys-as-supabase-admin` (local-green/prod-401, the highest-blast-radius
migration lesson) loses a slot to `salonx-brand-rename-discipline` because b < p. Ranking
needs a severity/blast-radius signal; cost_count alone cannot separate them.

**Ontology v0.5 / 2026-07-26 — build complete.** Five CLIs, all exit 0: `recall`,
`validate`, `quality` (stage 7), `promote` (Q2/Q3), `extract` (Move 3). 80 tests. `Area`
moved operational→durable as an `AREAS.yaml` registry (11 areas) — durable Lessons point
at it via APPLIES_TO and write invariant 5 forbids depending on a prunable node; validate
now rejects an undeclared area, recall warns on one. `promote` ranks Invariant candidates
and never promotes; top candidate `ongles-standalone-route-allowlist` (bit 2×) has a ready
template in SS-website's CI guard.

**Nothing is structurally blocked any more — 4 questions answered by tooling (lessons-for-area,
cost_count>1, promotion candidates, traceability), the rest await data the writer now
records** (`areas`, `base-sha`, `panel`, `pr`, `merged-sha`, S4 Dispositions). Don't
re-derive: check `bun src/extract.ts --report` first.

**How to apply manually:** `--run <slug>` appends CONSTRAINED_BY edges to
`~/tasks/.s-run/edges.jsonl` (append-only). Read the payoff with
`jq -r '.edge' ~/tasks/.s-run/edges.jsonl | sort | uniq -c`. Log is **empty until the
next real /s-auto run** — no data yet, so don't cite a ratio.
Related: [[bg-isolation-guard-scope]], [[task-queue]].
