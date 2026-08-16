---
name: timemachine-interrupted-loop
description: Time Machine stuck not backing up — lost reference snapshot causes deep-scan→interrupt loop on portable USB drive; fix is one uninterrupted run
metadata: 
  node_type: memory
  type: reference
  originSessionId: d064ca92-fca5-4182-955e-111ece8a6942
---

MacBook Time Machine "not working" (diagnosed 2026-07-13). Destination = Seagate "Expansion" 5TB USB, APFS-encrypted TM partition `/Volumes/Time Machine` (~1TB, plenty free). Engine, config, space all fine — `AutoBackup=1`, `disksleep=0`.

**Root cause:** last *completed* backup was ~2 months stale; its local reference snapshot (`com.apple.TimeMachine.<date>.local`) aged out / thinned away. Logs showed `Failed to mount reference snapshot` + `fs_snapshot_list failed: Operation not supported`. With no anchor, every run becomes a full **deep scan** of the whole Data volume → hours long → on a bus-powered portable + laptop it gets disconnected/slept before finishing → run ends `.interrupted`. Next run: still no anchor → deep scan again. Vicious loop. Fingerprint = destination littered with `.interrupted`/`.inprogress`/`.previous` folders spanning months, nothing completing.

**Fix (break loop with ONE complete run):**
1. `tmutil startbackup` — engine runs fine when triggered manually (`tmutil status` → `Running=1`).
2. Keep drive plugged + Mac awake for whole run: `nohup caffeinate -dimsu >/dev/null 2>&1 &` (background it; the tracked/plain background variant gets culled at turn boundaries — relaunch or nohup-detach).
3. Watch: `tmutil status` fields `_raw_totalBytes` / `bytes` are honest progress; top-level `Percent` is phase-weighted and lags. Phase walks `FindingChanges → Copying → ThinningPostBackup → Running=0`.
4. Completion mints a fresh `.backup` = new reference anchor → future hourly backups are fast incrementals again. Old `.interrupted` debris thins automatically, no manual delete (delete needs Full Disk Access anyway; plain Terminal lacks it → `Operation not permitted` on the TM volume + `tmutil latestbackup`).

**Gotchas:**
- `log` is shadowed by a shell alias here → use `/usr/bin/log show --predicate 'subsystem == "com.apple.TimeMachine"' --last 30m --info`.
- `backupd` runs as root, unaffected by Terminal's missing Full Disk Access — FDA errors in my shell are irrelevant to whether backups work.
- Recurrence trigger is *interruption*, not a bug: after any long gap, leave the portable docked through one backup.

Related: internal disk was low (~7.7GB free vs 15GB TM local-snapshot target) — separate from external backup, ties to [[task-queue]] disk-cleanup (Docker.raw 27GB).
