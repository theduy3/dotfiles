---
name: delegate-wave
description: Delegate all repository reading, discovery, and file changes to `pi` (the @earendil-works/pi-coding-agent CLI) running in tmux against DeepSeek's deepseek-v4-pro and deepseek-v4-flash models, instead of doing that work directly. Use this whenever the user asks for code exploration, investigation, or edits and expects the orchestrating session to act as a reviewer/dispatcher rather than doing the read/edit/write itself -- especially when the user says "delegate wave", "use pi for this", "wave this out", "spin up pi workers", or similar. Also use proactively whenever `AGENTS.md` says to always use delegate wave. Not for tasks with no filesystem/codebase component (pure Q&A, math, writing prose) -- those don't need a worker.
---

# delegate-wave

`pi` is a full coding-agent CLI (read/bash/edit/write/grep/find/ls tools,
its own model routing, its own sessions) that runs headlessly with `pi -p`.
That means it doesn't need to be told *how* to explore or edit -- only *what*
to do. This skill turns the orchestrating session into a dispatcher: it
decomposes work into tasks, launches one `pi` worker per task inside its own
tmux session, waits for results, reviews the diff/output, and either accepts
it, sends a follow-up in the same `pi` session, or reports a blocker. The
orchestrator does not read source files to explore, and does not edit/write
files itself -- `pi` does all of that.

## The contract

- **Orchestrator does:** decompose the request into tasks, pick a model per
  task, spawn/monitor `pi` workers, read *their* output (log + diff) to
  judge quality, send follow-up instructions, report to the user.
- **Orchestrator does not:** grep/read the target codebase to do its own
  discovery, or edit/write files in the target codebase directly. If a task
  turns out to need investigation, that investigation is itself a `pi` task
  ("find X, report back what you found"), not something the orchestrator
  does inline.
- **Reviewing is allowed and required.** Reading a worker's log, running
  `git -C <repo> diff` to see what it changed, or running the project's
  existing test command to confirm a worker's claim are all part of
  "review," not part of "discovery." The line is: don't do *the task's*
  reading/editing yourself; do verify *the worker's* output.

This mirrors why the workflow exists at all: `pi` against `deepseek-v4-flash`
(fast, cheap) or `deepseek-v4-pro` (slower, stronger judgment) does the
token-heavy grunt work, and the orchestrating model spends its budget on
decomposition and review instead of on file-by-file exploration.

## Prerequisites (check once per environment, not per task)

1. `pi` on PATH (`command -v pi`) and `tmux` on PATH (`command -v tmux`).
2. DeepSeek credentials available to `pi`. Preferred: a permanent entry in
   `~/.pi/agent/auth.json`:
   ```json
   { "deepseek": { "type": "api_key", "key": "sk-..." } }
   ```
   or `export DEEPSEEK_API_KEY=sk-...` in the shell that starts the tmux
   *server* (only works if tmux hasn't already been started with an older
   environment -- see the note below). If neither is set up, pass the key
   per-run with `DELEGATE_WAVE_API_KEY=sk-... scripts/delegate.sh spawn ...`,
   which forwards it via `pi --api-key` and works regardless of tmux's
   environment lineage.
3. `deepseek-v4-pro` / `deepseek-v4-flash` are passed straight through to
   DeepSeek's API by `--model`; they don't need to appear in
   `pi --list-models` first. If a spawned worker's log shows a model-not-found
   error from the API itself (not an auth error), the model name has changed
   upstream -- stop and ask the user for the current DeepSeek model IDs
   rather than guessing a substitute.

**tmux environment gotcha:** tmux's server process keeps the environment it
started with. `export`-ing a variable in the orchestrator's shell *after*
the tmux server is already running will not reach panes spawned later. This
is why `scripts/delegate.sh` supports `DELEGATE_WAVE_API_KEY` as an explicit
`--api-key` passthrough -- use it instead of chasing env propagation.

## Model routing

Pick per task, not per wave -- a single wave can mix both:

- **`deepseek-v4-flash`** (default/first choice): read-only discovery,
  mapping a directory, single-file mechanical edits, running a command and
  reporting output, anything where the instructions fully determine the
  answer.
- **`deepseek-v4-pro`**: multi-file or cross-cutting changes, anything
  touching a public API/contract/schema, ambiguous specs that need judgment
  calls, or a `deepseek-v4-flash` worker's output that needs a second,
  stronger pass.

