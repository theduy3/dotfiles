Create a scope-aware implementation plan from the /s0-brainstorm spec:

Parse task name from: `$ARGUMENTS`
- If provided → use as task name, derive kebab slug
- If empty → scan tasks/spec-*.md, ask user to pick

## Step 1 — Load Spec
Load tasks/spec-<task-name>.md if it exists. If none found, proceed with task description only.

## Step 2 — Scope Detection
Analyze the spec or task description and classify:

| Scope | Signals |
|-------|---------|
| **small** | 1-3 files, no design decisions, clear implementation path |
| **medium** | 4-10 files, some design choices, may introduce new patterns |
| **large** | 10+ files, architectural decisions, cross-cutting concerns |

If repo is indexed (`gitnexus status`): run `query` + `impact` MCP tools to gauge blast radius. Factor into classification.
User can override: "this is small" or "treat this as large".

## Step 3 — Write Plan
Enter plan mode. Invoke `superpowers:writing-plans` with spec as context.

Write plan to `tasks/todo-<task-name>.md`:

```
<!-- s1 metadata
task-name: <name>
scope: small|medium|large
status: planning
repo: <absolute-repo-root>
created-at: <today's date, YYYY-MM-DD>
-->

## Implementation Plan

- [ ] Step 1: ...
- [ ] Step 2: ...
```

Present plan for user approval.

## Step 4 — After Approval (ExitPlanMode)
1. Update metadata: `status: planning` → `status: plan-approved`
2. Safety check: verify `.gitignore` includes worktree directory pattern
3. Call `EnterWorktree` with task-name
4. Run baseline tests to confirm clean starting point

## Step 5 — Execute Skill Handoff

Branch on scope:

### scope: small
Implement directly with TDD discipline. No prompt (obvious path, fast feedback loop).

### scope: medium | large
**PROMPT user via `AskUserQuestion`:**

Question: `"Plan approved and baseline tests pass. Start implementation with subagent-driven-development?"`

Options:
- **Yes, start now** → invoke `superpowers:subagent-driven-development` (model: opus)
- **Yes, but different skill** → follow-up `AskUserQuestion` with options:
  - `superpowers:test-driven-development` (single-agent TDD loop)
  - `everything-claude-code:prp-implement` (PRP rigorous execution)
  - `claude-mem:do` (phased plan executor)
- **Pause — I'll run execute later** → stay in worktree, status already `plan-approved`, exit. Next session auto-resumes per `~/.claude/rules/common/session-resume.md`.

For `large` scope: before dispatching subagents, confirm plan contains granular self-contained tasks (each task = one subagent, independent, testable). If not, return to Step 3 and refine.

After implementation: stay in worktree. Run `/auto-ship` or `/ship-agents` when ready to ship.
