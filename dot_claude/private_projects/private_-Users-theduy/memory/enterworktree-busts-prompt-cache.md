---
name: enterworktree-busts-prompt-cache
description: "EnterWorktree/ExitWorktree regenerate CWD-dependent system-prompt sections, busting the Anthropic prompt-cache prefix at each transition"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 8f0a5790-a361-43cd-88c1-a8fa7e790514
---

`EnterWorktree` and `ExitWorktree` **bust the prompt cache**. They regenerate CWD-dependent system-prompt sections, which sit in the cached prefix — so `cache_read_input_tokens` drops to ~0 on the first API call after the transition, then re-warms.

**Evidence (definitive):** the `ExitWorktree` tool contract states its behavior:
> "Clears CWD-dependent caches (**system prompt sections**, memory files, plans directory) so the session state reflects the original directory"

`EnterWorktree` sets these up symmetrically ("switches the session's working directory"). Minimum bust = the `Primary working directory:` line in the Environment block changes; reloading the worktree's CLAUDE.md/memory enlarges the delta.

**Conflict resolved:** Claude Code's *prose docs* (memory.md, worktrees.md, tools-reference.md) don't mention cache invalidation, so a claude-code-guide agent inferred "immutable, cache-safe" (B). That inference is **wrong** — absence-of-evidence reasoning. The shipped tool contract (verdict A) overrides it. Rule: tool contract > prose docs for behavior.

**Workflow impact:** `/s1-plan` calls `EnterWorktree` mid-Opus-session → one cache re-warm at the plan→implement boundary; `/s9-cleanup`'s `ExitWorktree` → another. Bounded: 2 re-warms per worktree lifecycle (not per turn). Model routing (`/ship`→Sonnet, `/deploy`→Haiku, each a new session) still dominates total cold-start cost. Mitigation: enter the worktree before accumulating large Opus context (smaller prefix re-warms cheaper). The behavior is *correct* (worktree's project context loads) — don't fight it.

**Observe it live:** the cache hit-rate line in `~/.claude/statusline.sh` (line 2) drops the moment `/s1-plan` enters the worktree, then climbs back. See [[statusline-cache-monitoring]].
