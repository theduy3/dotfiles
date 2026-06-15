---
description: Full agent-skills pipeline — spec → plan → build → test → review → code-simplify → ship, end to end
---

> **Recommended session**: opus for stages 1–2 (spec, plan = reasoning), then run the build-onward tail (`/ss-auto-ship`) on a fresh sonnet session. A slash command can't switch the session model mid-run, so a single-model full run overpays: opus wastes spend on build/test/review, sonnet underperforms on spec/plan. Best cost/quality: opus through plan-approval, relaunch `claude --model sonnet`, then `/ss-auto-ship`.

Run the complete agent-skills pipeline in order. `$ARGUMENTS` is the initial feature description; carry it into the spec stage. Do not skip stages. Stop and surface to the user at any stage's built-in checkpoint (spec confirmation, plan approval, build failure/high-risk task, ship NO-GO) before continuing.

1. **Spec** (opus-grade) — invoke agent-skills:spec-driven-development. Produce SPEC.md; confirm with the user.
2. **Plan** (opus-grade) — invoke agent-skills:planning-and-task-breakdown. Slice the spec into small verifiable tasks (tasks/plan.md, tasks/todo.md).
3. **Build** (sonnet-grade) — invoke agent-skills:incremental-implementation alongside agent-skills:test-driven-development. Implement each task RED→GREEN→regression→build→commit. On a blocker, follow agent-skills:debugging-and-error-recovery and stop.
4. **Test** (sonnet-grade) — invoke agent-skills:test-driven-development (plus agent-skills:browser-testing-with-devtools for web UI). Verify coverage and a green suite.
5. **Review** (sonnet-grade) — invoke agent-skills:code-review-and-quality. Address Critical/Important findings.
6. **Code-simplify** (sonnet-grade) — invoke agent-skills:code-simplification on the changed code, preserving behavior; revert anything that breaks tests.
7. **Ship** (sonnet-grade) — invoke agent-skills:shipping-and-launch (parallel fan-out with each persona dispatched at `model: sonnet` → GO/NO-GO + rollback plan).

Honor each stage's stop conditions. A NO-GO at Ship halts the pipeline.
