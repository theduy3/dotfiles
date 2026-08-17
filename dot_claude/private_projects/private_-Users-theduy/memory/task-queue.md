---
name: task-queue
description: "Persistent cross-session task queue — check on session start, update on completion, archive done items monthly"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7d54dfe6-570a-43ae-be33-689eccef4954
  modified: 2026-08-17T07:36:31.683Z
---

# Task Queue

Persistent queue surviving session boundaries. Any session may pick up, update, or complete items. Keep concise — archive completed items to bottom section, prune monthly.

**Protocol:** on session start, scan Active for items matching current work context. Mark in-progress items with `(WIP: <date>)`. Move finished items to Completed with date.

## Active Tasks

- [ ] **Storage audit — PAUSED 2026-08-17 "save for later".** Full report (5 audits, live):
      https://claude.ai/code/artifact/bf3a6e2f-1d65-4608-97d0-d2ca6ad3d9a9 · local
      `~/tasks/mac-inventory-audit.html`. Background + design decisions: [[weekly-prune-agent]].
      **State on pause: 179 GiB used / 15 GiB free / 93%** — regressed 20 GiB in 2 days, back near
      the 95% that started this. Trend: 95→92→80→81→83→**93%**.
      **Dominant cause is Docker, not uv:** `Library/Containers` 2.1G → **13G**, VM 711M → **11G**,
      1 → **13 images (10.14GB, 9.34GB reclaimable / 92%)**, 12 volumes (1.3GB reclaimable). A
      Supabase-style local stack came back.
      ⚠️ **Gap in the prune agent I built:** it runs `docker image prune -f`, which removes only
      *dangling* images — 9.34GB here is tagged-but-unused, so `-f` cannot touch it. Deliberate
      (`-a` forces multi-GB re-pulls) but it means Docker is now the top consumer and the agent
      does nothing about it. **Decide: add `docker image prune -a --filter until=168h`, or leave
      Docker manual.**
      Next actions, in order: (1) reclaim Docker ~9GB; (2) uv cache is **4.0G vs the 5.12G cap** —
      cap never fired, consider lowering to ~3G; (3) `clean --force` against a live lock is still
      **unproven** (8 uvx holders now, up from 6).
      Working and verified — don't re-litigate: weekly-prune agent (`com.theduy.weekly-prune`,
      Sun 11:00) **fired correctly 2026-08-16, runs=2, exit 0**; salonx `.mcp.json` still on the
      persistent binary (the uvx→pipx root-cause fix held); **0 failed services**; codex-router
      fully removed; `Bash(rm -rf *)` deny restored.

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
