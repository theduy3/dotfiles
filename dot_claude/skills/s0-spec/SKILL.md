---
name: s0-spec
description: S0 of the /s* pipeline — interview, draft tasks/spec-<topic>.md, grill the requirements, self-review, stop at user approval. Use when starting a feature, refactor, or bugfix whose shape is not yet obvious. Interactive (run on Fable; warns otherwise). Writes no source code; hands off to /s1-plan. Never advances on its own.
---

# `/s0-spec` — specification, hostile-reviewed

Produces exactly one artifact: `tasks/spec-<topic>.md`. Writes no source code.
Hands off to `/s1-plan`. Never invokes it, never enters a worktree, never commits.

**Model check (first thing):** this stage is tuned for Fable. If the session model is not
Fable, say so once — "S0 runs best on Fable; you're on <model>. Continue or `/model fable`" —
then proceed with whatever the user chooses. Warn, don't block.

## Where this runs

Wherever you are. The spec lands **relative to the current directory** — in the repo you're
working on, or in `~/tasks/` when the subject is your own tooling. No worktree: repos that
guard their main checkout exempt `tasks/`, the only surface this skill touches.
(`EnterWorktree` belongs to `/s-auto`, after plan approval.)

## Step 1 — Interview

Do not improvise the interview; run it by these rules. It exists to stop you from speccing
the feature you assumed instead of the one that was asked for.

- Explore project context first — files, docs, recent commits. Ground every question in
  what the code already does.
- **Decomposition check before detail questions:** if the request spans multiple independent
  subsystems, flag it and split into sub-projects first — each gets its own spec→plan→build
  cycle. Don't spend questions refining a project that needs decomposition.
- Ask **one question at a time**. Multiple choice preferred; open-ended fine. If a question
  can be answered by exploring the codebase, explore instead of asking.
- Focus: purpose, constraints, observable success condition.
- **Blind-spot pass** before proposing anything: list 3-7 unknowns the user is NOT asking
  about but should be — unstated assumptions, missing constraints (scale, auth, error paths,
  migration, concurrency), unmentioned integration points. Rank by cost-if-discovered-late
  (architecture-changing > interface-changing > cosmetic). Ask about the
  architecture-changing ones; note the rest.
- Propose **2-3 approaches** with trade-offs; lead with your recommendation and why.
- YAGNI ruthlessly — strip speculative features from every approach.

Come out able to state, in one sentence each: the problem, the user, the observable success
condition.

## Step 2 — Draft `tasks/spec-<topic>.md`

`<topic>` is kebab-case, derived from the problem, not the solution
(`spec-email-capture-checkout.md`, not `spec-add-modal.md`).

Required sections. Omit none — an omitted section is a decision deferred to whoever
implements, which is how specs become fiction.

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
Which oracle can actually fail for each change (unit / integration / E2E / manual —
name the one that would catch a regression, not the one that's easiest to write).

## Success criteria
Numbered, each independently checkable, each a command or an observation.

## Risks
Table: risk → mitigation. A risk with no mitigation is an open question; go
resolve it before claiming the spec is done.
```

**Scope**, chosen honestly — `/s1-plan` and `/s-auto` both read it:

| Scope | Means |
|---|---|
| `small` | one file, no new dependency graph, no migration |
| `medium` | several files, one subsystem, possibly a migration |
| `large` | crosses subsystems, or migration + UI + RPC together |

## Step 3 — Grill the requirements

Interview the user relentlessly about the drafted spec until shared understanding. Target is
**requirements**, not sequencing (sequencing is `/s1-plan`'s grill):

- What happens at zero? At one? At ten thousand?
- Which role sees this, and which role must not?
- What does the existing code already do that this contradicts?
- Which stated non-goal is actually a hidden requirement?

Rules: one question per message — several at once is bewildering. Provide your recommended
answer with each question. If a question can be answered by exploring the codebase, explore
instead of asking. Walk each branch of the design tree, resolving dependencies between
decisions one by one.

Fold every answer back into the spec. An unanswered grill question stays in **Risks** as an
open question — never silently dropped.

## Step 4 — Self-review

Before showing the user, read your own spec hunting for:

| Smell | What it means |
|---|---|
| `TBD`, `TODO`, `<placeholder>` | not a spec yet |
| Two sections contradicting | you never decided |
| A Goal with no matching Success criterion | unfalsifiable |
| A file listed with no reason | you're guessing |
| A Design that restates the Goal | there is no design |
| A requirement readable two ways | pick one, make it explicit |

Fix inline, then move on — no re-review loop.

## Step 5 — Stop, and state what is unverified

Present the spec. **Separate what you verified from what you assumed** — read a file, ran a
command, checked a schema = verified. Everything else is an assumption, and you say so, by
name. Close with the unknowns ledger: what the interview resolved, what was consciously
deferred.

Then stop. The user approves, or sends you back to Step 3.

`/s0-spec` never advances to `/s1-plan` on its own.

## Consumed by

`/s1-plan`, which reads `tasks/spec-<topic>.md` and produces `tasks/todo-<topic>.md`.