Default to flash; escalate to pro only when the task actually needs the
judgment. This is the same "cheap lane first, escalate on real complexity"
logic as any other cost-aware delegation setup -- it's not about the model
being smarter in the abstract, it's about not paying for judgment a
mechanical task doesn't need.

## Workflow

1. **Decompose.** Break the request into tasks that are independent (or have
   a clear dependency order). If this is running as Section 5 of an
   AGENTS.md Brainstorm-to-Deployment workflow, the approved plan already
   did this decomposition -- reuse its tasks and their RED-GREEN-REFACTOR
   steps verbatim as the per-task prompts rather than re-deriving them.
   Otherwise, each task needs a self-contained prompt written from scratch --
   `pi` workers start blank, with no memory of this conversation. Write each
   prompt like a work order, not a hint:
   - **Target:** exact paths/symbols/directories in scope; explicit
     non-goals.
   - **Change:** what to add/remove/rename; the pattern to follow if one
     already exists in the repo.
   - **Acceptance:** what "done" looks like -- a command that should pass,
     a behavior that should hold, a specific fact to report back.

   Save each prompt to a file (`scripts/delegate.sh` reads prompts from
   files to avoid shell-quoting problems with multi-line text).

2. **Spawn the wave.** For each independent task:
   ```bash
   scripts/delegate.sh spawn <task-id> <deepseek-v4-flash|deepseek-v4-pro> <repo-dir> <prompt-file>
   ```
   Every task in a wave that has no dependency on another gets spawned in
   the same step, before waiting on any of them -- that's what makes it a
   wave rather than a queue. Tasks with a real dependency wait for the
   upstream task's result first (via `scripts/delegate.sh wait`), then get
   spawned with that result folded into their prompt.

3. **Wait and collect.**
   ```bash
   scripts/delegate.sh wait <task-id> [timeout_seconds]
   scripts/delegate.sh log <task-id>
   scripts/delegate.sh exit-code <task-id>
   ```
   `wait` blocks on the worker's actual process exit (via `tmux wait-for`),
   not on scraping pane text, so it's exact and doesn't race.

4. **Review.** Read the worker's log and, for file changes, the diff it
   produced (`git -C <repo-dir> diff`, or the worker's own summary if the
   repo isn't git-tracked). Judge against the task's Acceptance criteria.

5. **Iterate or accept.**
   - Good: move to the next task or finish the wave.
   - Needs a fix: send a follow-up in the *same* `pi` session so it keeps
     the context of what it already did:
     ```bash
     scripts/delegate.sh followup <task-id> <model> <followup-prompt-file>
     scripts/delegate.sh wait <task-id>-f2
     ```
   - Genuinely blocked (missing credential, ambiguous requirement, conflicting
     instructions): stop and report the blocker to the user rather than
     guessing or doing the work directly yourself.

6. **Report and clean up.** Summarize what each worker did, with evidence
   (log excerpts, diff, command output) -- not just "done." Then:
   ```bash
   scripts/delegate.sh status    # confirm nothing is still running
   scripts/delegate.sh cleanup   # kill all delegate-wave tmux sessions
   ```

## Script reference

`scripts/delegate.sh` (executable, no external deps beyond `pi` and `tmux`):

| Command | Effect |
|---|---|
| `spawn <id> <model> <cwd> <prompt-file>` | New tmux session `dw-<id>` running `pi -p` non-interactively against `<cwd>`, logging to `/tmp/delegate-wave/<id>.log`. |
| `followup <id> <model> <prompt-file>` | New pane, same `pi --session-id <id>`, so the worker keeps its prior context. Session becomes `<id>-f2`, `<id>-f3`, ... |
| `wait <id> [timeout]` | Blocks until that worker's process exits (`tmux wait-for`). |
| `log <id>` / `exit-code <id>` | Read captured stdout/stderr / exit status. |
| `status` | List currently running `dw-*` tmux sessions. |
| `kill <id>` | Force-stop one worker. |
| `cleanup` | Kill every `dw-*` tmux session (end-of-wave hygiene). |

Env overrides: `DELEGATE_WAVE_DIR` (scratch dir, default `/tmp/delegate-wave`),
`DELEGATE_WAVE_PROVIDER` (default `deepseek`), `DELEGATE_WAVE_API_KEY`
(explicit `--api-key` passthrough, see the tmux environment gotcha above).

Every worker runs with `--approve` (trusts project-local `pi` resources for
that one run, so headless mode doesn't silently ignore project skills/config)
and its own `--session-id`/`--session-dir` under the scratch dir, so waves
don't collide with the user's interactive `pi` sessions.
