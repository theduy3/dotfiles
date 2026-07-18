---
name: spec
description: Write a stress-tested specification before any code exists. Use when starting a feature, a refactor, or a bugfix whose shape is not yet obvious — anything where "what should this do?" is still open. Produces tasks/spec-<topic>.md. Stops at user approval; writes no source.
---

# `/spec` — specification, hostile-reviewed

Produces exactly one artifact: `tasks/spec-<topic>.md`. Writes no source code.
Hands off to `/plan`.

This is a **leaf workflow**, not a loop owner. It composes existing skills and
stops. It never invokes `/plan`, never enters a worktree, never commits.

## Where this runs

Wherever you are. `/spec` writes `tasks/spec-<topic>.md` **relative to the current
directory**, so it lands in the repo you are working on — or in `~/tasks/` when the
subject is your own tooling rather than a codebase.

No worktree. Repos that guard their main checkout against source writes exempt
`tasks/`, which is exactly the surface this skill touches. `EnterWorktree`
belongs to `/tdd-gates`, after approval.

## Steps

### 1. Interview — `superpowers:brainstorming`

Invoke it. Do not improvise an interview. It exists to stop you from writing a
spec for the feature you assumed rather than the one that was asked for.

Come out of it able to state, in one sentence each: the problem, the user, the
observable success condition.

### 2. Draft `tasks/spec-<topic>.md`

`<topic>` is kebab-case, derived from the problem, not the solution.
(`spec-email-capture-checkout.md`, not `spec-add-modal.md`.)

Required sections. Omit none — an omitted section is a decision deferred to
whoever implements, which is how specs become fiction.

```markdown
# Spec: <title>

**Created:** YYYY-MM-DD
**Status:** draft — awaiting user review
**Scope:** small | medium | large

## Problem
What is broken or missing, stated as consequence, not as absent feature.

## Goal
Numbered. Each one testable by inspection.

## Non-goals
What this deliberately does not do. Load-bearing — this is where scope creep dies.

## Design
The shape. Diagrams where a diagram carries what prose cannot.

## Files
Create / Modify / Delete tables, with a reason column. If you cannot name the
files, the design is not finished.

## Testing strategy
Which oracle can actually fail for each change. See the `/tdd-gates` test-type router.

## Success criteria
Numbered, each independently checkable, each a command or an observation.

## Risks
Table: risk → mitigation. A risk with no mitigation is an open question; go
resolve it before claiming the spec is done.
```

**Scope**, chosen honestly, because `/plan` reads it:

| Scope | Means |
|---|---|
| `small` | one file, no new dependency graph, no migration |
| `medium` | several files, one subsystem, possibly a migration |
| `large` | crosses subsystems, or migration + UI + RPC together |

### 3. Grill it — `grilling`

Invoke the `grilling` skill against the spec. Its target here is
**requirements**, not sequencing:

- What happens at zero? At one? At ten thousand?
- Which role sees this, and which role must not?
- What does the existing code already do that this contradicts?
- Which stated non-goal is actually a hidden requirement?

Fold every answer back into the spec. An unanswered grill question stays in
**Risks** as an open question — never silently dropped.

### 4. Self-review

Before showing the user, read your own spec hunting for:

| Smell | What it means |
|---|---|
| `TBD`, `TODO`, `<placeholder>` | not a spec yet |
| Two sections contradicting | you never decided |
| A Goal with no matching Success criterion | unfalsifiable |
| A file listed with no reason | you're guessing |
| A Design that restates the Goal | there is no design |

### 5. Stop, and state what is unverified

Present the spec. **Separate what you verified from what you assumed** — read a
file, ran a command, checked a schema = verified. Everything else is an
assumption, and you say so, by name.

Then stop. The user approves, or sends you back to step 3.

`/spec` never advances to `/plan` on its own.

## Consumed by

`/plan`, which reads `tasks/spec-<topic>.md` and produces
`tasks/todo-<topic>.md`.
