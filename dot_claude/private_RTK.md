# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

## Unhandled Commands

For commands without a dedicated rtk subcommand (notably `bun run`), prefix with `rtk proxy` to track adoption without filtering:

```bash
rtk proxy bun run typecheck    # tracked in rtk gain, no compression
```

This keeps telemetry accurate so `rtk discover` surfaces real gaps.

## Weekly Review

```bash
rtk cc-economics    # $ saved vs $ spent (ccusage integration)
rtk discover        # new missed savings opportunities
rtk session         # adoption % trend across recent sessions
```

Refer to CLAUDE.md for full command reference.
