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
5. Keep CLAUDE.md lean — every line costs context tokens on every session. A new feature is **one line + spec pointer** (see below), never a prose dump.
6. Show the final diff

## How to write a feature entry (one line + spec pointer)

When a feature genuinely warrants a CLAUDE.md mention, write it as ONE line, not a prose dump. The architecture/rules live in the spec — CLAUDE.md only carries the pointer.

Shape:
- `### Feature Name` heading, then a single sentence: what it does + the key table/flag/RPC/file a reader needs to find it.
- End with the pointer: `**Full spec → \`tasks/spec-<name>.md\`.**` (or `**Full rules → \`docs/business-rules.md#<anchor>\`.**` for business logic).

Rules:
- One sentence. If you need a second, it belongs in the spec, not here.
- No step-by-step flows, no exhaustive column/state lists, no edge-fn internals — those are what the spec pointer is for.
- Match existing entries (e.g. "Campaign Segmentation", "Google Review Rewards") — not the bloated ones (GBP Reviews Phase 2–4); those are the anti-pattern.
- If there is no spec/business-rules file, the feature probably follows existing patterns → no CLAUDE.md entry at all (see "When NOT to update").

## If no update is needed:
Say "No CLAUDE.md update needed — this session followed existing patterns." and skip.
