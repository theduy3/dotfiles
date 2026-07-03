---
name: feedback-1m-context-flag
description: CLAUDE_CODE_DISABLE_1M_CONTEXT env var in settings.json forces 200K context even when model+plan support 1M; removed 2026-05-12
metadata: 
  node_type: memory
  type: feedback
  originSessionId: da375604-4b44-45fc-972d-bf2684bbf581
---

`CLAUDE_CODE_DISABLE_1M_CONTEXT=1` in `~/.claude/settings.json` env block disables 1M context client-side. CLI omits beta header to API, capping at 200K regardless of model capability or plan tier.

**Why:** User had set this previously (likely cost-control before Max plan covered 1M). When Opus 4.7 GA'd 1M context on Max subscription, flag became stale and silently kept session at 200K. Removed 2026-05-12.

**How to apply:** If user reports unexpected 200K cap on a model that should support 1M (Opus 4.7+, Sonnet 4+ with beta), check `~/.claude/settings.json` env block for `CLAUDE_CODE_DISABLE_*` flags first. Client-side flags trump server capability. Restart session after change — env loads at boot.

**Edit gotcha:** Auto-mode classifier blocks Edit on `~/.claude/settings.json` as self-modification. Needs explicit "go ahead" from user or manual edit / sed one-liner.

Related: [[statusline-and-hooks]]
