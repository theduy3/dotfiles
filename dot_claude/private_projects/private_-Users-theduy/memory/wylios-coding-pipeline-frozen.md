---
name: wylios-coding-pipeline-frozen
description: "2026-07-20 the salonx-engineer autonomous coding pipeline was frozen; engineer+product are read-only Q&A personas, fleet pivoted to GTM/marketing"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4a24b86c-63d0-4a34-b503-ecb62ca81269
  modified: 2026-07-20T23:52:42.464Z
---

Owner decision 2026-07-20: STOP the bot-driven coding pipeline. Wylios/SalonX now run
with humans doing product/eng; the Discord fleet does GTM/marketing + advisory Q&A only.

Changes in `entrypoint.wylios.sh` (backup `.bak-nocoding-20260720-164339`), applied via
`docker restart hermes-wylios`:
- `salonx-engineer` + `salonx-product` added to the read-only persona loop -> the
  `block-codebase-writes.py` pre_tool_call hook now denies all write/shell/git-push tools
  on both; they stay on Discord for questions (`hermes-discord` chat active).
- All 4 coding-pipeline pollers gated behind `${CODING_PIPELINE_ENABLED:-0}` (default OFF):
  `paperclip-dispatch-bridge`, `ship-poller`, `decision-poller`, `approval-poller`.
  Verified 0 running post-restart.
- `salonx-engineer` git-write exception removed (line 845 `if true`): NO persona keeps
  GitHub push creds now; engineer git identity resolves to credential-less `salonx-readonly`.
- Left engineer on Anthropic Opus (Q&A quality); coding volume gone so pool drain drops.

**Why:** supersedes the live-coder assumption in [[hermes-wylios-coding-pipeline]] and
[[discord-driven-pipeline]] — those pipelines are now DORMANT, not deleted.

**How to apply / reverse:** to RE-ENABLE the whole pipeline, set `CODING_PIPELINE_ENABLED=1`
in `/root/hermes-wylios/.env` and `docker restart hermes-wylios`. To un-freeze the personas,
remove `salonx-engineer salonx-product` from the RO loop. Engineer is chat-only on Discord
(`[hermes-discord]`, no `file` read); add `file` to its platform_toolsets.discord if it needs
to read repo files when answering (hook still blocks writes). See [[entrypoint-exec-bit-strip]]
(chmod 755 after any entrypoint edit). Topology: [[hermes-platform-topology]].
