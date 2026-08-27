---
paths:
  - ".claude/**"
  - "**/CLAUDE.md"
  - "**/settings*.json"
---

# Agent Orchestration

## Available Agents

Located in `~/.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring (**opus-tier**) |
| architect | System design | Architectural decisions (**opus-tier**) |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| silent-failure-hunter | Swallowed errors, bad fallbacks | After error-handling changes |
| typescript-reviewer | Type safety, async correctness | TS/JS changes |
| build-error-resolver | Fix build errors | When build fails |

`~/.claude/agents/` also holds `verifier`, `debugger`, `debug-session-manager`,
`integration-checker`, `nyquist-auditor`, `performance-optimizer`, `refactor-cleaner`,
`codebase-mapper`, `security-auditor`, `fable-advisor`, and 8 display-named
engineering/design/testing agents whose frontmatter `name` contains spaces
(`UI Designer`, `Backend Architect`, `Evidence Collector`, …) and so differs from the
filename — legal, and they load fine. **26 total: 18 plain-named + 8 display-named.**

The marketing/SEO set — 6 `audit-*`, 6 `seo-*`, `Analytics Reporter`, `Content Creator`,
`Growth Hacker`, `Experiment Tracker` and the four social-platform agents (19 files) — was
archived 2026-08-27 to `~/claude-config-archive-20260827-0128/agents/`. Restore individually
if a task needs one; do not re-add the set.

⚠️ Five agents still reference `.planning/` in their prose (`debugger`, `debug-session-manager`,
`integration-checker`, `codebase-mapper`, `verifier`) — dead convention, nothing reads it.
Pass `tasks/` paths explicitly.

## Immediate Agent Usage

⚠️ **Check first that subagents are permitted this session.** Some sessions launch with
"do not call the Agent tool unless the user requested it" in effect (a launcher flag, not a
stored setting — it will not appear in `settings.json`). Where that applies it OVERRIDES this
section: do the work inline and offer delegation instead of performing it. The list below is
what to reach for **once delegation is on the table**, not a licence to spawn unasked.

No further prompting needed when subagents are permitted:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **code-reviewer** agent
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent

## Parallel Task Execution

When you are already spawning agents, run independent ones in parallel rather than
in sequence. This governs HOW to spawn, never WHETHER to — see the warning above:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth module
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utilities

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
