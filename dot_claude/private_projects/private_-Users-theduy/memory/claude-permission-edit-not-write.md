---
name: claude-permission-edit-not-write
description: "Claude Code permission rules must use Edit(path) — Write(path) rules are silently ignored, so Write() denies protect nothing"
metadata: 
  node_type: memory
  type: project
  originSessionId: e51cffba-57b3-49a5-a91b-e2282578fba4
---

Claude Code's **file permission matcher only consults `Edit(path)` rules**. `Write(path)` rules parse fine but are never matched — `Edit(...)` is the canonical form and covers all file-editing tools (Write, Edit, NotebookEdit). Startup prints one warning per offending rule: `Write(X) is not matched by file permission checks — only Edit(path) rules are.`

**Why it matters:** the failure is silent and asymmetric. A dead `allow` rule only costs an extra prompt. A dead **`deny`** rule means the path was never protected. In `~/.claude/settings.json` the denies for `**/.env`, `**/.env.*`, `**/secrets/**`, `**/.ssh/**` were all written as `Write(...)` and were therefore **inert from the day they were added** — believed-protected, actually open. Fixed 2026-07-16 (dotfiles `ca51ef7`).

**How to apply:**
- Write any new file permission rule as `Edit(glob)`, never `Write(glob)`. Note `Read(...)` and `Bash(...)` rules are unaffected — those matchers work as written.
- Startup warnings naming a rule are the tell; treat them as security findings, not noise, when the rule is a `deny`.
- Flipping a dead deny to live is a **behavior change** — anything that was quietly writing to those paths starts hard-failing (deny beats allow, no prompt).
- settings.json is a chezmoi template — fix `~/.local/share/chezmoi/dot_claude/settings.json.tmpl` too or the hourly `chezmoi apply --force` reverts it. See [[claude-config-chezmoi-sync]].

**Confirmed live 2026-07-18** (/s* verify, user-observed): `Edit(/Users/theduy/tasks/.s-run/**)`
**allow** rule suppressed every prompt for Write-tool calls to that path during the whole
autonomous run — absolute-path glob form works, and Edit() covering the Write tool is exactly
why. A redundant `Write(...)` twin rule added alongside it was removed same day (inert +
startup-warning noise). The /s* promptless tail depends on this rule; see [[plugin-routing-priorities]].
