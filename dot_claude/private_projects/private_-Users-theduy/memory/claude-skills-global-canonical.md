---
name: claude-skills-global-canonical
description: ~/.claude/skills is a symlink VIEW over the ~/.agents/skills STORE; global is canonical for the mattpocock package and serves every repo
metadata:
  node_type: memory
  type: project
---

**`~/.claude/skills` is a VIEW, not a store.** It is mostly symlinks (`../../.agents/skills/<name>`) pointing into `~/.agents/skills`, which is the real store — chezmoi-managed (941 files) and read by OMP/Codex via `~/.codex/AGENTS.md` + `sync-claude-inventory.sh`. `.agents/` vs `.claude/` is a **consumer boundary, not a fork**: Codex/OMP reads one, Claude Code reads the other. Any "the two dirs are byte-identical copies" observation is just the same inode seen twice.

**Consequences that matter.** Deleting a symlink from the view hides a skill from Claude while the content survives in the store — cheap and fully reversible by re-linking. Writing a skill *through* the view writes into the store, which the hourly push job ships to Bluehost + Hostinger (see [[claude-config-chezmoi-sync]]). `.gitignore` does **not** stop Claude Code loading a skill: 64 gitignored bmad dirs in salonx were loading at full token cost while invisible to `git status`.

**Decision (2026-08-27): `~/.claude/skills` is canonical for the mattpocock package** and serves every repo, because `/f-o` is a global command in `~/.claude/commands/`. A repo keeps only genuinely repo-specific skills (salonx: `tdd-salonx`, `verify-salonx`). Source of truth is `mattpocock/skills` on GitHub; `salonx/skills-lock.json` (at repo ROOT) records the 35 + 6 JuliusBrussee with per-skill `skillPath`.

⚠️ **`~/.agents/skills/research/` is a directory COLLISION** — it holds mattpocock's `research/SKILL.md` *and* an unrelated family (`arxiv`, `polymarket`, `blogwatcher`, `llm-wiki`, `grounded-citations`, `competitor-news-monitor`, `research-paper-writing`, `blocked-page-recovery`, + 3 `.bak`). **Refresh by merge-copy, never by replacing the directory** — `rm -rf` + copy destroys all of it. `~/claude-skills-refresh.sh` does this correctly and asserts the 8 survive.

⚠️ **Five mattpocock skills are `disable-model-invocation: true`** — `to-spec`, `to-tickets`, `triage`, `grill-with-docs`, `implement` (28 of 160 skills carried the flag). They are hidden **by design**, not by `skillListingBudgetFraction` truncation, and pruning does not reveal them. A slash-command's prose saying "run /to-spec" does NOT count as the user typing it, so the Skill tool refuses. The working route is to **read `~/.claude/skills/<name>/SKILL.md` and follow it inline** — which is what `/f-o` now instructs. Upstream is independently converting these to "Call the Skill tool with X".

⚠️ **`~/.claude/commands/f-o.md` and `claude-pi.md` are NOT chezmoi-managed** — only `vault-save.md` is. They exist on the Mac alone. This is the `re-add` never DISCOVERS trap: unmanaged files are invisible to the sync, to `chezmoi status`, and to any drift check, so nothing ever reports their absence on the VPSes.
