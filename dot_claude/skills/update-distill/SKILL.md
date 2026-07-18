---
name: update-distill
description: Monthly refresh of the /s* distillates — re-hash every Source in the sidecar manifests, show what drifted, propose scoped edits to the owned copies, and apply only what the user approves per Source. Use monthly, after plugin updates, or when a Source skill/agent is known to have changed. Never modifies a Source; never auto-applies.
---

# `/update-distill` — reviewable refresh of the owned copies

The `/s*` skills and `s-*` agents are self-contained copies distilled from upstream
Sources. Sources evolve; this command is how improvements flow in — as a **reviewed
diff**, never a silent sync.

## Inventory

Every distillate carries a sidecar manifest with per-Source `{path, hash, took}` rows:

- `~/.claude/skills/{s0-spec,s1-plan,s}/.manifest.yaml`
- `~/.claude/agents/.s-{code-reviewer,security-reviewer,silent-failure-hunter,typescript-reviewer,code-fixer,implementer,gate-runner,shipper}.manifest.yaml`
- `~/.claude/skills/update-distill/.manifest.yaml` (this skill — no upstream Sources)

## Procedure

### 1. Sweep

For every manifest, for every Source row: resolve the path (follow symlinks),
`shasum -a 256`, compare to the recorded hash.

- **Unchanged** → skip.
- **Missing** → the Source moved or was uninstalled. Plugin paths are versioned
  (`…/superpowers/6.1.1/…`) — search for the same skill/agent name under the plugin
  root and treat the new path as **changed** (update the manifest `path` on
  approval). Truly gone → report as `missing`; the distillate keeps working (it is
  self-contained) but its provenance row goes stale — flag for a human decision.
- **Changed** → step 2.

### 2. Scoped diff — per changed Source

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

### 3. Approve — per Source, no batching

Ask the user per changed Source (AskUserQuestion; recommend accept/reject with
reasoning): **apply** or **reject**. A rejection is recorded, not silently
re-proposed next month — add a `rejected: <hash> (<date>, why)` note to that
Source's manifest row so the next sweep can skip an unchanged-since-rejection hash.

### 4. Apply

For each approved Source: edit the distillate, update the manifest row (`hash`,
refresh `took` if the extraction changed, `distilled:` date), then
`chezmoi add` both files.

### 5. Report

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
