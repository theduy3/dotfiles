---
name: graph-engineer
description: Run the plan → work → parallel-review → synthesise → pass/fail loop as a background workflow, with lesson recall at the front and a plan reviewer at the back. Use for work where being wrong is expensive — design, audits, refactors, anything worth adversarial review. Invoking this skill IS the workflow opt-in. Expensive: ~13-19 agents per run.
---

# `/graph-engineer` — the adversarial work loop

One command from a task to a reviewed result. Wraps
`~/tasks/workflows/graph-engineer.js`, which runs:

```
recall → plan → [ work → review×N → synthesise → pass? ] → plan review → deliver
                        ↑______ feedback, bounded ______|
```

**Invoking this skill is the explicit workflow opt-in.** Do not ask again for permission.

**The name is narrower than the tool.** The loop is general-purpose — it is not limited to
knowledge-graph work. It is named for where it was built, not for what it can take.

## What it is NOT for

- Routine edits, single-file changes, anything mechanical. A run costs roughly
  `rounds × (1 + lenses + 1) + 4` agent calls; the one real run was **19 agents, 1.87M
  subagent tokens, 55 minutes**. That price only makes sense when being wrong is expensive.
- Work inside the `/s-auto` Seam. A `tasks/todo-*.md` at `status: plan-approved` belongs to
  `/s-auto`, which already runs its own plan → implement → gate → panel → ship loop. Never
  race it.

## Steps

1. **Take the task from the invocation** (`/graph-engineer <task>`). If the argument is
   empty, ask for the task — it is the one required input, and the script throws without it.

2. **Infer `repo` and `areas`, then say what you inferred.** `repo` is the basename of the
   repo the work touches (`salonx`, `ongles-website`, `SS-website`); use `harness` for
   chezmoi / git / skills / cross-cutting work. Area names come from
   `~/theduyvault/Notes/Claude-Context/lessons/AREAS.yaml` — read it, never guess. A wrong
   `--repo` silently narrows recall to globals; recall warns, but the warning is inside a
   subagent where nobody reads it.

3. **Sharpen the lenses.** This is the knob that matters. The defaults —
   `correctness`, `failure-modes`, `simplicity` — are generic. On the first real run BOTH
   blocking findings came from `failure-modes`, and no finding was raised by two lenses, so
   there was no cross-confirmation to weight. For a specific job, pass lenses matching the
   failure modes *that* job actually has: schema drift, auth boundaries, migration
   ordering, concurrency. Three sharp lenses beat five vague ones; redundant lenses just
   re-find one class.

4. **Invoke the workflow.** `args` must be a real JSON object, never a JSON-encoded string
   — passing a string made the first run silently ignore `maxRounds` and fall back to every
   default:

   ```
   Workflow({
     scriptPath: "/Users/theduy/tasks/workflows/graph-engineer.js",
     args: { task, repo, areas, maxRounds, lenses, presentAs }
   })
   ```

   It runs in the background and notifies on completion.

5. **On completion, report honestly.** Read `.result` from the output file — the payload is
   nested under `result`, not top-level. State `passed` and `rounds_used` plainly. **A run
   that hits the cap without passing is a normal and useful outcome, not a failure to hide**
   — the blocking findings are the deliverable. Never present a capped run as a success.

6. **Surface the plan review separately.** It answers what no other stage can: which
   rejections were FORESEEABLE from the plan, and which were only knowable by attempting.
   The second list matters as much — without it every rejection reads as a planning failure
   and someone hardens a plan that was already correct.

7. **Lesson candidates are proposals.** If the plan review proposes one, show it and let the
   human decide. Check the store first — `bun ~/tasks/graph-engineering/tools/src/promote.ts`
   and the existing cluster — because the obvious candidate is usually a duplicate. A store
   that accepts every observation becomes a pile.

## Never

- Apply the workflow's output to files on its behalf. It returns text; a human decides what
  lands. The script forbids the agents from writing, and that boundary is the point.
- Claim a pass the verdict did not give.
- Auto-author a lesson node.
