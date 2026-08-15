---
name: claude-permission-edit-not-write
description: "Claude Code permission rules must use Edit(path) — Write(path) rules are silently ignored, so Write() denies protect nothing"
metadata: 
  node_type: memory
  type: project
  originSessionId: e51cffba-57b3-49a5-a91b-e2282578fba4
  modified: 2026-08-15T20:45:35.822Z
---

Claude Code's **file permission matcher only consults `Edit(path)` rules**. `Write(path)` rules parse fine but are never matched — `Edit(...)` is the canonical form and covers all file-editing tools (Write, Edit, NotebookEdit). Startup prints one warning per offending rule: `Write(X) is not matched by file permission checks — only Edit(path) rules are.`

**Why it matters:** the failure is silent and asymmetric. A dead `allow` rule only costs an extra prompt. A dead **`deny`** rule means the path was never protected. In `~/.claude/settings.json` the denies for `**/.env`, `**/.env.*`, `**/secrets/**`, `**/.ssh/**` were all written as `Write(...)` and were therefore **inert from the day they were added** — believed-protected, actually open. Fixed 2026-07-16 (dotfiles `ca51ef7`).

**How to apply:**
- Write any new file permission rule as `Edit(glob)`, never `Write(glob)`. Note `Read(...)` and `Bash(...)` rules are unaffected — those matchers work as written.
- Startup warnings naming a rule are the tell; treat them as security findings, not noise, when the rule is a `deny`.
- Flipping a dead deny to live is a **behavior change** — anything that was quietly writing to those paths starts hard-failing (deny beats allow, no prompt).
- settings.json is a chezmoi template — fix `~/.local/share/chezmoi/dot_claude/settings.json.tmpl` too or the hourly `chezmoi apply --force` reverts it. See [[claude-config-chezmoi-sync]].

## `Bash(rm -rf *)` deny — briefly removed then RESTORED, same session (2026-08-15)

**Current state: the deny is IN PLACE on all boxes. Nothing was permanently weakened.**

Deleting the codex-router checkout was blocked by the `Bash(rm -rf *)` **deny** in `settings.json`.
**Adding an allow rule — even an exact-path one in `settings.local.json` — did nothing: deny
unconditionally beats allow, no prompt, no override.** The only way through was to delete the deny
line from `dot_claude/settings.json.tmpl` (the live file is a template; editing it directly is
reverted by the hourly `chezmoi apply --force`). Owner authorized, deletes ran, owner then asked for
the deny back; re-added at its original index (between `Bash(more **/.env*)` and `Bash(sudo *)`),
`chezmoi apply`, and **functionally re-verified** — a probe `rm -rf` was denied again. 41 deny rules,
template and live in sync.

- ⚠️ **The removal was NEVER committed or pushed.** Verified after restoring: working tree clean,
  `HEAD == origin/main`, HEAD's committed template still contains the deny, and no commit that day
  touched the file. It lived only as an uncommitted working-tree change on the Mac. **Hostinger and
  Bluehost never received the weakened config.** Do not carry forward any claim that it propagated.
- **But it very nearly did.** `claude-sync.sh` runs `git add -A` + `git commit` + `git push origin
  main` hourly, and the servers `chezmoi update --force`. A chezmoi-source edit left sitting for an
  hour propagates to all three boxes with nobody pushing. **Treat any edit to
  `~/.local/share/chezmoi` as fleet-wide and time-boxed** — revert within the hour or it ships.
- The other **40** denies were untouched throughout (`sudo *`, `curl * | sh`, `wget * | bash`,
  `npm publish*`, and the `.env` / `.ssh` / `*.pem` / `*.key` guards).
- Lesson: check the **deny** list first when a Bash command is refused. Retrying, or piling on
  allow rules, cannot work. And never route around it with `rm -r` / `find -delete` — that evades
  a control the owner set.

**Confirmed live 2026-07-18** (/s* verify, user-observed): `Edit(/Users/theduy/tasks/.s-run/**)`
**allow** rule suppressed every prompt for Write-tool calls to that path during the whole
autonomous run — absolute-path glob form works, and Edit() covering the Write tool is exactly
why. A redundant `Write(...)` twin rule added alongside it was removed same day (inert +
startup-warning noise). The /s* promptless tail depends on this rule; see [[plugin-routing-priorities]].
