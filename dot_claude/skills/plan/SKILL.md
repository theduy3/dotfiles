---
name: plan
description: Turn an approved spec into a sequenced, dependency-ordered task list at tasks/todo-<topic>.md, stress-tested for ordering bugs. Use after /spec, or when a spec already exists and needs breaking into tasks. Stops at user approval; writes no source and enters no worktree.
---

# `/plan` — sequencing, hostile-reviewed

Reads `tasks/spec-<topic>.md`. Produces `tasks/todo-<topic>.md` carrying the
`status: plan-approved` metadata block. Writes no source code.

**This skill does not invoke `/tdd-gates`.** It leaves an artifact and stops. That is
the entire reason it is a leaf library and not a sixth workflow loop competing
with GSD: exactly one consumer picks up the plan, and *which* consumer is the
operator's choice, made after approval.

## Where this runs

Same directory as `/spec`, reading the spec it left there. No worktree —
`EnterWorktree` belongs to `/tdd-gates` and happens after approval, never here.

## Steps

### 1. Read the spec

If no `tasks/spec-<topic>.md` exists, stop and run `/spec` first. Do not plan
against a spec you invented in-context — the artifact is the contract.

Reject a spec still marked `Status: draft — awaiting user review`. Unapproved
requirements produce a plan nobody agreed to.

### 2. Break it down — `superpowers:writing-plans`

Invoke it. Task granularity is the whole game:

- Each task is **independently verifiable** — it has its own RED test.
- Each task names its **dependencies by task number**, not by vibes.
- A task that cannot fail a test is not a task; it is a note.

### 3. Write `tasks/todo-<topic>.md`

The metadata block is a **contract with the consumers**, not decoration.
`/tdd-gates` and `~/.claude/hooks/inject-vault-context.sh` read these exact keys
to pick up and resume a `plan-approved` task after a context clear. Invent no new
keys; omit none.

```markdown
---
status: draft
worktree: <kebab-task-name>
scope: small | medium | large
created-at: YYYY-MM-DD
spec: tasks/spec-<topic>.md
---

# Plan: <title>

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
| `status` | `/tdd-gates`, `inject-vault-context.sh` | `draft` → `plan-approved` → `implementing` |
| `worktree` | `/tdd-gates` | name passed to `EnterWorktree` |
| `scope` | this skill | selects implementation style *only* |
| `created-at` | *no live reader* — the >14-day staleness-replan gate retired with `session-resume.md` (deleted 2026-07-17); kept as an informational timestamp |

`scope` never routes work back to the main checkout. It selects style:
`small` → single-context TDD. `medium`/`large` → `superpowers:subagent-driven-development`.

### 4. Grill the sequencing — `grilling`

**Skip this step when `scope: small`.** A single-file change has no dependency
graph worth attacking.

Otherwise invoke `grilling` against the plan. Its target here is **ordering**,
not requirements — requirements were grilled in `/spec`, and re-litigating them
here means the spec was approved too early.

- Which task consumes an artifact a later task creates?
- Which task's RED test cannot go red until a migration from another task lands?
- Which two tasks touch the same file and will conflict?
- Which task is actually three tasks?
- Which "independent" tasks share mutable state?

Reorder. Split. Merge. Then re-grill the parts you changed.

### 5. Stop, and hand off

Present the plan. On approval, flip the metadata:

```
status: plan-approved
```

Then **stop**, and tell the user which consumers can now pick it up:

| Consumer | When |
|---|---|
| `/tdd-gates` | solo, current session — plus the repo's `tdd-<project>` skill if it has one |
| `gsd-execute-phase` | GSD owns this task's loop |
| `superpowers:subagent-driven-development` | `scope: medium` \| `large` |

## The handoff seam

`status: plan-approved` in `tasks/todo-<topic>.md` is the only coupling between
planning and implementation. It is a **file state**, not a call.

This matters operationally: `status: implementing` already signals that a live
consumer holds the plan. If you find a plan at `implementing` and you did not
put it there, another session or a GSD phase owns it. Do not pick it up.
