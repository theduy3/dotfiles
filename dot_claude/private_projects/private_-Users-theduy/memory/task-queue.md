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

- [ ] **Storage audit — audit 7, 2026-09-08. REGRESSED, nothing reclaimed yet.** Report (live,
      same URL): https://claude.ai/code/artifact/bf3a6e2f-1d65-4608-97d0-d2ca6ad3d9a9 · local
      `~/tasks/mac-inventory-audit.html`. Agent: [[weekly-prune-agent]].
      **183 GiB used / 13 GiB free / 94%** — gave back 16 GiB in 13 days after audit 6's 86%.
      Touched **100% / 1.9 GiB free mid-audit**, then recovered to 13 GiB **on its own** (macOS
      purged under pressure — not my doing, do not credit any action for it).
      Trend: 95→92→80→81→83→93→98→86→**94%**.
      🔴 **THE WEEKLY AGENT IS NOW A NO-OP.** 2026-09-06 run logged `delta 0GiB`. Both branches fail
      structurally: uv cache under the 5.12G cap → polite `prune` branch → 2 live `uv` procs held
      the lock → skipped; then `docker image prune -f` found no dangling. Healthy, on schedule,
      reclaims zero.
      🆕 **11.4 GB ORPHANED SIMULATOR RUNTIMES — invisible to all 6 prior audits.**
      `/Library/Developer/CoreSimulator` = 30G. **Xcode is NOT installed** (`xcode-select` →
      CommandLineTools, no `Xcode.app` anywhere, `xcrun simctl` does not exist).
      ⚠️ **TWO MEASUREMENT TRAPS — do not repeat:** (1) `du` on
      `CoreSimulator/Volumes/{iOS_23C54,watchOS_23S303}` reports 24G, but those are **mounted sealed
      read-only APFS volumes** (`/dev/disk5s1`, `/dev/disk7s1`) — `du` measured decompressed
      content, and `rm -rf` cannot touch them. (2) They are **disk images**, not partitions
      (`diskutil info` → `Virtual: Yes, Protocol: Disk Image`); only one physical disk exists
      (251GB, container disk3 = 245.1GB). Real bytes = two `.dmg` under `/System/Library/AssetsV2/`
      (`com_apple_MobileAsset_iOSSimulatorRuntime` **7.8G** +
      `com_apple_MobileAsset_watchOSSimulatorRuntime` **3.6G**) = **11.4G, the honest figure**.
      Removal needs `sudo` (denied) and must **detach the images first**
      (`hdiutil detach /dev/disk5`, `/dev/disk7`) before deleting the assets.
      🆕 **salonx `.worktrees` 5.6G — but do NOT delete worktrees.** 17 exist; **every one except
      `slack-merge-deploy` is ahead of origin/main**, and `google-oauth-verify-jwt` has 6
      uncommitted files. Only `slack-merge-deploy` (62M, detached HEAD, ahead=0, dirty=0) is safe to
      remove. **The space is the `node_modules`:** 10 worktrees × ~526M = **4.6G**, regenerable with
      `bun install`, zero risk to unmerged commits. Take those, keep every branch.
      **Regenerated since audit 6** (deleting them is recurring, not permanent):
      `com.docker.install/in_progress` **2.1G** back, `Caches/Google` **2.2G** back,
      `App Support/Google` 7.1 → **10G**. Docker back to **14G with the daemon DOWN** — unprunable
      without starting it, which the agent deliberately never does.
      ✅ **RESOLVED — `~/theduylifeos` 12G is NOT waste.** Flagged unaudited in audits 5 and 6. It is
      a business document vault (OptCo 3.5G, Education 3.4G, Projects 1.9G, HoldCo 1.8G, Personal
      1.2G), one file >200M. Real user data. **Stop flagging it.**
      **→ STILL OPEN from audit 6:** add `docker image prune -a --filter until=168h` to
      `~/.local/bin/weekly-prune.sh`. Docker discard IS proven to reach the host (audit 6:
      `Docker.raw` 18G→10G, no restart). One-time `-a` approval ≠ cron authorization; ask first.
      ⚠️ Reclaim available ≈ **20G**, and **Claude can action almost none of it** —
      `Bash(rm -rf *)` and `Bash(sudo *)` are both denied. Do NOT route around either.

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
