---
name: s1-plan
description: S1 of the /s* pipeline — turn an approved tasks/spec-<topic>.md into a sequenced, dependency-ordered tasks/todo-<topic>.md, adversarially checked and grilled for ordering bugs. Use after /s0-spec, or when an approved spec needs breaking into tasks. Interactive (run on Opus 5; Fable 5 accepted when already active; warns otherwise). Stops at user approval; writes no source, enters no worktree. On approval flips status: plan-approved — the Seam /s-auto consumes.
---

# `/s1-plan` — sequencing, hostile-reviewed

Reads `tasks/spec-<topic>.md`. Produces `tasks/todo-<topic>.md` carrying the
`status:` metadata block. Writes no source code. Leaves the artifact and stops —
`/s-auto` is the consumer, invoked by the operator after approval, never by this skill.

**Model check (first thing):** run this stage on **Opus 5** — the default since 2026-07-24
(ADR 0006). **Fable 5 is accepted but never requested:** if the session is already on Fable,
proceed silently; never suggest switching *to* it. On Opus 5 or Fable 5 → no warning. On any
other model, warn once ("S1 runs on Opus 5 (Fable 5 accepted if already active); you're on
<model>. Continue, or `/model opus`") and proceed with whatever the user chooses. Warn, don't
block. For a single hard sequencing call, `fable-advisor` is the escape hatch — one subagent,
not a whole session.

## Where this runs

Same directory as `/s0-spec`, reading the spec it left there. No worktree —
`EnterWorktree` belongs to `/s-auto`, after approval, never here.

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

The metadata block is a **contract with the consumers**, not decoration. `/s-auto` and
`~/.claude/hooks/inject-vault-context.sh` read these exact keys to pick up and resume a
`plan-approved` task after a context clear. Use exactly the keys documented below and omit
none; invent no others.

```markdown
---
status: draft
worktree: <kebab-task-name>
scope: small | medium | large
created-at: YYYY-MM-DD
spec: tasks/spec-<topic>.md
artifact: <url>           # omit until the first publish in Step 6
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
| `status` | `/s-auto`, `inject-vault-context.sh` | `draft` → `plan-approved` → `implementing` |
| `worktree` | `/s-auto` | name passed to `EnterWorktree` |
| `scope` | `/s-auto` | selects S2 implementation *style only*, never the model |
| `created-at` | informational timestamp | no live reader |
| `spec` | `/s-auto` | back-reference to requirements |
| `artifact` | `/s1-plan`, `/s-auto` | stable Artifact URL for this plan — reused across sessions so the link never changes |

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

### The dimensional pass — required before Step 4 is done

The seven checks above audit the plan on its **reference** axis: is each claim true, does
each goal have a task. They will not catch a plan whose claims are all true and whose
arithmetic is still wrong, because two operands of one comparison measure different things.
That defect ships silently — every test passes, because the tests inherit the plan's
assumption.

Produce two tables **in the plan document**. They are deliverables, not scratch work.

**Table A — one row per comparison OPERATOR.** Not per rendered fraction. Every `<`, `>=`,
`===`, every filter predicate, every "N of M" the plan writes:

| Comparison | Left operand — what EVENT does it measure? | Right operand — what EVENT? | Same thing? |

The event column is the whole point. *"Both are ISO instants"* is not an answer — that is
the type, and matching types is precisely how these defects pass review. Write what happened
in the world: *"when the run record was first written"* versus *"when the code that writes
this edge first existed"*. Stated that way a mismatch is unmissable; stated as types it is
invisible.

A comparison that **filters** rather than divides has no numerator and no denominator, so a
ratio-shaped table cannot hold a row for it — and those are the rows most worth writing. If
your table's columns are Numerator / Denominator, it is the wrong table.

**Table B — every field of an unvalidated payload the plan newly READS**, marked validated
or not, and at which boundary. Promoting a field from inert payload to map key, comparator,
or the receiver of a method call makes it load-bearing. Validation is a property of the
payload, not of the one field that happened to motivate the guard.

Two executable checks, pasted into the plan **with their output**:

- **Output strings** — for every message this plan rewords, `git grep -F '<old literal>'`
  across the whole tree **including `.test.*`**. A reworded string is not a signature, so no
  symbol-name grep will ever find its consumers.
- **Constants citing a source** — any constant whose comment cites a commit, file, or
  release is pasted from a command that reads it (`git show -s --format=%cI <sha>`), never
  from memory and never truncated to a friendlier precision.

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

**Facts you look up; decisions you ask.** Ordering questions look answerable from the
codebase, and the dependency facts are — but which of two valid orders to ship is the
user's call. Put each such decision to them and **wait for the answer** before moving on.

Reorder. Split. Merge. Then re-grill the parts you changed.

## Step 6 — Stop, and hand off

**Publish the plan as the review surface** — call `Artifact` on `tasks/todo-<topic>.md`
itself. The markdown is published directly; no companion HTML page exists to drift from it.

- `favicon: "🗂️"`, and a one-line `description` naming the plan.
- **`url:`** — set it from the `artifact:` metadata key whenever that key holds a URL.
  Omitting it mints a *new* URL in any session that did not itself publish the file, and S1
  routinely runs in a different session from `/s0-spec` and `/s-auto`. Passing the stored URL
  is what keeps one link valid for the whole life of the task.
- On the first publish, write the returned URL back into the `artifact:` key.
- Re-publish after every grill round that edits the plan. A page one round behind is worse
  than no page — the user approves what they read, and they read the page.

Publish **before** presenting, so the user approves what they actually read.

Then present the plan, with its URL. On approval, flip the metadata:

```
status: plan-approved
```

Re-publish once after the flip, so the page shows the approved state rather than `draft`.

Then **stop**, and tell the user: `/s-auto` picks it up from here (autonomous S2→S5,
auto-merge on green; halts ping via notification).

## The handoff Seam

`status: plan-approved` in `tasks/todo-<topic>.md` is the only coupling between planning
and implementation. It is a **file state**, not a call. `/s1-plan` never invokes `/s-auto`.

Operationally: `status: implementing` signals a live consumer already holds the plan.
If you find a plan at `implementing` and you did not put it there, another session owns
it. Do not pick it up.
