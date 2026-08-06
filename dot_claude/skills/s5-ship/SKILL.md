---
name: s5-ship
description: Manual S5 of the /s* pipeline — spawn s-shipper from the task worktree; conventional commit, push, rich PR, CI watch (30m cap), squash auto-merge. Then parent-side worktree cleanup in the CWD-ENOENT-safe order. Requires green gates + panel approval evidence in hand; refuses to ship unverified work.
---

# `/s5-ship` — manual S5 (ship + cleanup)

Ship verified work, then clean up. You orchestrate: check preconditions, spawn
`s-shipper` (model pinned in its frontmatter), then perform the parent-side
cleanup yourself. The shipper NEVER removes the worktree — that ordering contract
is yours.

## Preconditions — refuse to ship blind

Evidence of **S3 GREEN** and **S4 all-APPROVE** must exist: in the Run-State File
(`~/tasks/.s-run/<slug>.md`), or presented by the operator this session. Neither →
refuse: "unverified — run /s3-gates and /s4-review first". Stale evidence (commits
after the last gate run) → same refusal.

## Steps

1. **Locate the worktree** (cwd if inside one, else slug → todo metadata →
   `EnterWorktree`).
2. **Spawn `s-shipper`** with the gate evidence + panel verdicts for the PR body.
   Before the spawn, print the stage banner with the live pin
   (`grep '^model:' ~/.claude/agents/s-shipper.md`):
   `▶ S5 · s-shipper · model: <pin>`.
   It commits (conventional format), pushes, opens the PR, watches CI (30m cap),
   squash-auto-merges.
3. On `merged` → **Cleanup, the CWD-ENOENT ordering contract** (parent-side,
   non-negotiable, this exact order):
   1. `git worktree list` — enumerate.
   2. `ExitWorktree` **in this parent session** (a subagent's cd changes nothing).
   3. Verify `pwd` == the main repo root (first entry of `git worktree list`).
   4. Only then: `git worktree remove <path>` and delete the local task branch.

   Skipping step 3 while your CWD is inside the worktree kills every subsequent
   tool call (`posix_spawn ENOENT`) — restart required.
4. **Run-State File**, if it exists: append Evidence tagged `manual-s5`; on merge
   you MAY set `status: merged` (double-merge guard — this is the one status flip
   allowed outside `/s-auto`, because merged is terminal and factual).
5. **Report:** PR URL, merge SHA, tasks delivered. On `ci-red` / `ci-timeout` /
   `merge-conflict` → report the shipper's evidence and stop; no PushNotification —
   the operator is present.
6. **On merge only — `/agentmemory:remember`**, after step 3's cleanup, never before it.
   Save what the shipment changed in behaviour and anything that surprised the run; 2–5
   specific lowercased concepts, because they are the retrieval surface. **Fail-open: a
   failed save is a note in the report, never a reason to stop** — the run is already
   merged, and nothing downstream depends on it. **"Nothing to save" is a valid outcome**
   for a mechanical shipment; generic entries make `recall` worse. `s-shipper` cannot do
   this — it has no `Skill` tool. Full guidance lives in `/s-auto` §4; it is not restated
   here, because a policy written in two files drifts into two policies.

## Never

- Ship without S3/S4 evidence, or with a dirty working tree.
- Commit, push, or merge inline — `s-shipper` does the git writes.
- Remove the worktree before the 4-step order, or from a subagent.
- Modify any upstream Source skill/agent.
