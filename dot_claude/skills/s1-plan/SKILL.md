---
name: s1-plan
description: S1 of the /s* pipeline — turn an approved tasks/spec-<topic>.md into a sequenced, dependency-ordered tasks/todo-<topic>.md, adversarially checked and grilled for ordering bugs. Use after /s0-spec, or when an approved spec needs breaking into tasks. Interactive (run on Fable; warns otherwise). Stops at user approval; writes no source, enters no worktree. On approval flips status: plan-approved — the Seam /s consumes.
---

# `/s1-plan` — sequencing, hostile-reviewed

Reads `tasks/spec-<topic>.md`. Produces `tasks/todo-<topic>.md` carrying the
`status:` metadata block. Writes no source code. Leaves the artifact and stops —
`/s` is the consumer, invoked by the operator after approval, never by this skill.

**Model check (first thing):** tuned for Fable. If the session model is not Fable, warn
once and proceed with whatever the user chooses. Warn, don't block.

## Where this runs

Same directory as `/s0-spec`, reading the spec it left there. No worktree —
`EnterWorktree` belongs to `/s`, after approval, never here.

## Step 1 — Read the spec

If no `tasks/spec-<topic>.md` exists, stop and run `/s0-spec` first. Do not plan against
a spec you invented in-context — the artifact is the contract.

Reject a spec still marked `Status: draft — awaiting user review`. Unapproved
requirements produce a plan nobody agreed to.

## Step 2 — Break it down

Write for an engineer with zero context for this codebase and questionable taste:
skilled, but ignorant of the toolset, the domain, and good test design. Document
everything they need. DRY. YAGNI. TDD.

**File structure first.** Before defining tasks, map which files will be created or
modified and what each is responsible for — this locks in decomposition. One clear
responsibility per file; follow the codebase's existing patterns; split by
responsibility, not technical layer.

**Task granularity is the whole game:**

- Each task is **independently verifiable** — it has its own RED test.
- Each task names its **dependencies by task number**, not by vibes.
- A task that cannot fail a test is not a task; it is a note.
- Exact file paths always. Complete code in every step — if a step changes code, show
  the code. Exact commands with expected output.

**No placeholders — these are plan failures, never write them:**

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without the actual test code)
- "Similar to Task N" (repeat the code — tasks may be read out of order)
- Steps that describe what to do without showing how
- References to types or functions not defined in any task

## Step 3 — Write `tasks/todo-<topic>.md`

The metadata block is a **contract with the consumers**, not decoration. `/s` and
`~/.claude/hooks/inject-vault-context.sh` read these exact keys to pick up and resume a
`plan-approved` task after a context clear. Invent no new keys; omit none.

```markdown
---
status: draft
worktree: <kebab-task-name>
scope: small | medium | large
created-at: YYYY-MM-DD
spec: tasks/spec-<topic>.md
---

# Plan: <title>

**Goal:** one sentence — what this builds.

## Setup
Worktree name, base branch, baseline command to prove green before starting.

## Tasks

### 1. <verb-first title>
**Depends on:** none
**RED:** the test that must fail first, named, with its file path
**GREEN:** the minimal change that makes it pass
**Files:** paths

### 2. …
```

| Key | Read by | Meaning |
|---|---|---|
| `status` | `/s`, `inject-vault-context.sh` | `draft` → `plan-approved` → `implementing` |
| `worktree` | `/s` | name passed to `EnterWorktree` |
| `scope` | `/s` | selects S2 implementation *style only*, never the model |
| `created-at` | informational timestamp | no live reader |
| `spec` | `/s` | back-reference to requirements |

`scope` style map (read by `s-implementer`): `small`/`medium` → single-context;
`large` → dispatch workers for independent tasks, synthesis stays with the implementer.

## Step 4 — Adversarial plan-check

Now attack your own plan. **Starting hypothesis: this plan will not deliver the spec.**
Plans describe intent; you verify they deliver. Credit nothing for effort or plausible
task names — read what each task actually says. Classify every finding
**BLOCKER** (spec goal not achieved unless fixed) or **WARNING** (degraded, can proceed);
an unclassified finding is not a finding.

Goal-backward, from the spec:

1. **Coverage** — walk every numbered Goal and Success criterion in the spec: point to
   the task(s) that deliver it. A goal with zero tasks, or several goals sharing one
   vague task, is a BLOCKER.
2. **Task completeness** — every task has RED + GREEN + Files. A well-named task can
   still be empty; read the fields, not the title.
3. **Wiring** — artifacts connected, not just created. Component with no import,
   endpoint no caller ever fetches, form with a stub submit handler: creation without
   wiring is a WARNING, load-bearing wiring missing is a BLOCKER.
4. **Scope-reduction scan** — search the plan for "v1", "simplified", "for now",
   "hardcoded", "basic version", "future enhancement", "stub", "not wired to", and
   time-estimate justifications. Cross-reference the spec: if a task delivers a reduced
   version of what the spec says, that is **always a BLOCKER** — deliver fully or send
   the user back to `/s0-spec` to split the spec. Never invent versioning the spec
   doesn't contain.
5. **Verify-command sanity** — a RED command whose failure is swallowed
   (`cmd 2>/dev/null || echo "0"` feeding a comparison, `|| true` in an assertion) can
   never go red: BLOCKER. Hard-coded counts with no measured provenance: WARNING.
6. **Consistency** — types, signatures, and names used in later tasks match what earlier
   tasks define (`clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug).
   Numeric claims: measure live with a read-only command rather than trusting either
   the spec or your memory.
7. **Project rules** — the plan violates nothing in the repo's `CLAUDE.md`
   (conventions, forbidden patterns, required steps).

Fix BLOCKERs now; fix or explicitly accept WARNINGs. Then re-check only what you changed.

## Step 5 — Grill the sequencing

**Skip this step when `scope: small`.** A single-file change has no dependency graph
worth attacking.

Otherwise interview the user about **ordering**, not requirements — requirements were
grilled in `/s0-spec`, and re-litigating them here means the spec was approved too
early. One question per message, your recommended answer attached; if the codebase can
answer it, explore instead of asking:

- Which task consumes an artifact a later task creates?
- Which task's RED test cannot go red until a migration from another task lands?
- Which two tasks touch the same file and will conflict?
- Which task is actually three tasks?
- Which "independent" tasks share mutable state?

Reorder. Split. Merge. Then re-grill the parts you changed.

## Step 6 — Stop, and hand off

Present the plan. On approval, flip the metadata:

```
status: plan-approved
```

Then **stop**, and tell the user: `/s` picks it up from here (autonomous S2→S5,
auto-merge on green; halts ping via notification).

## The handoff Seam

`status: plan-approved` in `tasks/todo-<topic>.md` is the only coupling between planning
and implementation. It is a **file state**, not a call. `/s1-plan` never invokes `/s`.

Operationally: `status: implementing` signals a live consumer already holds the plan.
If you find a plan at `implementing` and you did not put it there, another session owns
it. Do not pick it up.
