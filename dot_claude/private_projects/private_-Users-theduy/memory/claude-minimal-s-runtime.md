---
name: claude-minimal-s-runtime
description: "Claude runtime is intentionally limited to /s*, graph engineering, and their ten s-* agents; 951 upstream components remain archived for reviewed weekly distillation"
metadata: 
  node_type: memory
  type: project
  modified: 2026-07-31T21:40:39.837Z
  originSessionId: 2fc43f97-0ad9-457d-97ce-fe1c730e3b94
---

Claude Code uses a deliberately minimal active engineering runtime:

- User skills: `graph-engineering`, `s-auto`, `s0-spec`, `s1-plan`,
  `s2-implement`, `s3-gates`, `s4-review`, `s5-ship`, and `update-distill`.
  `cua-driver` is supplied separately by the installed app.
- Custom agents: `s-code-fixer`, `s-code-reviewer`, `s-gate-runner`,
  `s-implementer`, `s-plan-reviewer`, `s-security-reviewer`, `s-shipper`,
  `s-silent-failure-hunter`, `s-spec-reviewer`, and `s-typescript-reviewer`.
  `s-spec-reviewer` was added 2026-07-31 as the always-on S4 spec axis — the only
  panelist that asks whether the code is what was *approved* rather than whether it
  is *good*.
- Enabled user plugins: only the two output styles and TypeScript LSP. Capability
  plugins, including Superpowers and ECC, remain installed but disabled.
- `/s-auto` recalls graph-engineering lessons directly through
  `~/tasks/graph-engineering/tools/src/recall.ts`; the separate graph-engineer
  workflow is intentionally inactive.

All other skills, commands, and agents were moved—not deleted—to inactive source
archives. Global recovery roots are `~/.claude/skills-archive/runtime-sources/`,
`~/.claude/agents-archive/runtime-sources/`, and
`~/.claude/commands-archive/runtime-sources/`. SalonX project sources are under
`~/Repo/salonx/.claude/skills-archive/runtime-sources/`.

Run `$update-distill` **weekly** (cadence changed monthly→weekly 2026-07-31) and after
upstream/plugin upgrades. Its manifest
sweep checks registered provenance; its catalog checks the full inactive library
(951 component entrypoints as of 2026-07-29). Upstream changes are reviewed per
Source and never auto-applied. Do not reactivate a source provider just to
distill it: read it from the archive/cache, update the owned `/s*` copy after
approval, and leave the provider disabled.

Decision record:
`~/theduyvault/Notes/ADR/2026-07-29-minimal-claude-s-runtime.md`.
