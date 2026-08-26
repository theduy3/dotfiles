---
name: task-queue
description: "Persistent cross-session task queue — check on session start, update on completion, archive done items monthly"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7d54dfe6-570a-43ae-be33-689eccef4954
  modified: 2026-08-19T04:31:18.000Z
---

# Task Queue

Persistent queue surviving session boundaries. Any session may pick up, update, or complete items. Keep concise — archive completed items to bottom section, prune monthly.

**Protocol:** on session start, scan Active for items matching current work context. Mark in-progress items with `(WIP: <date>)`. Move finished items to Completed with date.

## Active Tasks

- [ ] **salonx loyalty hardening — PAUSED 2026-08-18 "complete later".** Handoff:
      `~/tasks/loyalty-backlog-handoff.md`. **Production is CLEAN — none of this is a live defect.**
      Shipped and verified: #1613 (reopen releases the redeem, the root cause), #1646 (never debit
      without the discount), #1651 (detection RPC); detector returns **0 rows on both tenants**
      (proven non-vacuous), client remediation closed.
      **Order — do #1663 FIRST:** the settle invariant asserts money-out ⇒ debit twice
      (`schema.sql:13707`, `:13822`) and **debit ⇒ money-out nowhere** — the direction the original
      defect took. ⚠ **Sequencing trap: doing #1645 first kills #1663** — consolidation is a
      snapshot, the assertion is durable; once the cheap fix lands the pressure drops and the gap
      stays. ⚠ #1663 modifies `fn_loyalty_accrue` (highest blast radius, ~5 rewrites, stale-base
      defect history) — copy VERBATIM from `20261225040000`.
      Then #1645 (five copies of the discount-leg mapping — judgment per site, three answer `""`
      differently on purpose), then #1662 (surplus detector — only needed before the NEXT
      compensation-RPC run; population is 2, both hand-verified). #1463's *decision* (does the
      assertion count the dead legacy tender?) is on #1663's critical path; its deletion is not.
      **Do-nothing is defensible** — the cost is that prevention stays client-side.

- [ ] **Storage audit — audit 6 CLOSED 2026-08-26, 24 GiB reclaimed.** Report (live, same URL):
      https://claude.ai/code/artifact/bf3a6e2f-1d65-4608-97d0-d2ca6ad3d9a9 · local
      `~/tasks/mac-inventory-audit.html`. Agent design: [[weekly-prune-agent]].
      **98% / 4.8 GiB free → 86% / 29 GiB free** (168 GiB used). Trend: 95→92→80→81→83→93→98→**86%**.
      `~/Library` **57G → 33G** (App Support 24→13, Caches 7.1→2.3, Containers 19→11).
      ✅ **DOCKER DISCARD REACHES THE HOST — proven, stop assuming otherwise.** `Docker.raw` is
      sparse (60G apparent / 18G allocated); pruning 8.1 GB *inside* the VM dropped the host file
      **18G → 10G immediately, no restart**. ⇒ the weekly agent's dangling-only
      `docker image prune -f` leaks **~8 GB/week**.
      **→ STILL OPEN: add `docker image prune -a --filter until=168h` to
      `~/.local/bin/weekly-prune.sh`.** `until=168h` protects freshly-pulled images — the safety
      valve the original `-a` objection lacked. User approved a ONE-TIME `-a` on 2026-08-26; that is
      **not** standing authorization to change the unattended cron. Ask first.
      **Reclaimed, user ran the deletes** (all rm-blocked for Claude by `Bash(rm -rf *)` deny — do
      NOT route around it): `Claude/vm_bundles` 9.1G, `com.docker.install/in_progress` 2.1G,
      `Caches/Google` 3.3G, 4 updater caches 1.5G. `Application Support/Claude` is now 1.3G.
      ⚠️ **`~/theduylifeos` 12G is still unaudited** — appeared between audits 5 and 6, never
      investigated. Biggest remaining unknown in home.
      ⚠️ **~61G is protected system data needing `sudo`** (denied) — 168 used vs ~107 measurable.
      Never invent a breakdown for it.
      Working, don't re-litigate: weekly-prune agent ran **2026-08-23, exit 0**, freed 2 GiB
      (`runs=` resets on reboot — trust `~/.local/state/weekly-prune.log`, not launchctl); uv cache
      **3.5G vs 5.12G cap**, uvx→pipx fix held; 0 APFS snapshots; 11 `supabase_*_salon365`
      containers verified live after the prune; `rm -rf` deny enforcing.
      ❌ **Retracted mid-session:** a `-9` in the `launchctl list` Status column is routine (launchd
      kills idle on-demand agents that way); baseline here is **~200**. A `head -10` read made it
      look like 9 anomalous crashes and got misreported as jetsam. **Count the whole list first.**

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
