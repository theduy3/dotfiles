---
name: discord-driven-pipeline
description: "SalonX Discord-driven spec→critic→plan→critic→ship redesign; 3 plans, spec gate proven live, plan gate blocked on stale-mirror verification"
metadata: 
  node_type: memory
  type: project
  originSessionId: ba885a40-e5b1-430d-ac45-c21c2611e5f3
---

Redesign replacing the monolithic `gsd-runner.yml` off-box build with a Discord-driven,
per-task loop for `Wylios-Dev/salonx`. Three plans (specs/plans in `~/tasks/`):

- **Plan 1 — task-runner loop** (`todo-task-runner-loop.md`): `.github/workflows/task-runner.yml`,
  one TDD task per dispatch, state = `tasks/todo-*.md` frontmatter on the feature branch. BUILT +
  MERGED, 5/5 smokes. Core logic in `scripts/task-runner/todo.mjs` (parseTodo/gate). Frontmatter
  contract: `attempts:` is a BARE line (empty), task rows are EXACTLY `- [ ] NN-NN Title`.
- **Plan 2 — ship/stop poller** (`todo-ship-stop-poller.md`): `~/.hermes/work/ship-poller.py` on
  `hermes-wylios`, owner types `ship WYL-N [branch]` / `stop WYL-N` in #product-dev → flips plan
  `status` + fires `task-run` repository_dispatch. IMPLEMENTED + PROVEN LIVE (both verbs e2e).
  Entrypoint launch block added; deployed via docker cp (volume-backed, durable).
