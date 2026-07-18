---
name: s-star-pipeline-guide
description: "Canonical usage guide for the /s* local pipeline lives in the vault — flow, entry rules (incl. debug-before-s0 for unknown-cause bugs), agents/models, halt surface, resume, maintenance"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 698605e9-2911-4689-b178-b801b9b42336
---

Full /s* pipeline guide: `~/theduyvault/Notes/s-star-pipeline-guide.md` (written 2026-07-18,
post-verify). Covers: s0→s1→/s-auto flow + the deliberate no-auto-advance gap at the Seam; entry
decision table (bug with unknown root cause → `systematic-debugging` first, then /s0);
built-in grill map (requirements grill in s0, adversarial plan-check + sequencing grill in
s1 — no external grill skill needed); stage agents + pinned models; 5-halt surface;
Run-State resume (`/s-auto <slug>`); /update-distill maintenance; allowlist + guard-exemption
infra; window/current-state snapshot.

Related: [[plugin-routing-priorities]] (arena split, Seam precedence),
[[claude-permission-edit-not-write]] (why the tail is promptless).
