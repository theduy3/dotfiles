---
name: unknowns
description: Surface the unknowns in a task before (or after) implementation — blind spot pass, interview inversion, prototype triage, self-quiz. Use at the start of any non-trivial task, or when the user invokes /unknowns. Args: [blind|interview|proto|quiz] to run one step; no args runs the full pre-implementation sequence.
---

# Finding Your Unknowns

Work quality is bottlenecked by unknowns — gaps between the prompt (map) and the real problem (territory). This skill surfaces them early, when they cost 1x instead of 100x.

Reference: `~/theduyvault/Notes/Claude-Context/finding-unknowns-cheatsheet.md`

## Argument routing

- **no args** → run steps 1-3 in order (blind spot pass → interview → prototype triage), then recommend next tool (`/gsd-plan-phase`, `/spec`, or direct implementation).
- **`blind`** → step 1 only
- **`interview`** → step 2 only
- **`proto`** → step 3 only
- **`quiz`** → step 4 only (post-implementation)
- Anything else → treat as the task description; run full sequence against it.

If no task is evident from args or conversation, ask: "What task should I find unknowns for?"

## Step 1 — Blind spot pass (unknown unknowns)

Analyze the task and output:

1. **Unknowns the user is NOT asking about but should be.** Look for: unstated assumptions, missing constraints (scale, auth, error paths, migration, i18n, concurrency), integration points not mentioned, "obvious" defaults that have alternatives.
2. Rank each by **cost-if-discovered-late** (architecture-changing > interface-changing > cosmetic).
3. For each architecture-changing unknown, state what evidence would resolve it (a file to read, a question to answer, a spike to run).

Read relevant code first if in a repo — grounded blind spots beat generic checklists. Do NOT pad the list; 3-7 real unknowns beat 15 generic ones.

## Step 2 — Interview inversion (known unknowns)

Interview the user via AskUserQuestion:

- **One question at a time**, max 4-5 total.
- Prioritize strictly by: architecture-changing first, interface-changing second. Never ask cosmetic questions.
- Each question offers concrete options with tradeoffs, not open-ended "what do you want?"
- Stop when remaining questions are low-stakes — say so explicitly and list the low-stakes items as "decided during implementation, will note deviations".

## Step 3 — Prototype triage (unknown knowns)

Determine whether the task has a **taste component** (UI, API shape, output format, naming scheme, report layout — anything the user will judge by reacting rather than by spec).

- **Taste component present** → propose 2-3 throwaway sketches with deliberately contrasting approaches. Optimize for contrast, not polish. Let the user react before planning.
- **No taste component** (pure logic/fix/migration) → say so and skip; don't manufacture prototypes.

## Step 4 — Self-quiz (post-implementation, `quiz`)

Quiz the user on the just-completed implementation before merge:

- 5 questions testing real understanding: what the code does on the failure path, why key decisions were made, what breaks if X changes, where the riskiest line is.
- Ask via AskUserQuestion one at a time, then grade honestly — name what they got wrong, point at the file:line that proves it.
- If they fail 2+, recommend a walkthrough before merging.

## Handoff

After the pre-implementation sequence, close with a one-paragraph **unknowns ledger**: what was resolved, what was consciously deferred, and the recommended next command. Write nothing to disk unless the user asks; the ledger lives in conversation (or the plan doc, if one follows).
