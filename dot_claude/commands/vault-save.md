---
description: Save session summary and any architecture decisions to Obsidian vault
---

Save this session's work to the Obsidian vault at ~/theduyvault.

## Step 1: Session Summary

Write a session summary to `~/theduyvault/Notes/Claude-Context/sessions/YYYY-MM-DD-HH.md` (use today's actual date and current hour, e.g. `2026-04-18-02.md`).

Format:
```markdown
---
type: session-log
created: YYYY-MM-DD
project: [project name from pwd]
---

## Session - YYYY-MM-DD HH:00

**Project:** [current directory / project name]
**Branch:** [git branch if applicable]

### Key Decisions
- [bullet each significant decision made]

### Bugs Fixed
- [bug description] — Root cause: [why it happened]

### Patterns Discovered
- [any reusable patterns, constraints, or gotchas]

### Next Steps
- [what was left unfinished]
```

## Step 2: Architecture Decisions (if any)

For each major architecture decision made this session, create `~/theduyvault/Notes/ADR/YYYY-MM-DD-[short-title].md`:

```markdown
---
type: adr
created: YYYY-MM-DD
status: accepted
project: [project name]
---

## Decision
[what was decided in one sentence]

## Context
[why this decision was needed — the problem it solves]

## Options Considered
- Option A: [description]
- Option B: [description]

## Chosen: [option]
[rationale]

## Consequences
[trade-offs, what this makes easier/harder]
```

## Step 3: Update Project Registry (if new project)

If this is the first session for this project, add an entry to `~/theduyvault/Notes/Claude-Context/project-registry.md`:

```
| /absolute/path/to/project | [[Projects/project-name/CLAUDE]] | yes |
```
