---
name: s2-implement
description: Manual S2 of the /s* pipeline — spawn s-implementer to execute an approved tasks/todo-<topic>.md test-first in its task worktree, then stop. Operator rerun/debug tool; no Seam ownership (status:plan-approved auto-pickup belongs to /s-auto), no auto-advance to S3. Use for a standalone implementation pass, or resuming a half-implemented task without the autonomous tail.
---

# `/s2-implement` — manual S2 (implement only)

One stage, then stop. You orchestrate: locate the plan, enter the worktree, spawn
`s-implementer` (model pinned in its frontmatter), record, report. You never
implement inline — spawning IS the model routing.

## Boundaries

- **Seam untouched.** `status: plan-approved` auto-pickup belongs to `/s-auto`.
  This command runs only when the operator explicitly invokes it.
- **No chaining.** The report ends the run. Suggest `/s3-gates` as the next step;
  never invoke it.
- **Run-State File** (`~/tasks/.s-run/<slug>.md`): if it exists, append an Evidence
  entry tagged `manual-s2` with the results. Never flip its `status:` — that field
  belongs to the `/s-auto` orchestrator.

## Steps

1. **Resolve the plan.** Argument = topic slug, or auto-detect: exactly one
   `tasks/todo-*.md` at `plan-approved` or `implementing`. Sanitize the slug:
   `^[a-z0-9][a-z0-9-]*$`, max 40 chars, no `..` or slashes.
   - `status: draft` → refuse: "plan not approved — run /s1-plan".
   - `status: implementing` with a Run-State File that is **not** `halted` →
     a live `/s-auto` run owns it. Refuse — don't race the orchestrator.
2. **Enter the worktree** named in the todo's metadata — exactly one Enter; no Exit
   at the end (operator continues here; each switch busts the prompt-cache prefix).
   If the branch exists but the worktree is gone, `git worktree add` it back.
3. If the todo is still `plan-approved`: flip to `implementing` in the worktree copy
   **and commit the flip immediately** (an uncommitted flip leaves the tree dirty,
   which S3 correctly reports as a finding).
4. **Spawn `s-implementer`** with the todo path, spec path, and worktree path.
   Before the spawn, print the stage banner with the live pin
   (`grep '^model:' ~/.claude/agents/s-implementer.md`):
   `▶ S2 · s-implementer · model: <pin>`. It
   verifies isolation, proves the baseline green, implements test-first per task,
   commits per green slice.
5. Record its per-task evidence. On its halt (`baseline-red` / `task-blocked` /
   `spec-conflict`) report the reason and evidence verbatim — no PushNotification;
   the operator is present.
6. **Report and stop:** tasks done, commits, remaining tasks, halts. Next step is
   the operator's call (`/s3-gates`).

## Never

- Implement, fix, or test inline in this session.
- Weaken a linter config, loosen strictness, or quarantine a test.
- Advance to S3, or touch a second task (single-track).
- Modify any upstream Source skill/agent.
