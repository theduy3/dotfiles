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

**Roster verified 2026-08-07.** `~/.claude/agents/` now holds **55** agents — the archive was
restored 2026-08-07, then all 34 `gsd-*` agents were deleted with GSD the same day.
Beyond the eight above, these also resolve: `verifier`, `debugger`, `integration-checker`,
`nyquist-auditor`, `performance-optimizer`, `refactor-cleaner`, `codebase-mapper`,
`security-auditor`, 6 `audit-*`, 6 `seo-*`, and 15 display-named marketing/engineering/testing
agents whose frontmatter `name` contains spaces (`UI Designer`, `Backend Architect`, …) and so
differs from the filename — legal, and they load fine.

⚠️ Those 8 verify/build/security agents came from the GSD runtime, so their prose still references
`.planning/` even though nothing reads it now — pass `tasks/` paths explicitly.
⚠️ **No `gsd-*` agent resolves any more.** ECC is enabled again, so `ecc:`-prefixed agents
(`ecc:code-reviewer`, `ecc:python-reviewer`, …) resolve too — prefer the unprefixed ones above.

The ten `s-*` agents in the same directory belong to the `/s-auto` pipeline and are **not**
general-purpose; do not call them directly.

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **code-reviewer** agent
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

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
