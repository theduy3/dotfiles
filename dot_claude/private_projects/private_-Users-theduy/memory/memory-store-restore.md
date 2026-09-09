---
name: memory-store-restore
description: "The live memory store vanished from disk on 2026-09-08; chezmoi held every file and chezmoi apply --force restored all 59"
metadata:
  node_type: memory
  type: reference
  modified: 2026-09-08
---

On 2026-09-08 the whole live memory directory `~/.claude/projects/-Users-theduy/memory/` was
**absent from disk**. All 59 files were gone, including `MEMORY.md`, `task-queue.md` and every
project note. The likely cause is the config reorganization of 2026-08-27, which also took
`~/.claude` from 3.8G down to 1.3G and left `~/claude-config-archive-20260827-0128` in home. That
archive did **not** contain the memory files.

**Nothing was lost.** chezmoi held every file, fully current, at
`~/.local/share/chezmoi/dot_claude/private_projects/private_-Users-theduy/memory/`.

**Why:** chezmoi is the source of truth for `~/.claude`, and the memory store rides along with it.
See [[claude-config-chezmoi-sync]].

**How to apply:**

- Check first: `chezmoi status ~/.claude/projects` — a `DA` prefix means deleted locally, would be
  added back by apply.
- Restore with `chezmoi apply --force ~/.claude/projects/-Users-theduy/memory`.
- ⚠️ Plain `chezmoi apply` fails here with `could not open a new TTY: open /dev/tty: device not
  configured`. chezmoi wants to prompt because the target changed since it last wrote. `--force` is
  safe when the target is **absent** — there is nothing to overwrite. Do not use `--force` blindly
  when the target exists.
- The `private_` prefix in the source path is chezmoi's permission encoding (0700), not part of the
  directory name.

**Lesson:** before treating any `~/.claude` loss as real, check the chezmoi source. The live tree is
a deployment target, not the record.
