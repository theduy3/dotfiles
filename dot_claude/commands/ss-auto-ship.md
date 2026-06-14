---
description: Post-build agent-skills tail — test → review → code-simplify → ship, run in one pass
---

Run the verification-and-ship tail of the agent-skills pipeline, in order, on the current change. Assumes spec/plan/build are already done. Stop at any stage's checkpoint (review blockers, ship NO-GO) before continuing.

1. **Test** — invoke agent-skills:test-driven-development (plus agent-skills:browser-testing-with-devtools for web UI). Confirm coverage and a green suite.
2. **Review** — invoke agent-skills:code-review-and-quality. Resolve Critical/Important findings across the five axes.
3. **Code-simplify** — invoke agent-skills:code-simplification on recently changed code, preserving exact behavior; revert anything that fails tests.
4. **Ship** — invoke agent-skills:shipping-and-launch as a parallel fan-out (code-reviewer + security-auditor + test-engineer), merged into a GO/NO-GO decision with rollback plan.

A NO-GO at Ship halts the pass.
