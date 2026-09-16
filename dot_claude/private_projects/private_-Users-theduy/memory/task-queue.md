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

- [ ] **Storage audit — audit 7 CLOSED 2026-09-09. 26 GiB reclaimed, 79% = best of 7 audits.**
      Report (live, same URL): https://claude.ai/code/artifact/bf3a6e2f-1d65-4608-97d0-d2ca6ad3d9a9
      · local `~/tasks/mac-inventory-audit.html`. Agent: [[weekly-prune-agent]].
      **183 GiB used / 13 GiB free / 94% → 157 GiB / 44 GiB free / 79%.** Peaked at **100% /
      1.9 GiB free** mid-audit and recovered on its own (macOS purged under pressure — do not
      credit any action). Trend: 95→92→80→81→83→93→98→86→**79%**.
      🔑 **SIP REFUSES ROOT — and simctl was installed the whole time.** The 11.4 GB of orphaned
      iOS/watchOS simulator runtimes could NOT be removed with `sudo rm -rf`
      (`Operation not permitted`) or `hdiutil detach` (`Resource busy`): the
      `/System/Library/AssetsV2/...` dirs carry the **`restricted` flag** and SIP is **enabled**, so
      no `sudo` variant can ever work. ⚠️ **`xcrun simctl` returning "not a developer tool" means
      xcrun cannot RESOLVE it through a CommandLineTools developer dir — NOT that the binary is
      missing.** It lives at
      `/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/bin/simctl` and works
      when called by absolute path, with **no Xcode and no sudo**. `simctl runtime list` confirmed
      `Total Disk Images: 2 (11.4G)`; `simctl runtime delete <UUID>` removed both (async — state
      goes `Deleting`, done in ~15s) by delegating to `simdiskimaged`, which holds the entitlements
      SIP requires. **`/Library/Developer` 32G → 2.1G**, `/Library` 33G → 2.7G — more than the
      11.4 GB estimate, because it also cleared a 6.3 GB dyld cache.
      ✅ **salonx worktrees: took 4.1G, kept every branch.** `.worktrees` 5.6G → 1.5G by deleting
      only `node_modules` (10 × ~526M). `git worktree list` still shows **18**. ⚠️ **Never delete
      the worktrees themselves** — all but `slack-merge-deploy` are ahead of origin/main, and
      `google-oauth-verify-jwt` had 6 uncommitted files. Restore deps with `bun install` per tree.
      🔴 **THE WEEKLY AGENT IS A NO-OP.** 2026-09-06 run logged `delta 0GiB`. uv cache under the
      5.12G cap → polite prune → 2 live `uv` procs held the lock → skipped; then
      `docker image prune -f` found no dangling. Cap never fires, prune never succeeds. See
      [[weekly-prune-agent]].
      **→ STILL OPEN:** (1) add `docker image prune -a --filter until=168h` to
      `~/.local/bin/weekly-prune.sh` (discard IS proven to reach the host — audit 6, `Docker.raw`
      18G→10G no restart); one-time `-a` approval ≠ cron authorization, ask first. (2) Docker sat at
      14G with the **daemon DOWN** — unprunable without starting it, which the agent never does.
      (3) Lower the uv cap below 3G or the polite branch stays dead.
      **Recurring, not one-time:** `com.docker.install/in_progress` (2.1G) and `Caches/Google`
      (2.2G) both regenerated within 13 days of the audit 6 deletion. Expect them every audit.
      ✅ **RESOLVED — `~/theduylifeos` 12G is NOT waste.** Business document vault (OptCo 3.5G,
      Education 3.4G, Projects 1.9G, HoldCo 1.8G, Personal 1.2G). Real user data. **Stop flagging.**
      ⚠️ ~54G remains protected system data needing `sudo` (denied). Never invent a breakdown.
      **AUDIT 8 CLOSED 2026-09-15. ~26 GiB reclaimed, 81%.** 183 GiB used / 12 GiB free / 94%
      → **157 GiB / 39 GiB / 81%**. Trend: 95→92→80→81→83→93→98→86→79→**81%** — the 6-day
      regression (79→94%) was Docker.raw regrowth + uv cache + worktree node_modules.
      Per-category: docker `system prune -a --volumes` after stopping 19 stale postgres
      containers → 11.6G in-VM, `Docker.raw` 25G→14G on host (no restart needed, discard
      reached host again); uv cache 5.7G→130M (killed 2 `uvx code-review-graph` lock-holders —
      they respawn instantly under the MCP supervisor, so kill + `uv cache clean` must run in
      ONE command to win the lock race); `.worktrees/*/node_modules` 5.3G deleted, all 26
      worktrees kept (count grew 25→26); Chrome OptGuideOnDeviceModel 4.0G, Caches/Google 2.3G,
      com.docker.install/in_progress 2.1G, claude versions ~800M (kept 2.1.268 only).
      ✅ **weekly-prune.sh PATCHED:** `UV_CACHE_CAP_MB` 5120→3072 and `docker image prune -a
      --filter until=168h` added before the dangling-only prune (audit-7-approved change).
      `bash -n` clean. Volume prune still deliberately absent — volumes hold local DB state.
      **Recurring, not one-time:** `com.docker.install/in_progress` and `Caches/Google` —
      re-delete every audit.

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
