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

**Roster verified 2026-08-04** — every name above resolves. Provenance: harvested from the
disabled `ecc` plugin's cache (`~/.claude/plugins/cache/ecc/ecc/2.0.0-rc.1/agents/`); a fuller set
including the GSD runtime variants is archived at `~/.claude/agents-archive/runtime-sources/`.
Removed as unavailable: `e2e-runner` (salonx runs Playwright via CI, not an agent),
`refactor-cleaner`, `doc-updater` — restorable from either source if wanted.

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
