# Workflow Model Routing

## Command-to-Model Map

| Command | Target Model | How to Launch |
|---------|-------------|---------------|
| /s0-brainstorm | Opus | `claude --model opus` (or default session) |
| /s1-plan | Opus | Same Opus session (scope detection internal: small/medium/large) |
| /ship | Sonnet | `claude --model sonnet` then `/ship` |
| /quick-ship | Sonnet | `claude --model sonnet` then `/quick-ship` |
| /deploy | Haiku | `claude --model haiku` then `/deploy` |

## Enforcement

Each command includes a **Model Guard** (Step 0) that:
- Detects the current session model via self-introspection
- Warns if running on a more expensive model than needed
- Blocks if running on a model too weak for the task (e.g., Haiku for /ship)
- Auto-proceeds in remote mode (`CLAUDE_REMOTE=1`)

The guard cannot switch models mid-session — it advises the user to start a new session with `claude --model <target>`.

## Subagent Routing

When spawning Agent() calls during workflow steps, use these models:

| Context | Agent Model |
|---------|------------|
| s1 → subagent-driven-development implementation tasks | sonnet |
| s3/ship → build-error-resolver | sonnet |
| Any Agent() in /deploy | haiku |

## Workflow Sequence

After implementation completes → suggest: "/ship or /quick-ship?"
After /ship or /quick-ship completes → suggest: "/deploy"

## Individual Commands (standalone use)

s3-verify-app, s6-commit-push-pr, s7-review-pr, s8-merge-pr, s9-cleanup remain available
for standalone use. They run at the current session model.
