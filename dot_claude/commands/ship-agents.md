Agent-orchestrated shipping pipeline. Dispatches each step as an isolated subagent with model routing:

## Pre-flight
Capture context to pass between agents:
- BRANCH=$(git rev-parse --abbrev-ref HEAD)
- CHANGED=$(git diff --name-only origin/main...HEAD)
- BASE_SHA=$(git merge-base origin/main HEAD)
- HEAD_SHA=$(git rev-parse HEAD)

## Scope Detection
Read tasks/todo-*.md on the current branch. Extract `scope` from s1 metadata:
- `small`: skip Round 2A (s4-techdebt-simplify) — 1-3 file changes don't need simplification pass
- `medium` or `large`: run full pipeline
- If no plan file found: default to `medium`

## Round 1 — Verify (sonnet)
Dispatch Agent(model: sonnet):
  Prompt: Run s3-verify-app steps on branch $BRANCH.
  Return: READY TO SHIP or NEEDS FIXES with list.
  (sonnet, not haiku: s3-verify-app's goal-backward step launches the `verifier`
   sub-agent — a haiku runner cannot spawn sub-agents, so that check would silently skip.)

If NEEDS FIXES → stop. Report errors to user. Do not proceed to Round 2.

## Round 2 — Techdebt + Reflect (parallel)
**If scope=small**: skip Agent A, run Agent B only.
**If scope=medium|large**: dispatch both agents in a single message:

Agent A (model: sonnet):
  Prompt: Run s4-techdebt-simplify on changed files: $CHANGED.

Agent B (model: haiku):
  Prompt: Run s5-update-claude-md for branch $BRANCH. Session summary: [brief description of what was implemented].

Wait for all dispatched agents to complete before proceeding.

## Round 3 — Commit & PR (sonnet)
Dispatch Agent(model: sonnet):
  Prompt: Run s6-commit-push-pr on branch $BRANCH. Base SHA: $BASE_SHA, Head SHA: $HEAD_SHA. Changed files: $CHANGED.

Return the PR URL when done.
