---
name: hostinger-gsd-runtime-live
description: "Global harness changes NEVER reach Hostinger (Linux settings.json is chezmoi-ignored) — GSD survived there 5 days after the Mac removal; cleaned up 2026-08-12, backup at /root/.claude/.gsd-removal-backup-20260812"
metadata: 
  node_type: memory
  type: project
  originSessionId: af9594d9-ef17-4ac2-a3fd-a86b11e205c6
  modified: 2026-08-12T21:48:02.158Z
---

## The durable lesson

**Linux `settings.json` is chezmoi-ignored *by design*** (see [[claude-config-chezmoi-sync]]), so
nothing done to the Mac's config template propagates to Hostinger. Additive drift is visible;
**subtractive drift is invisible** — the VPS never receives *deletions*, and nothing surfaces the
gap until something resolves that shouldn't.

**Before trusting any "removed/installed globally" claim, check Hostinger separately.** Every VPS
harness change is hand-wired and persists independently.

## The instance that proved it (discovered + fixed 2026-08-12)

The 2026-08-07 GSD removal was **Mac-only**. Five days later Hostinger still ran the complete
pre-removal generation: **71 `gsd-*` skills, 34 `gsd-*` agents, 15 wired hook entries across 12
distinct scripts (25 `gsd-*` scripts on disk), a 7.3M `~/.claude/gsd-core/`, and a
`Bash(npx gsd-core *)` permission rule** — while `/s*` was also installed. Both loop owners
resolved simultaneously on the always-on unattended box, violating the one-loop-owner rule in
`~/CLAUDE.md` (whose "all `/gsd-*` commands are gone" was true of the Mac only).
The engine was already gone (`~/.gsd` and `@opengsd` npm both absent) but the wiring was live, so
the hooks cost latency per tool call while protecting nothing — fail-open, same failure mode as the
2026-08-07 `worktree-branch-guard.js` audit.

✅ **RESOLVED 2026-08-12.** Mirrored the Mac removal. Backup **`/root/.claude/.gsd-removal-backup-20260812`**
(8.8M: skills/ agents/ hooks/ gsd-core/ settings.json) — restore by copying back.
Verified after: settings.json parses, 16 hook entries, **0** gsd refs, **0 dangling hook targets**,
`/s*` intact (8 skills + 10 `s-*` agents), claude 2.1.227 runs, herdr active.
Counts went 134→63 skills, 88→54 agents, 60→35 hooks.

⚠️ **`~/.claude.json` was deliberately NOT touched** — the Mac still has 24 `gsd-` hits there, so it
is not part of the reference state. Don't "clean" it without checking the Mac first.

⚠️ **The substring-collision trap is real here:** `gsd-worktree-path-guard.js` *contains*
`worktree-path-guard.js`, and the neutral guards sat at `PreToolUse[6][7]` immediately beside the
GSD one at `[4]`. **Anchor every match on `/gsd-`** or a loose filter deletes the neutral guards.

## 🔥 The chezmoi source still carries 31 `gsd-*.md` agents — and one ignore rule is all that stops them

`~/.local/share/chezmoi/dot_claude/agents/gsd-*.md` has existed since the initial snapshot
`7dc4c83` and was **never removed**. The `.chezmoiignore` line `.claude/agents/gsd-*.md` is the
**only** thing preventing `chezmoi apply` from writing all 31 back onto every device.

**Incident 2026-08-12:** that rule was deleted as "stale GSD residue" (its comment said GSD was
regenerable, which read as obsolete). Within the hour the Mac restored 31 agents at 11:22 and both
VPSes pulled them at 19:00Z — silently undoing the same-day Hostinger cleanup and putting `/s*` and
`/gsd-*` back in competition everywhere. Rule restored in `618ad55` with a load-bearing warning;
deployed copies removed by hand on all three boxes (Mac→55 agents, Hostinger→54, Bluehost→53).

⚠️ **`.chezmoiignore` BEATS `.chezmoiremove`.** An ignored path is excluded from the target state
entirely, so a `.chezmoiremove` entry for it never fires. Proven the same day: `.omx` (not ignored)
was deleted correctly by the very apply that left all 31 ignored gsd agents untouched. You cannot
use `.chezmoiremove` to clean up something you are also ignoring — remove it from the **source**, or
delete it by hand per box.

**Permanent fix still pending:** `git rm dot_claude/agents/gsd-*.md` from the source, after which
both the ignore rule and the explanatory note in `.chezmoiremove` can be dropped.

## Bluehost carried the same pre-removal generation — ✅ CLEANED 2026-08-12

Because it had never synced (see the PATH bug in [[codex-claude-inventory-mirror]]), Bluehost kept
its own GSD generation: 69 gsd skills, 19 gsd hook scripts, 16 hook entries + 1 permission rule in
settings.json, 6.2M `gsd-core/`, 34 gsd agents — engine gone, wiring live, `/s*` also present.
It is a production box (hermes-wylios, hermes-dashboard, hermes-autoheal, agentmemory-main).
It still carried `gsd-phase-worktree-guard.js`, which the Mac deleted 2026-08-07 — confirming an
older generation than Hostinger's.

Removed, backup at **`/root/.claude/.gsd-removal-backup-20260812`** (7.2M: skills/ hooks/ agents/
gsd-core/ settings.json). Verified after: settings parses, 16 entries, 0 gsd refs, 0 dangling hook
targets, neutral `worktree-*-guard` hooks intact, `/s*` 8 skills, claude 2.1.220 runs.

**All three boxes now read 0 gsd agents / 0 gsd skills / 0 gsd settings refs** —
Mac 55 agents, Hostinger 54, Bluehost 53.

## Still divergent (deferred by user 2026-08-12)

`~/.agents/skills` = **146 on Mac, 2 on Hostinger**; `~/.agents` is chezmoi-managed on neither box,
so there is **no sync path at all**. Hostinger also carries 7 `gitnexus-*` skills the Mac lacks.
Options weighed: add `~/.agents` to chezmoi (hourly push, but it is a push-on-add mirror not a live
one) vs an on-demand rsync. Related: [[plugin-routing-priorities]], [[herdr-host-hostinger]],
[[claude-plugins-not-chezmoi-synced]].
