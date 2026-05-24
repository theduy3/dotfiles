Review this session and decide whether CLAUDE.md needs updating.

## When to update (structural changes only)
- New page or component directory added
- New reusable pattern or utility introduced (used across multiple files)
- New gotcha discovered (something that caused a real bug)
- Command changed or added
- Architecture shift (new layer, new dependency pattern)

## When NOT to update (most ships)
- New feature that follows existing patterns
- Bug fixes
- UI changes
- Database migrations that don't introduce new patterns
- Anything git log already captures

## If an update IS needed:
1. Run the /claude-md-management:revise-claude-md skill to analyze the session
2. Only accept changes that add structural knowledge (new patterns, gotchas, commands)
3. Reject changelog-style entries — git log handles that
4. If the change is domain rules (business logic, permissions), update `docs/claude/` reference files instead of CLAUDE.md
5. Keep CLAUDE.md under 200 lines — every line costs context tokens on every session
6. Show the final diff

## If no update is needed:
Say "No CLAUDE.md update needed — this session followed existing patterns." and skip.
