---
name: update-distill
description: Weekly refresh of the /s* distillates — re-hash every Source in the sidecar manifests, show what drifted, propose scoped edits to the owned copies, and apply only what the user approves per Source. Use weekly, after plugin updates, or when a Source skill/agent is known to have changed. Never modifies a Source; never auto-applies.
---

# `/update-distill` — reviewable refresh of the owned copies

The `/s*` skills and `s-*` agents are self-contained copies distilled from upstream
Sources. Sources evolve; this command is how improvements flow in — as a **reviewed
diff**, never a silent sync.

## Inventory

Every distillate carries a sidecar manifest with per-Source `{path, hash, took}` rows:

- `~/.claude/skills/{s-auto,s0-spec,s1-plan,s2-implement,s3-gates,s4-review,s5-ship}/.manifest.yaml`
- `~/.claude/agents/.s-{code-reviewer,security-reviewer,silent-failure-hunter,typescript-reviewer,code-fixer,implementer,gate-runner,shipper}.manifest.yaml`
- `~/.claude/skills/update-distill/.manifest.yaml` (this skill — no upstream Sources)

## Procedure

### 1. Sweep

Run the deterministic sweep first:

```bash
bash ~/.claude/skills/update-distill/scripts/sweep.sh
```

It resolves archived local Sources, checks every manifest hash, and compares
versioned plugin paths with the plugin's currently installed version. An old cache
directory still existing must never hide a newer installed plugin.

- **Unchanged** → skip.
- **Newer plugin version** → read the current installed Source in full and treat it
  as changed even when the manifest's older cache path still exists.
- **Missing** → the Source moved or was uninstalled. Plugin paths are versioned
  (`…/superpowers/6.1.1/…`) — search for the same skill/agent name under the plugin
  root and treat the new path as **changed** (update the manifest `path` on
  approval). For local Sources, search `~/.claude/skills-archive/` and
  `~/.claude/agents-archive/`; inactive Sources belong there and remain valid
  provenance. Truly gone → report as `missing`; the distillate keeps working (it
  is self-contained) but its provenance row goes stale — flag for a human decision.
  Once that decision is taken, record it on the row as
  `removed: <why> <date>` and the sweep reports it as **`REMOVED_ACK`** thereafter
  instead of re-raising it. Do **not** remap a row to a dated backup directory
  (`.gsd-removal-backup-*`) — that is a temp path, so it defers the same breakage and
  lengthens the trail.
- **`REMOVED_ACK` / `REJECTED_ACK`** → a decision already recorded on that row.
  Reported so no row is ever hidden, but neither sets the exit code. Both are
  deliberately narrow:
  - `removed:` suppresses **only the absence**. If the Source ever comes back, the row
    resumes normal hash checking — a Source returning is news.
  - `rejected:` is **hash-scoped**. It silences the one version it names; drift to any
    other hash fires again. A rejection settles a version, never a Source.
- **Changed** → step 2.

Rows pointing from the manual `s2`–`s5` wrappers to owned `/s*` artifacts are
internal dependency checks, not upstream doctrine. Drift means re-check the
wrapper's stage contract against the changed owned artifact; never copy prose
mechanically.

### 2. Discover unregistered upstream changes

The manifest sweep only covers doctrine already distilled. Check the full inactive
source library for newly added, changed, or removed components:

```bash
bash ~/.claude/skills/update-distill/scripts/catalog.sh diff
```

The catalog covers archived skills/agents, `~/.agents/skills`, GSD workflow
Sources, and every currently installed plugin version whether enabled or disabled.
Additional project archives are listed one absolute path per line in
`~/.claude/update-distill/catalog-roots.txt`.
For each `NEW` or `CHANGED` component, inspect its name and description first.
Read the body only when it could improve an existing `/s*` stage or close a known
coverage gap. Do not expand `/s*` merely because upstream added something.

After all approved/rejected decisions are recorded, refresh the baseline:

```bash
bash ~/.claude/skills/update-distill/scripts/catalog.sh snapshot
```

### 3. Scoped diff — per changed Source

The old Source content is not retrievable from the hash; the comparison target is
the **distillate**, guided by the manifest's `took` notes:

1. Read the new Source in full.
2. Identify what changed *in the regions the `took` notes say we harvested* —
   new rules, changed thresholds, removed doctrine, new failure modes. Ignore drift
   in regions we deliberately dropped (the `took` notes name those too).
3. Draft the corresponding edit to the owned copy, preserving the distillate's
   voice, structure, and /s*-specific adaptations (model pins, verdict contracts,
   halt taxonomy, severed references — these are OURS, never "fixed back" to the
   Source's version).
4. Present, per Source: a short changelog of what drifted upstream + the proposed
   inline diff of the owned artifact.

### 4. Approve — per Source, no batching

Ask the user per changed Source (AskUserQuestion; recommend accept/reject with
reasoning): **apply** or **reject**. A rejection is recorded, not silently
re-proposed next month — add a `rejected: <hash> (<date>, why)` note to that
Source's manifest row so the next sweep can skip an unchanged-since-rejection hash.

### 5. Apply

For each approved Source: edit the distillate, update the manifest row (`hash`,
refresh `took` if the extraction changed, `distilled:` date), then
`chezmoi add` both files.

### 6. Report

```
| Artifact | Source | Status |
|---|---|---|
| s0-spec | skills/spec | unchanged |
| s-code-reviewer | agents/code-reviewer | UPDATED (approved) |
| s-implementer | superpowers TDD | changed → rejected (reason) |
| s-shipper | gsd-core ship.md | missing → remapped to <new path> |
```

## Rules

- **Never modify a Source.** Read-only, always.
- **Never auto-apply.** No approval, no edit — even for "trivial" drift.
- **Never resurrect severed references.** If an upstream Source starts delegating to
  another skill, distill the content, not the call.
- A distillate with zero changed Sources this sweep is healthy, not stale — say so
  and move on.
