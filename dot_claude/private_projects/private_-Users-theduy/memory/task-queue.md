---
name: task-queue
description: "Persistent cross-session task queue — check on session start, update on completion, archive done items monthly"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7d54dfe6-570a-43ae-be33-689eccef4954
  modified: 2026-07-31T21:40:58.340Z
---

# Task Queue

Persistent queue surviving session boundaries. Any session may pick up, update, or complete items. Keep concise — archive completed items to bottom section, prune monthly.

**Protocol:** on session start, scan Active for items matching current work context. Mark in-progress items with `(WIP: <date>)`. Move finished items to Completed with date.

## Active Tasks

- [ ] Hermes-wylios pipeline: unstick stalled wyl-15 task (see [[hermes-wylios-coding-pipeline]])
- [ ] Hermes-wylios pipeline: install `gh` in container (missing, breaks PR ops)
- [ ] Sans Souci SEO Phase 2: /faq page, /galerie page, review acquisition, local citations (see [[seo-sanssouci]])
- [ ] salonx i18n Phase M: remap obsolete keyring on translate-km branch (fr/vi/km), only unmerged work from 73-spec audit (see [[salonx-gates-local]])
- [ ] /s* consolidation Phase 3-4: deferred for soak since 2026-06-11 — revisit (see [[consolidation-into-s-star]])
- [ ] **Run provenance Phase 1c** — `~/tasks/spec-run-provenance-1c.md` (draft, NOT grilled).
      Closes the third generation of one defect family: `present` unions all history while
      `expected` is point-in-time, so a roster rename + re-stamp can still silence a partial.
      Plus: latest-wins `expected` suppression, two quadratic regexes, `Edge.absent` is
      write-only, "unknown" renders as "verified complete", and a typecheck tier asked for twice.
      **Read its "How to grill this" section before planning** — Phase 1b was grilled twice and
      still shipped two HIGHs, because both grills asked reference-axis questions and never a
      dimensional-axis one.
- [ ] **`/s1-plan` template change** (skill edit, not repo work) — add a "Dimensions and call
      sites" section: (A) for every comparison or "N of M" the plan writes, name the unit of both
      operands and where each is counted; (B) for every NEW symbol, table every call site with the
      exact expression passed. S4.5 proposed this after Phase 1b; the existing consumer-map
      template is retrospective by construction, so a brand-new symbol with brand-new call sites
      gets no row at all — the structural hole H2 fell through.
- [ ] **Lesson candidates to author** (staged, not written to the store) — full text and S4.5's
      keep/sharpen/drop dispositions are in `~/tasks/.s-run/run-provenance-1b.md`. Headline new
      one: *when a plan writes a comparison or an "N of M", name where each operand is counted and
      prove both count the same thing.* Three instances in one plan, each survived two grills and
      a green suite.

## Completed

- [x] 2026-08-05: **`s-spec-reviewer` soak COMPLETE — it works, no tuning needed.** Ran on three
      real diffs (run-provenance, 1b-widen, 1b + its re-panel). Claimed-set scoping held every
      time: it correctly excluded Goal 7 on Phase 1 and goal 4 / criterion 4 on Shipment 2 as
      out-of-claimed-set, and never raised a CRITICAL. Zero false blocks across four invocations.
      It also did the thing it was built for — on Shipment 2 it confirmed all 12 claimed
      requirements delivered with zero scope creep, and independently adjudicated three
      implementer escalations. Severity calls were calibrated (LOW for spec-text drift, never
      inflated to block).
- [x] 2026-08-05: **Run provenance Phase 1 + 1b COMPLETE** — three PRs on theduy3/tasks:
      #1 `bb6f7a0` (record which artifact revisions each run used), #2 `3b718d7` (widen the
      fingerprint 8→16 hex before the log grew), #3 `afb0288` (surface partial stamps, panel gaps
      and base-sha in the coverage report). All nine spec criteria closed. 110 → 179 tests.
      Carries → Phase 1c above.
- [x] 2026-07-10: Task queue created (autonomous-agent-harness setup)
- [x] 2026-07-31: /s* S4 spec-axis gap closed — `s-spec-reviewer` added as an always-on blocking
      panel member. Nothing had verified the merged diff against `tasks/spec-<topic>.md`, so an
      unattended auto-merge could ship code that passed every quality gate and implemented the
      wrong feature. No sixth halt reason (s-auto forbids it); blockers ride the existing
      CRITICAL/HIGH → fix loop → `review stuck` path.
