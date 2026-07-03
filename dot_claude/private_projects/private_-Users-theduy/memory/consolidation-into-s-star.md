---
name: consolidation-into-s-star
description: "Migrating GSD+ECC+Superpowers best parts into /s* worktree workflow, then deleting all three. Phases 1-2 done 2026-06-11, Phase 3-4 deferred for soak."
metadata: 
  node_type: memory
  type: project
  originSessionId: 0e84b4bb-d50a-4709-87e0-f70ddca381f0
---

Consolidating three competing orchestrators into the hand-built `/s*` suite, then deleting GSD + ECC + Superpowers plugins. Spec/todo: `~/tasks/spec-consolidation.md` + `~/tasks/todo-consolidation.md` (status: implementing).

**Key finding:** `/s*` was NOT standalone — it delegated core logic to `superpowers:` skills in s0/s1/s6/full-ship. Difficulty inverted from size: ECC (biggest) trivial to delete, Superpowers (smallest) hardest.

**Done (2026-06-11):**
- Phase 1: copied 16 agents (8 ECC + 8 GSD renamed) → `~/.claude/agents/`; 9 skills (3 discipline + 6 workflow) → `~/.claude/skills/`; 2 hooks (worktree-path-guard.js, format-on-edit.sh) written but NOT yet registered in settings.json.
- Phase 2: rewired s0/s1/s6/full-ship/s3 to user-level skills (chose copy-as-user-skill over inline); CLAUDE.md "Superpowers Integration" → explicit-invoke discipline prose (user chose explicit prose over auto-injector); added Must-Haves schema to s1, verifier step to s3, AgentShield gate to s6.
- 33 files staged in chezmoi source (uncommitted as of session end unless committed later).

**Deferred (user decision: delete after few-day soak):**
- Phase 3: strip GSD's 15 hooks from chezmoi settings.json TEMPLATE (managed — `.chezmoiignore:39-40`), keep worktree-path-guard repointed. Remove `.chezmoiignore:36-41` GSD-agent ignore block.
- Phase 4: uninstall ECC + Superpowers plugins, `rm -rf ~/.claude/gsd-core`, `rm ~/.claude/agents/gsd-*.md`, rm gsd hooks, remove dead superpowers cache `6fd450765978`.
- Decisions locked: keep `code-review-graph` SessionStart hook; auto-trigger replaced by explicit CLAUDE.md prose.

**Gotchas:** old plugins still installed during soak (coexistence-safe; /s* uses unprefixed user skills). `.planning/` refs in 6 harvested GSD agents resolved via call-time path injection, not per-agent sed. ECC hooks are plugin-merged (vanish on uninstall, not in settings.json); Superpowers SessionStart injector + cache erosion persist until Phase 4. Related: [[claude-config-chezmoi-sync]], [[plugin-routing-priorities]], [[gsd-reinstall-global]].
