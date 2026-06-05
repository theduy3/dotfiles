---
description: Brainstorm and design a feature before planning implementation
argument-hint: [topic]
---

Brainstorm and design a feature, producing a spec for `/s1-plan` to consume.

Parse topic from: `$ARGUMENTS`
- If provided (e.g., `/s0-brainstorm add user authentication`) → use as brainstorming topic
- If empty → ask the user to describe what they want to build

Derive `<task-name>` slug: convert the topic to lowercase kebab-case (e.g., "add user authentication" → `add-user-authentication`). This slug is used for all file paths in this command.

## Step 1: Setup

1. Confirm current directory is a git repo with `git rev-parse --show-toplevel`
2. Detect if currently inside a worktree:
   - Run `git rev-parse --git-common-dir` and `git rev-parse --git-dir`
   - If they differ → you're in a worktree
   - If in a worktree: get main repo path from first line of `git worktree list` (the path before the first space), then `cd` to it
   - Run `git checkout main && git pull origin main` (now safely in main repo)
3. Check if `tasks/spec-<task-name>.md` already exists:
   - If it exists → warn: "An existing spec was found at `tasks/spec-<task-name>.md`. Overwrite it or review what's there first?"
   - If user wants to keep it → stop (they can proceed to `/s1-plan` directly)

## Step 2: Brainstorm

Invoke `superpowers:brainstorming` skill with the topic.

**Critical overrides to the brainstorming skill's default behavior:**

1. **Spec output path**: Save the spec to `tasks/spec-<task-name>.md` — NOT to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
2. **Stop after step 8** (user reviews written spec). Do NOT invoke `superpowers:writing-plans` (step 9 of the brainstorming skill). Writing the implementation plan is `/s1-plan`'s responsibility.

Follow the brainstorming skill's full process (steps 1-8):
- Explore project context
- Offer visual companion (if visual questions ahead)
- Ask clarifying questions (one at a time)
- Propose 2-3 approaches with trade-offs
- Present design section by section
- Write spec to `tasks/spec-<task-name>.md`
- Spec self-review (fix inline)
- User reviews written spec

## Step 3: Commit & Handoff

After the user approves the spec:

1. Commit the spec:
   ```
   git add tasks/spec-<task-name>.md
   git commit -m "docs: spec for <task-name>"
   ```
2. Ask the user:
   ```
   Spec ready at tasks/spec-<task-name>.md.
   Proceed with /s1-plan <task-name>?
   ```
   - If yes → invoke `/s1-plan <task-name>`
   - If no → stop

IMPORTANT: Do NOT create a worktree, enter plan mode, or invoke writing-plans. This command's sole output is `tasks/spec-<task-name>.md`. Everything else is s1's job.