- **Plan 3 — PL bot gates + critic** (`todo-pl-bot-gates.md`): `.github/workflows/critic.yml`
  (memory-less, write-less, `repository_dispatch: [critic-run]`) + `critic-findings.mjs` MERGED
  (PR #1234). PL bot AGENTS.md rewritten (spec→critic→plan→critic→ship, no more Engineer handoff)
  and deployed to both source + instance on the box.

**SPEC GATE PROVEN LIVE (2026-07-12):** PL bot committed `spec-social-rewards-p9.md` to
`feat/social-rewards-p9` → critic located it among 78 specs (deterministic branch-path, not
glob — the #1167-class fix) → clean 0 findings → posted to Discord "WYL-44: spec critique"
thread → owner approved.

**PLAN GATE FIXED + PROVEN (2026-07-12).** The "heartbeat/verification override" was a STALE
PERSISTED SESSION: `persistSession: true` made the bot resume its June-25 pre-pause session
(carrying WYL-31 context + the old reassign-to-Engineer flow) — confirmed in the run-log ndjson.
Three fixes: (1) `paperclipai agent runtime-state:reset-session <id>` clears it; (2) AGENTS.md
new ABSOLUTE RULE "read repo state ONLY via `gh api` against origin, never the main-only mirror"
+ explicit Step-4 gh-api spec read (kills the false "branch empty" loop); (3) mandatory
`in_review` disposition as the last action (avoids missing-disposition block). After fixes, the
plan gate ran clean: grounded the plan against real code via gh api, committed a parser-valid
`todo-social-rewards-p9.md` (attempts bare, max_dispatches 18, `- [ ] 09-01` rows, 9 tasks),
plan critic clean 0 findings → Discord, issue correctly `in_review`. BOTH GATES PROVEN.

**FULL PIPELINE PROVEN END-TO-END ON A REAL FEATURE (2026-07-13).** Owner typed
`ship WYL-44 feat/social-rewards-p9` in #product-dev → ship-poller acked "shipping — first task
dispatched" → flipped plan `plan-approved→implementing` → fired `task-run` → task-runner loop
run 29269300235 building Phase 9 (09-01 approve/reject RPCs + pgTAP first). Complete chain:
Discord ship → poller → dispatch → loop → build. GOTCHAS confirmed live: (a) bare `ship WYL-N`
USED to fail "no branch given" — **FIXED 2026-07-16 (#4):** `derive_candidate_branch` in
`~/.hermes/work/ship-poller.py` scans the Paperclip issue description + comments for the most
recent `feat/<slug>` (the bot's "Spec committed to `feat/<topic>`" note records it — no PL-bot
change), `resolve_branch` validates it (wrong/merged-away guess fails closed). Uses
`wylios-paperclip.py get` + `npx paperclipai issue comments <id>` (cwd=PC_DIR). Live-tested
`derive(WYL-44)=feat/social-rewards-p9`. ⚠️ restart the poller via `docker exec -u hermes -d …
setsid python3 …`, NEVER `pkill -f ship-poller.py` (the bash-c wrapper self-matches, kills its own
shell). Bare `ship WYL-N` now works. (b) owner must approve the PLAN before ship — flips todo `draft→plan-approved`;
if skipped, flip it manually via Contents API (owner shipping = approval intent). Remaining:
watch the multi-hour build → PR → §10 diff vs run-#66 benchmark (`~/benchmarks/wyl-44-phase-9/`).

**Also 2026-07-13: user's Mac disk hit 100% full (147MB free of 228Gi) — system-wide, not
session scratch. Blocks background-task output writes (ENOSPC). Flag to user; work foreground.
uv cache had 2063 orphaned `.tmp*` dirs (~5G) that `uv cache clean`/`prune` DON'T remove;
manual `rm -rf ~/.cache/uv/.tmp*` reclaims them.**

**WYL-44 Phase 9 COMPLETE (2026-07-14), PR #1276 ready.** All 9 tasks built/tested/i18n'd on
`feat/social-rewards-p9`. §10 acceptance diff: per-task rebuild 19 files/2435 ins vs run-#66
monolith 14 files/2347 ins — NOT thinner, BETTER structured (4 focused UI components vs 1
monolith file; +1 SECURITY DEFINER staff-read RPC the RLS-gap surfaced). Decomposition MODEL
validated. But the autonomous LOOP hit TWO real defects on the ~2-day multi-task build, so
09-04 + 09-06..09-09 were hand-built via subagents + pushed with a workflow-scoped token:
  1. **task timeout too low** — 45m couldn't fit TDD+full gates (typecheck+lint+pgTAP+build) on
     heavy tasks. Fixed 45→90m (PR #1284). BUT bumping it merged a `.github` change to main
     MID-BUILD → triggered defect 2. Lesson: DRAIN the loop before changing its own workflow on main.
  2. **`sync-github.sh` + scopeless App token can't push when main's `.github` drifts mid-build.**
     The step makes branch `.github`==main so GitHub's "App can't modify workflows" check passes;
     but when OTHER PRs keep merging `.github` to main during a long build, every task re-syncs +
     the workflow-file push is racy/rejected. Chronic on multi-day builds.
     **FIXED + merged 2026-07-15 (PR #1287, main @ 2419a8b2):** push step now wraps sync+push in a
     5-attempt retry that RE-FETCHES main each attempt (re-fetch inside the loop is the load-bearing
     part — retrying against a moving target must re-read where the target is now). CODE_HEAD reset
     each attempt so sync commits don't stack; bare commands guarded vs inherited errexit; a real
     `.github`-modification violation still fails loud with no retry. Locked by
     `workflow-invariants.test.sh` check 6 (now 7/7). The loop can now run a long multi-task build
     unattended. NOT YET proven on a real fresh build — Phase 10 through the loop is that proof.
  3. **Blind retry (autonomous-loops anti-pattern #3).** The retry re-dispatched a failed task with
     an IDENTICAL prompt → re-fails. **FIXED + merged 2026-07-16 (PR #1292, main @ d2c0bdec):** a red
     task captures gate output + claude stderr → `.task-runner/fail-<task>.md`, commits+pushes it
     robustly; the next dispatch's implement step injects it into the prompt so the retry fixes the
     root cause; success-commit deletes it. Extracted #1287's retry push into
     `scripts/task-runner/push-with-retry.sh` (success AND failure pushes call it, so the failure
     context reliably lands). Gitignored run.jsonl/run.stderr/.task-runner/tmp (were leaking into
     PRs). Locked by `workflow-invariants.test.sh` checks 6+7 (8/8). ALL 3 LOOP-AUTONOMY FIXES NOW
     ON MAIN (timeout90 #1284, push-race #1287, failure-context #1292) — still test-proven only; a
     live Phase-10 run is the falsification test for "unattended". Threading all 3: each fixes a
     BLIND retry (moving main / repeated failure) by carrying current reality into the next attempt.
Critic blind spot also found: it reviews spec/plan as DOCUMENTS, missed that 09-04 querying an
RLS-locked table from the anon browser is impossible (repo's own lesson). Plan-critic should
verify claims like "query table X" against X's grants via gh api.

**Key box verbs:** `paperclipai agent resume|wake|runtime-state:reset-session <id>`;
`paperclipai issue recovery:resolve <id> --outcome restored --source-issue-status in_review`;
`paperclipai issue comment|comments|checkout|release|requeue <id>` (all `npx --yes paperclipai`,
run inside the hermes-wylios container).

**Also learned this session:**
- PL bot = Paperclip instance `8b56f331`; `.paperclip` → symlink to `.hermes/paperclip/instance`.
  Runtime reads the INSTANCE AGENTS.md. `paperclipai` is `npx`-run (no global binary).
- Paperclip requires every SUCCESSFUL run to end in a terminal disposition (NOT `in_progress`),
  `maxHandoffAttempts: 1` → one miss = "missing_disposition" escalation → issue `blocked`.
  Resolve: `paperclipai issue recovery:resolve <id> --outcome restored --source-issue-status in_review`.
- `PRODUCT_DEV_FORUM_ID` was NOT a salonx Actions secret (plan grounding was wrong); added it
  (value = public #product-dev id `1507452368260694096`). Only `CLAUDE_CODE_OAUTH_TOKEN` +
  `DISCORD_BOT_TOKEN` pre-existed.
- No Discord→Paperclip bridge for SPEC approval (only the PR-merge approval-poller); owner
  approval typed in a critique thread must be relayed into Paperclip manually.
- CEO / Engineer / Product-Lead agents were all manually paused late-June (old-pipeline breakage
  era); only Product-Lead was unpaused this session.

Related: [[gsd-offbox-pipeline]], [[hermes-wylios-coding-pipeline]], [[salonx-mirror-personas]],
[[hermes-platform-topology]].
