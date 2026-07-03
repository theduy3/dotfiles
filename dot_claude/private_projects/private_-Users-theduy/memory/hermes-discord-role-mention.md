---
name: hermes-discord-role-mention
description: Hermes Discord bots silently drop owner role-mentions (<@&id>); fixed via entrypoint auto-patch
metadata: 
  node_type: memory
  type: project
  originSessionId: 5f574367-6cd4-491b-9691-ed9a98f23891
---

Hermes Discord personas silently DROP messages that mention the bot's **managed role** (`<@&roleid>`) instead of the bot **user** (`<@userid>`). Discord auto-creates a managed role named after each bot (`managed=true`, `tags.bot_id`, carries the bot's VIEW/SEND/READ perms — **cannot be deleted**, deletion API blocked). A server owner (theduy = `836783578552467467`) bypasses `mentionable=false`, so picking the role from autocomplete produces `<@&id>`. discord.py 2.7.1 puts role mentions in `raw_role_mentions`/`role_mentions`, NOT `message.mentions`, so `require_mention` (default true, adapter.py:4151) drops it at `_handle_message` with no log — bot looks dead: connected, frozen session, no reply.

Diagnosed via Discord REST reading channel messages (`mentions=[]`, content `<@&...>`) — on_message logs nothing on drop, so logs alone can't see it.

**Fix (2026-06-27):** entrypoint.wylios.sh boot auto-patch (`discord role-mention auto-patch`, 2/2 hunks) injects `_hermes_bot_role_mentioned(message)` (any `raw_role_mentions` ∩ `guild.me.roles`) and adds it to the GATE-2 require_mention check. Idempotent, re-applied every boot, survives hermes upgrades. Backup: `entrypoint.wylios.sh.bak-rolemention`. NOT yet committed to git (working-file edit on Bluehost `/root/hermes-wylios`).

Topology context: [[hermes-platform-topology]], [[hermes-wylios-config-regen]]. Box: [[hermes-desktop-remote]].
