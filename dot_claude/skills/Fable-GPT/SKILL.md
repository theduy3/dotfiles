---
name: Fable-GPT
description: Use when handling any coding task involving implementation, debugging, test fixing, refactoring, or multi-file edits — before writing code yourself, to decide whether Fable orchestrates or Codex executes.
---

# Fable-GPT — Orchestrator/Executor Split

## Overview

Fable 5 (this session) is the orchestrator; Codex is the executor. Fable owns judgment, Codex owns heavy keystrokes.

**Core principle: plan and verify locally; delegate heavy implementation.**

## Role Split

| Work | Owner |
|---|---|
| Planning, task decomposition | Fable (you) |
| Repo understanding, architecture decisions | Fable |
| Heavy implementation, multi-file edits | Codex via `/codex:rescue` |
| Debugging, test fixing, refactoring | Codex via `/codex:rescue` |
| Final review, accept/reject | Fable |

## Delegation Protocol

1. **Decompose first.** One focused, specific task per Codex dispatch: file paths, acceptance criteria, constraints. No open-ended briefs.
2. **Dispatch:**

   ```
   /codex:rescue --model gpt-5.5-codex --effort xhigh <focused task brief>
   ```

   GPT-5.5 at xhigh effort is the standing model preference (user-directed — overrides the plugin's leave-unset default). If that model is unavailable, use the CLI default and tell the user.
3. **Inspect before accepting.** Codex output is a proposal, not a result.

## Verification — mandatory after every Codex run

- Read the actual diff (`git diff` / changed files), not just Codex's summary
- Run the tests/build gates the change touches
- Check each acceptance criterion from the brief explicitly
- On any failure: reject, re-dispatch with a tighter brief (`--resume` to continue the thread)

## Red Flags — STOP

- About to hand-write a multi-file change yourself → delegate
- About to report "done" on Codex's word without reading the diff → inspect first
- Brief says "fix the app" / "clean this up" → not decomposed enough
- "Output looks right" without running gates → run them

## When NOT to Use

- Trivial single-file edits — faster inline
- Pure planning/analysis/questions — no executor needed
- Codex CLI missing or unauthenticated — run `/codex:setup`, fall back to normal workflow, tell the user
