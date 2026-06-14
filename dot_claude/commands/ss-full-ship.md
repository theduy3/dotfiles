---
description: Full agent-skills pipeline — spec → plan → build → test → review → code-simplify → ship, end to end
---

Run the complete agent-skills pipeline in order. `$ARGUMENTS` is the initial feature description; carry it into the spec stage. Do not skip stages. Stop and surface to the user at any stage's built-in checkpoint (spec confirmation, plan approval, build failure/high-risk task, ship NO-GO) before continuing.

1. **Spec** — invoke agent-skills:spec-driven-development. Produce SPEC.md; confirm with the user.
2. **Plan** — invoke agent-skills:planning-and-task-breakdown. Slice the spec into small verifiable tasks (tasks/plan.md, tasks/todo.md).
3. **Build** — invoke agent-skills:incremental-implementation alongside agent-skills:test-driven-development. Implement each task RED→GREEN→regression→build→commit. On a blocker, follow agent-skills:debugging-and-error-recovery and stop.
4. **Test** — invoke agent-skills:test-driven-development (plus agent-skills:browser-testing-with-devtools for web UI). Verify coverage and a green suite.
5. **Review** — invoke agent-skills:code-review-and-quality. Address Critical/Important findings.
6. **Code-simplify** — invoke agent-skills:code-simplification on the changed code, preserving behavior; revert anything that breaks tests.
7. **Ship** — invoke agent-skills:shipping-and-launch (parallel fan-out → GO/NO-GO + rollback plan).

Honor each stage's stop conditions. A NO-GO at Ship halts the pipeline.
