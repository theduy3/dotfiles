---
name: s-star-grill-and-html-gates
description: "User's /s* running order — each of s0/s1 is followed by grill-with-docs then an HTML approval artifact, before /s-auto"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2fc43f97-0ad9-457d-97ce-fe1c730e3b94
  modified: 2026-07-31T21:22:32.539Z
---

The user's standing running order for the `/s*` local pipeline (stated 2026-07-31) inserts
two extra steps at **each** human gate:

1. `/s0-spec` → draft `tasks/spec-<topic>.md`
2. `grill-with-docs` on the spec
3. Build an **HTML presentation of the spec** → publish via `Artifact` → **wait for approval**
4. `/s1-plan` → `tasks/todo-<topic>.md`
5. `grill-with-docs` on the plan
6. Build an **HTML presentation of the plan** → publish via `Artifact` → **wait for approval**
7. `/s-auto` (autonomous S2→S5 tail)

**Why:** the built-in grills inside s0/s1 sharpen requirements and sequencing but produce no
durable artifacts. `grill-with-docs` = `/grilling` + `/domain-modeling`, so it also emits ADRs
and a glossary as a side effect — the interrogation gets captured instead of evaporating. The
HTML artifact exists because the user reviews and approves visually, not by reading raw
markdown in the terminal. This **supersedes** the "built-in grill map — no external grill skill
needed" claim in [[s-star-pipeline-guide]].

**How to apply:**
- `grill-with-docs` is `disable-model-invocation: true` — it is NOT in the model's Skill list and
  cannot be fired with the Skill tool. Either prompt the user to type `/grill-with-docs`, or run
  the equivalent directly: `grilling` + `domain-modeling` (both model-invocable).
- For the HTML: load the `artifact-design` skill first, write the file, then publish with
  `Artifact`. Redeploy to the same path/URL when the spec or plan changes after grilling.
- Both approval gates are **hard stops** — do not auto-advance s0→s1 or s1→`/s-auto`. This
  reinforces the deliberate no-auto-advance gap at the `status: plan-approved` Seam.
- Past the second approval, ownership flips per [[spec-plan-tdd-ownership]]: `/s-auto` runs
  implement→gates→review→PR→CI→**merge** unattended, halting only on its 5 halt reasons.

Related: [[s-star-pipeline-guide]], [[spec-plan-tdd-ownership]], [[plugin-routing-priorities]].
