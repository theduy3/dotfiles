---
name: spec-plan-tdd-ownership
description: "Division of labor for the /spec→/plan→implement→merge workflow — human owns spec+plan, Claude owns implement through merge autonomously"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9a1a5747-86a7-402b-8c12-22ef2aab485d
---

The `/spec` → `/plan` → implement → merge workflow (see [[consolidation-into-s-star]],
spec at `~/tasks/spec-spec-tdd-workflow.md`) splits ownership at the `plan-approved` seam:

- **Human owns (interactive, grilled, approval gates):** `/spec` and `/plan` only.
  User grills requirements + sequencing, approves, flips `status: plan-approved`.
- **Claude owns (autonomous, no per-step asking):** everything from implement →
  gates → commit → PR → review → **merge**. "From implement-merge is all yours."

**Why:** user wants to invest judgment only where it's cheap to change (the plan),
then hand the mechanical implement-through-ship tail to Claude to run end-to-end
without babysitting each step.

**How to apply:** after a plan hits `plan-approved`, do NOT stop at green gates and
wait for a human ship decision. The as-built `/tdd-gates` skill hard-stops there
("Shipping is a separate decision made by a human") — that wall contradicts this
preference. Carry through: implement → commit → PR → CI → merge autonomously.
GSD tail (`gsd-execute-phase` → `gsd-verify-work` → `gsd-ship`) is the loop owner;
`CLAUDE_REMOTE=1` auto-merges after CI.

**Merge authority = FULL AUTO-MERGE (user decision 2026-07-17).** After
`plan-approved`: implement → gates → **blocking code review** → PR → wait for CI
green → **merge, no pause**. Do not ping for the merge button. Only surface if
something breaks (gate fails, CI red, conflict, or an unfixable CRITICAL/HIGH review
finding). Durable, all repos, until the user says otherwise.

**Blocking review gate is mandatory** for full-auto-merge — mechanical gates alone
don't catch logic/security/silent-failure bugs. `code-reviewer` + `security-reviewer`
+ `silent-failure-hunter` on the diff; CRITICAL/HIGH blocks; auto-fix loop capped at
2 iterations, then STOP + ping (the one sanctioned no-ping exception).

**Tail-runner is PARKED (not built yet)** — full design at `~/tasks/spec-tail-runner.md`.
Until built, this ownership+auto-merge behavior lives in memory only; a fresh session
reads `/tdd-gates:11` "human ships" and would stop. Build the tail-runner to make it
structural.
