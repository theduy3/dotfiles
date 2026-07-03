# Commands & Hooks Inventory

## Custom Slash Commands (21 total)

### Workflow Commands (s-series + shipping pipelines)
| Command | Purpose |
|---------|---------|
| /s0-brainstorm | Brainstorm + design feature, output `tasks/spec-<task-name>.md`, hand off to /s1-plan |
| /s1-plan | Plan in main repo then create worktree after approval (task-specific plan file bridges context clears via metadata block) |
| /s2-preview | Preview app locally |
| /s3-verify-app | Verify app on current branch |
| /s4-techdebt-simplify | Tech debt scan + code simplification |
| /s5-update-claude-md | Review session, update CLAUDE.md |
| /s6-commit-push-pr | Commit, push, create PR |
| /s9-cleanup | Clean up after PR merge |
| /full-ship | End-to-end worktree pipeline — brainstorm, plan, implement, ship, deploy |
| /auto-ship | Full pipeline after implementation: ship then deploy, agent-driven |
| /ship-agents | Agent-orchestrated shipping; each step an isolated subagent with model routing |
| /deploy-agents | Agent-orchestrated batch deploy; merges open PRs in parallel, checks file overlaps |
| /emergency-pr-revert | Auto-detect last merged PR, revert, push, redeploy |

### Analysis Commands
| Command | Purpose |
|---------|---------|
| /sync-context | Aggregate recent project activity (git, GitHub, MCP) into session summary |
| /security-scan | Scan app source for vulnerabilities (secrets, SQLi, XSS, injection) |
| /dep-audit | Audit deps (vulnerabilities, outdated, unused) — read-only |
| /db-check | Supabase database health checks |
| /analytics-agent | dbt model creation/review/testing workflows |
| /state-diagram | Generate Mermaid stateDiagram-v2 from state-management code |

### Setup & Utility Commands
| Command | Purpose |
|---------|---------|
| /init-tests | Bootstrap vitest + testing-library (Vite + React + TS) |
| /vault-save | Save session summary + ADRs to Obsidian vault |

Analysis/setup commands use `context: fork` frontmatter to run in subagent context; s-series workflow commands run inline.

## Hooks Layer (multi-source — DOMINATED by ECC plugin, NOT ~/.claude/hooks/)

> ⚠️ The active hook layer lives in **3 places**. The `~/.claude/hooks/*.sh` scripts are a
> LEGACY layer, superseded and unwired (0 config refs). What actually fires = ECC plugin.

### Source 1 — `settings.json` (user-wired) — 2 hooks
| Event | Matcher | Command | Purpose |
|-------|---------|---------|---------|
| PostToolUse | Edit\|Write\|Bash | `code-review-graph update --skip-flows` (async, t=30) | Incremental knowledge-graph update |
| SessionStart | * | `code-review-graph status` (t=10) | Report graph status on session start |

### Source 2 — ECC plugin `plugins/marketplaces/ecc/hooks/hooks.json` (THE active layer, 28 hooks)
Each hook is a `node -e` bootstrap that resolves the ECC plugin root → `scripts/hooks/<x>.js` via `run-with-flags.js` (honors `ECC_HOOK_PROFILE` + `ECC_DISABLED_HOOKS`).

**PreToolUse (8):**
| id | Matcher | Purpose |
|----|---------|---------|
| pre:bash:dispatcher | Bash | Quality/tmux/push + **GateGuard** preflight |
| pre:write:doc-file-warning | Write | Warn on non-standard doc files |
| pre:edit-write:suggest-compact | Edit\|Write | Suggest manual compaction at intervals |
| pre:observe:continuous-learning | * (async) | Capture tool-use observations |
| pre:governance-capture | Bash\|Write\|Edit\|MultiEdit | Secrets/policy capture (opt-in `ECC_GOVERNANCE_CAPTURE=1`) |
| pre:config-protection | Write\|Edit\|MultiEdit | **Block** edits to linter/formatter configs |
| pre:mcp-health-check | * | Block unhealthy MCP calls |
| pre:edit-write:gateguard-fact-force | Edit\|Write\|MultiEdit | **Fact-forcing gate** — block 1st edit/file, demand facts (off: `ECC_GATEGUARD=off`) |

**PostToolUse (10):** post:bash:dispatcher (Bash, async — log/PR/build notify) · post:quality-gate (async) · post:edit:design-quality-check (generic-UI drift) · post:edit:accumulator (batch format paths) · post:edit:console-warn · post:governance-capture (opt-in) · post:session-activity-tracker · post:observe:continuous-learning (async) · post:ecc-metrics-bridge (statusline) · **post:ecc-context-monitor** (the cost / loop / scope-creep warnings)

**Other events:** PreCompact → pre:compact · SessionStart → session:start (load context + detect pkg mgr) · PostToolUseFailure → post:mcp-health-check · **Stop (6)**: stop:format-typecheck, stop:check-console-log, stop:session-end, stop:evaluate-session, stop:cost-tracker, stop:desktop-notify · SessionEnd → session:end:marker

### Source 3 — other plugins (NON-exhaustive — ~10 plugin manifests on disk under `plugins/cache/*/*/hooks/hooks.json`)
- **caveman** — SessionStart: injects caveman-mode persona (`/caveman lite|full|ultra`)
- **claude-mem** (thedotmack 13.4.0) — SessionStart: injects `$CMEM` memory digest; Pre/Post: observation capture
- **explanatory- / learning-output-style** (claude-plugins-official) — inject the output-style reminders
- Also present: superpowers, hookify, ralph-loop, security-guidance, last30days. To enumerate active hooks: `for f in ~/.claude/plugins/cache/*/*/*/hooks/hooks.json; do echo "$f"; done` (ignore `.cursor/` + `.codex/` — those are Cursor/Codex variants, not Claude Code)

### Legacy — `~/.claude/hooks/*.sh` (12 scripts, 0 config refs = UNWIRED)
auto-approve-exit-plan, auto-approve-write-edit, auto-format, bun-rtk-wrap, cleanup-caffeinate, inject-vault-context, permission-check, session-guard, tool-log, vault-autolog, worktree-env-copy, worktree-tab-rename.
The 4 once-documented (permission-check→pre:bash:dispatcher, auto-format→post:quality-gate, tool-log→post:bash:dispatcher, session-guard→stop:check-console-log) are superseded by ECC equivalents. worktree-env-copy/tab-rename are referenced in CLAUDE.md as EnterWorktree hooks but **no current wiring found** — treat as intent, verify before relying.

### Runtime gating & maintenance
- `ECC_HOOK_PROFILE` (minimal/standard/strict) · `ECC_DISABLED_HOOKS=pre:bash:gateguard-fact-force,...` · `ECC_GATEGUARD=off` · `ECC_GOVERNANCE_CAPTURE=1`
- ⚠️ **ECC plugin update RESETS `hooks.json`** → re-apply `~/.claude/ecc-hooks.stripped.json` (per salonx env memory: stripped 5 noisy `console.log` Bash echoers that scrambled multi-line output)
- Design philosophy (Boris #7/#13/#24): hooks = deterministic/mechanical; commands = judgment; all hooks exit 0 (never hard-block unexpectedly); blocking hooks stay <200ms, no network
