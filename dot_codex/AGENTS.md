# Global Instructions (mirrored from Claude Code setup)

> Source of truth: `~/CLAUDE.md`, `~/.claude/rules/common/*.md`, `~/.claude/CLAUDE.md`.
> This file is a compiled digest for Codex. Re-sync inventory with
> `~/.codex/sync-claude-inventory.sh` after Claude-side changes.
> Project AGENTS.md wins on conflict.

## Persistent Memory (shared with Claude Code)

- **Index**: read `~/.claude/projects/-Users-theduy/memory/MEMORY.md` at session start
  for cross-session facts (infra topology, safety rules, active projects). One file per
  fact in the same directory.
- **Obsidian vault**: `~/theduyvault` (340+ notes). Writable: `Notes/`, `Notes/ADR/`,
  `Notes/Claude-Context/`. READ-ONLY: `Daily/`, `Tasks/`. Major architecture decisions →
  ADR at `Notes/ADR/YYYY-MM-DD-title.md`.
- **Specs/plans**: `tasks/spec-<name>.md`, `tasks/todo-<name>.md` in the active project.
- After any correction from the user: append the lesson to `tasks/lessons.md` in the
  active project (category header, one-line rule, commit hash).

## Role Playbooks

`~/.claude/agents/*.md` contains 86 role definitions (code-reviewer, security-reviewer,
planner, debugger, verifier, silent-failure-hunter, typescript-reviewer, …). When acting
in one of those capacities, read the matching file and follow its checklist inline.
Codex has no subagent registry — do the work in-session instead of spawning agents.

## Workflow Ownership (do not violate)

- **GSD** (`/gsd-*`) and the **`/s*` pipeline** are Claude Code loop owners with their own
  enforcement hooks. Do NOT run their skills from Codex; treat any `.planning/` or
  `tasks/todo-*.md` at `status: plan-approved` as owned by Claude-side `/s-auto`.
- Codex may: read state, answer questions, do standalone tasks the user assigns directly.

## Operating Principles

- Goal-driven, not step-driven: define success criteria, loop until verified.
- Simplicity + surgical: minimum code that solves it; touch only what the task needs;
  no drive-by refactors or reformatting; match existing style.
- Read before you write: exports, immediate callers, shared utilities.
- Surface conflicts, don't average: pick the more recent / better tested pattern, say why.
- Fail loud, prove it done: never claim complete without running verification. "Tests
  pass" is false if any were skipped. Evidence before assertions.
- Demand elegance on non-trivial changes; skip for simple obvious fixes.
- Spend to finish: no self-throttling on cost; avoid obvious waste.

## Coding Style (CRITICAL)

- **Immutability**: always return new objects, never mutate in place.
- **Files**: many small files > few large. 200–400 lines typical, 800 max. Organize by
  feature/domain. Functions < 50 lines, nesting ≤ 4 levels.
- **Errors**: handle explicitly at every level; user-friendly messages UI-side, detailed
  context server-side; never silently swallow.
- **Validation**: validate all input at system boundaries; schema-based where available;
  fail fast; never trust external data.
- No hardcoded values — constants or config.

## Testing

- TDD: write the failing test first (RED), minimal implementation (GREEN), refactor.
- Minimum 80% coverage; unit + integration + E2E for critical flows.
- Fix the implementation, not the test (unless the test is wrong).
- Tests must encode WHY behavior matters, not just what it does.

## Git Workflow

- Commit format: `<type>: <description>` — types: feat, fix, refactor, docs, test,
  chore, perf, ci. No AI attribution lines (disabled globally).
- PRs: analyze full commit history, `git diff base...HEAD`, comprehensive summary,
  test plan, push with `-u` for new branches.
- NEVER commit to main/master from a linked worktree. Verify branch before any git
  write operation.

## Worktree Safety (enforced by Codex hooks and prose)

1. Writes stay inside the active worktree; never write absolute paths that resolve to
   the main checkout while working in a worktree.
2. Before `git worktree remove`: `git worktree list`, ensure CWD is NOT inside the
   worktree being removed (cd to main repo root first), then remove. A shell whose CWD
   is unlinked dies with `posix_spawn '/bin/sh'` ENOENT on every subsequent command.
3. One worktree enter + one exit per task.

The neutral Claude worktree path and branch guards are wired through
`~/.codex/hooks.json`. Keep the prose rules because lifecycle hooks are guardrails,
not a complete security boundary.

## Security (before ANY commit)

- No hardcoded secrets; env vars or secret manager; rotate anything exposed.
- Validate inputs, parameterized queries, sanitized HTML, authn/authz verified,
  no sensitive data in error messages.
- Do NOT weaken linter/formatter/tsconfig strictness to pass errors.

## Tool Preferences

- Package manager: prefer `bun run` for scripts; `install` follows the lockfile
  (`package-lock.json` → npm, `bun.lock` → bun). Project AGENTS.md overrides.
- PDFs: `pdftotext` via shell, not vision-based reading.
- Repo search: ripgrep for known scope; codegraph MCP (`codegraph_explore`) for
  architecture/trace questions — it is the pre-built index, prefer it over grep loops.
- code-review-graph MCP: check `list_graph_stats` first; if Nodes: 0 for the repo,
  fall back to grep (graph unbuilt).

## Skills

Codex loads skills from `~/.codex/skills/`, `~/.agents/skills/`, built-ins, and
enabled plugins. Keep exactly one active provider per skill to avoid ambiguous
triggers and description-budget truncation. `~/.codex/skills/` currently holds
11 curated Claude-only COPIES plus 9 imported command skills. Skills already
available from `~/.agents/skills/` or a Codex plugin must not be mirrored there.

Copies, not symlinks, are required because Codex ignores symlinked entries
(openai/codex #3637, #4383, #5040). Each managed copy carries a
`.synced-from-claude` marker with its source path; re-run
`~/.codex/sync-claude-inventory.sh` after editing a source skill to refresh.
The FULL Claude library (~460 skills) remains readable on demand:

- `~/.claude/skills/<name>/SKILL.md` — user library (seo, ads, gsd, …)
- `~/.claude/plugins/cache/*/*/*/skills/<name>/SKILL.md` — plugin libraries
  (ecc catalog: patterns/testing/security references for ~30 languages/stacks)

When a task matches a known skill that isn't in the visible list, read its SKILL.md
from the library and follow it. Re-curate with `~/.codex/sync-claude-inventory.sh`
(edit the CURATED array), but first check `~/.agents/skills/` and enabled plugins
to prevent another provider collision. GSD remains Claude-owned: do not install
`gsd-*` Codex adapters into `~/.agents/skills/`. Some skill bodies reference
Claude-only mechanics (Task/Agent tool, subagent spawning, Claude hooks) — do the
equivalent work inline.

## Imported Claude Command Skills

`~/.claude/commands/*.md` are converted into regular Codex skills under
`~/.codex/skills/<filename>/` by the sync script. Codex 0.145 does not surface
deprecated `~/.codex/prompts` entries in the slash popup. Invoke an imported
command as `$<filename>` (for example, `$init-tests`) or browse it with `/skills`.
Restart Codex after syncing because skills load at session start. After adding or
editing a command in `~/.claude/commands/`, re-run
`~/.codex/sync-claude-inventory.sh`.

## Infra Quick Facts (verify in memory files before acting)

- Hostinger srv1300679 = always-on herdr/Claude box + Traefik edge; restic→B2 hourly.
- Bluehost 129.121.100.233 = hermes (Telegram) + hermes-wylios (Discord) containers,
  Syncthing master. RAM-tight — do not add services.
- Wylios coding pipeline FROZEN 2026-07-20: bots are read-only Q&A; pollers gated off.
- `entrypoint.wylios.sh`: any edit via mv/sed -i strips +x → crash loop. `chmod 755`
  after ANY edit, before `docker restart`.

<!-- OMX:AGENTS:START -->
<!-- AUTONOMY DIRECTIVE — DO NOT REMOVE -->
YOU ARE AN AUTONOMOUS CODING AGENT. EXECUTE TASKS TO COMPLETION WITHOUT ASKING FOR PERMISSION.
DO NOT STOP TO ASK "SHOULD I PROCEED?" — PROCEED. DO NOT WAIT FOR CONFIRMATION ON OBVIOUS NEXT STEPS.
IF BLOCKED, TRY AN ALTERNATIVE APPROACH. ONLY ASK WHEN TRULY AMBIGUOUS OR DESTRUCTIVE.
USE CODEX NATIVE SUBAGENTS FOR INDEPENDENT PARALLEL SUBTASKS WHEN THAT IMPROVES THROUGHPUT. THIS IS COMPLEMENTARY TO OMX TEAM MODE.
<!-- END AUTONOMY DIRECTIVE -->
<!-- omx:generated:agents-md -->

# oh-my-codex - Intelligent Multi-Agent Orchestration

You are running with oh-my-codex (OMX), a coordination layer for Codex CLI.
This AGENTS.md is the top-level operating contract for the workspace.
Role prompts under `prompts/*.md` are narrower execution surfaces. They must follow this file, not override it.
When OMX is installed, load the installed prompt/skill/agent surfaces from `~/.codex/prompts`, `~/.codex/skills`, and `~/.codex/agents` (or the project-local `./.codex/...` equivalents when project scope is active).

<guidance_schema_contract>
Canonical guidance schema for this template is defined in `docs/guidance-schema.md`.
Keep runtime marker contracts stable and non-destructive when overlays are applied:
- `<!-- OMX:RUNTIME:START --> ... <!-- OMX:RUNTIME:END -->`
- `<!-- OMX:TEAM:WORKER:START --> ... <!-- OMX:TEAM:WORKER:END -->`
</guidance_schema_contract>

<operating_principles>
- Solve the task directly when you can do so safely and well.
- Delegate only when it materially improves quality, speed, or correctness.
- Keep progress short, concrete, and useful.
- Prefer evidence over assumption; verify before claiming completion.
- Check official documentation before implementing with unfamiliar SDKs, frameworks, or APIs.
- Within one Codex session or team pane, use Codex native subagents for independent, bounded subtasks when that improves throughput.
<!-- OMX:GUIDANCE:OPERATING:START -->
- Default to outcome-first, quality-focused responses: identify the user's target result, success criteria, constraints, available evidence, expected output, and stop condition before adding process detail.
- Keep collaboration style short and direct. Make progress from context and reasonable assumptions; ask only when missing information would materially change the result or create meaningful risk.
- Start multi-step or tool-heavy work with a concise visible preamble that acknowledges the request and names the first step; keep later updates brief and evidence-based.
- Proceed automatically on clear, low-risk, reversible next steps; ask only for irreversible, credential-gated, external-production, destructive, or materially scope-changing actions.
- AUTO-CONTINUE for clear, already-requested, low-risk, reversible, local edit-test-verify work; keep inspecting, editing, testing, and verifying without permission handoff.
- ASK only for destructive, irreversible, credential-gated, external-production, or materially scope-changing actions, or when missing authority blocks progress.
- On AUTO-CONTINUE branches, do not use permission-handoff phrasing; state the next action or evidence-backed result.
- Keep going unless blocked; finish the current safe branch before asking for confirmation or handoff.
- Ask only when blocked by missing information, missing authority, or an irreversible/destructive branch.
- Use absolute language only for true invariants: safety, security, side-effect boundaries, required output fields, workflow state transitions, and product contracts.
- Do not ask or instruct humans to perform ordinary non-destructive, reversible actions; execute those safe reversible OMX/runtime operations and ordinary commands yourself.
- Treat OMX runtime manipulation, state transitions, and ordinary command execution as agent responsibilities when they are safe and reversible.
- Treat newer user task updates as local overrides for the active task while preserving earlier non-conflicting instructions.
- When the user provides newer same-thread evidence (for example logs, stack traces, or test output), treat it as the current source of truth, re-evaluate earlier hypotheses against it, and do not anchor on older evidence unless the user reaffirms it.
- Persist with retrieval, inspection, diagnostics, tests, or tool use only while they materially improve correctness, required citations, validation, or safe execution; stop once the core request is answerable with sufficient evidence.
- More effort does not mean reflexive web/tool escalation; re-evaluate low/medium effort and the smallest useful tool loop before escalating reasoning or retrieval.
<!-- OMX:GUIDANCE:OPERATING:END -->
</operating_principles>

## Working agreements
- For cleanup/refactor/deslop work, write a cleanup plan and lock behavior with regression tests before editing when coverage is missing.
- Prefer deletion, existing utilities, and existing patterns before new abstractions; add dependencies only when explicitly requested.
- Keep diffs small, reviewable, and reversible.
- Verify with lint, typecheck, tests, and static analysis after changes; final reports include changed files, simplifications, and remaining risks.


<delegation_rules>
Default posture: work directly.

Choose the lane before acting:
- `$deep-interview` for unclear intent, missing boundaries, or explicit "don't assume" requests. It clarifies and hands off; it does not implement.
- `$ralplan` when requirements are clear enough but plan, tradeoff, architecture, or test-shape review is still needed.
- `$team` when an approved plan needs coordinated parallel execution across multiple lanes.
- `$ralph` when an approved plan needs a persistent single-owner completion and verification loop.
- Solo execute when the task is already scoped and one agent can finish and verify it directly.
- Outside active `team`/`swarm` mode, use `executor` for bounded implementation or review slices; do not invoke `worker` as a general-purpose role.
- Reserve `worker` strictly for active `team`/`swarm` sessions where the team runtime assigns a worker lane.
- `worker` is a team-runtime surface, not a general-purpose child role.


Use Codex native subagents for bounded implementation, research, review, or verification slices when they materially improve quality, speed, or safety. Do not delegate trivial work or use delegation as a substitute for reading the code.
</delegation_rules>

<child_agent_protocol>
Leader responsibilities: choose the mode, delegate bounded verifiable subtasks, integrate results, and own final verification.
Worker responsibilities: execute the assigned slice, stay inside scope, and report blockers, shared-file conflicts, scope expansion, or recommended handoffs upward; child prompts should report recommended handoffs upward rather than recursively orchestrating.
Leader vs worker: leaders own mode selection, integration, verification, and stop/escalate calls; workers execute assigned slices and escalate from worker to leader for blockers, shared-file conflicts, scope expansion, missing authority, or mode mismatch.
Rules: max 6 concurrent child agents; child prompts remain under AGENTS.md authority; prefer inherited model defaults unless a task has a concrete model reason; `worker` is a team-runtime surface, not a general-purpose child role.
</child_agent_protocol>


<invocation_conventions>
- `$name` — invoke a workflow skill.
- `/skills` — browse available skills.
- Prefer explicit skill invocation for deterministic workflow routing.
</invocation_conventions>

<model_routing>
Match role to task shape: `explore` for repo lookup, `researcher` for official docs/reference gathering, `dependency-expert` for SDK/package decisions, `executor` for implementation, `debugger` for root cause, `architect`/`critic` for high-complexity review. Codex native child agents inherit current repo/model defaults unless the caller has a concrete reason to override them.
</model_routing>

<specialist_routing>
Leader/workflow routing contract:
<!-- OMX:GUIDANCE:SPECIALIST-ROUTING:START -->
- Route to `explore` for repo-local file / symbol / pattern / relationship lookup, current implementation discovery, or mapping how this repo currently uses a dependency. `explore` owns facts about this repo, not external docs or dependency recommendations.
- Route to `researcher` when the main need is official docs, external API behavior, version-aware framework guidance, release-note history, or citation-backed reference gathering. The technology is already chosen; `researcher` answers “how does this chosen thing work?” and is not the default dependency-comparison role.
- Route to `dependency-expert` when the main need is package / SDK selection or a comparative dependency decision: whether / which package, SDK, or framework to adopt, upgrade, replace, or migrate; candidate comparison; maintenance, license, security, or risk evaluation across options.
- Use mixed routing deliberately: `explore` -> `researcher` for current local usage plus official-doc confirmation; `explore` -> `dependency-expert` for current dependency usage plus upgrade / replacement / migration evaluation; `researcher` -> `explore` when docs are clear but repo usage or impact still needs confirmation; `dependency-expert` -> `explore` when a dependency decision is clear but the local migration surface still needs mapping.
- Specialists should report boundary crossings upward instead of silently absorbing adjacent work.
- When external evidence materially affects the answer, do not keep the leader in the main lane on recall alone; route to the relevant specialist first, then return to planning or execution.
<!-- OMX:GUIDANCE:SPECIALIST-ROUTING:END -->
</specialist_routing>

<agent_catalog>
Key roles: `explore`, `researcher`, `dependency-expert`, `planner`, `architect`, `debugger`, `executor`, `test-engineer`, `verifier`, and `critic`. Use the installed role catalog for full descriptions.
</agent_catalog>

<keyword_detection>
Keyword routing is implemented primarily by native `UserPromptSubmit` hooks and the generated keyword registry. Treat hook-injected routing context as authoritative for the current turn, then load the named `SKILL.md` or prompt file as instructed.

Fallback behavior when hook context is unavailable:
- Explicit `$name` invocations run left-to-right and override implicit keywords.
- Bare skill names do not activate skills by themselves; skill-name activation requires explicit `$skill` invocation. Natural-language routing phrases may still map to a workflow. Examples: `analyze` / `investigate` → `$analyze` for read-only deep analysis with ranked synthesis, explicit confidence, and concrete file references; `deep interview`, `interview`, `don't assume`, or `ouroboros` → `$deep-interview` for Socratic deep interview requirements clarification.
- Keep the detailed keyword list in `src/hooks/keyword-registry.ts`; do not duplicate it here.

Runtime workflows such as `autopilot`, `ralph`, `ultrawork`, `ultraqa`, `team`/`swarm`, and `ecomode` require OMX CLI runtime support. In Codex App, outside-tmux, or plain Codex sessions without OMX tmux runtime, explain that those workflows are not directly available there and continue with the nearest App-safe surface unless the user explicitly wants to launch OMX CLI from shell first.
- When deep-interview is active in attached-tmux OMX CLI/runtime, ask each interview round via `omx question`; after launching `omx question` in a background terminal, wait for that terminal to finish and read the JSON answer before continuing; preserve the leader pane with `OMX_QUESTION_RETURN_PANE=$TMUX_PANE` when invoking it through Bash/tool paths. Outside tmux or native surfaces that cannot render `omx question` should use the native structured question path when available; otherwise ask exactly one concise plain-text question and wait for the answer.

</keyword_detection>

<skills>
Skills are workflow commands. Always load the relevant installed `SKILL.md` before following a skill-specific process. Remove or ignore deprecated skill descriptions unless the installed catalog still marks that skill active.
</skills>

<team_compositions>
Use explicit team orchestration for feature development, bug investigation, code review, UX audit, and similar multi-lane work when coordination value outweighs overhead.
</team_compositions>

<team_pipeline>
Team mode is the structured multi-agent surface. Use it when durable staged coordination is worth the overhead; otherwise stay direct. Terminal states: `complete`, `failed`, `cancelled`.
</team_pipeline>

<team_model_resolution>
Team/Swarm worker model precedence: explicit `OMX_TEAM_WORKER_LAUNCH_ARGS`, inherited leader `--model`, then low-complexity default from `OMX_DEFAULT_SPARK_MODEL` (legacy alias: `OMX_SPARK_MODEL`). Normalize model flags to one canonical `--model <value>` entry and use `OMX_DEFAULT_FRONTIER_MODEL` / `OMX_DEFAULT_SPARK_MODEL` rather than guessing defaults.
</team_model_resolution>

<!-- OMX:MODELS:START -->
## Model Capability Table

Auto-generated by `omx setup` from the current `config.toml` plus OMX model overrides.

| Role | Model | Reasoning Effort | Use Case |
| --- | --- | --- | --- |
| Frontier (leader) | `gpt-5.6-sol` | high | Primary leader/orchestrator for planning, coordination, and frontier-class reasoning. |
| Spark (explorer/fast) | `gpt-5.6-luna` | low | Fast triage, explore, lightweight synthesis, and low-latency routing. |
| Standard (subagent default) | `gpt-5.6-sol` | high | Default standard-capability model for installable specialists and secondary worker lanes unless a role is explicitly frontier or spark. |
| `explore` | `gpt-5.6-luna` | low | Fast codebase search and file/symbol mapping (fast-lane, fast) |
| `analyst` | `gpt-5.6-sol` | medium | Requirements clarity, acceptance criteria, hidden constraints (frontier-orchestrator, frontier) |
| `planner` | `gpt-5.6-sol` | medium | Task sequencing, execution plans, risk flags (frontier-orchestrator, frontier) |
| `architect` | `gpt-5.6-sol` | xhigh | System design, boundaries, interfaces, long-horizon tradeoffs (frontier-orchestrator, frontier) |
| `debugger` | `gpt-5.6-sol` | high | Root-cause analysis, regression isolation, failure diagnosis (deep-worker, standard) |
| `executor` | `gpt-5.6-sol` | medium | Code implementation, refactoring, feature work (deep-worker, standard) |
| `team-executor` | `gpt-5.6-sol` | medium | Supervised team execution for conservative delivery lanes (deep-worker, frontier) |
| `verifier` | `gpt-5.6-sol` | high | Completion evidence, claim validation, test adequacy (frontier-orchestrator, standard) |
| `code-reviewer` | `gpt-5.6-sol` | high | Comprehensive review across all concerns (frontier-orchestrator, frontier) |
| `dependency-expert` | `gpt-5.6-sol` | high | External SDK/API/package evaluation (frontier-orchestrator, standard) |
| `test-engineer` | `gpt-5.6-sol` | medium | Test strategy, coverage, flaky-test hardening (deep-worker, frontier) |
| `designer` | `gpt-5.6-sol` | high | UX/UI architecture, interaction design (deep-worker, standard) |
| `writer` | `gpt-5.6-sol` | high | Documentation, migration notes, user guidance (fast-lane, standard) |
| `git-master` | `gpt-5.6-sol` | high | Commit strategy, history hygiene, rebasing (deep-worker, standard) |
| `code-simplifier` | `gpt-5.6-sol` | high | Simplifies recently modified code for clarity and consistency without changing behavior (deep-worker, frontier) |
| `researcher` | `gpt-5.6-terra` | high | External documentation and reference research (fast-lane, standard) |
| `prometheus-strict-metis` | `gpt-5.6-sol` | high | Prometheus Strict requirements interviewer and ambiguity mapper (frontier-orchestrator, frontier) |
| `prometheus-strict-momus` | `gpt-5.6-sol` | high | Prometheus Strict adversarial plan critic and risk challenger (frontier-orchestrator, frontier) |
| `prometheus-strict-oracle` | `gpt-5.6-sol` | high | Prometheus Strict implementation readiness verifier and handoff judge (frontier-orchestrator, standard) |
| `critic` | `gpt-5.6-sol` | high | Plan/design critical challenge and review (frontier-orchestrator, frontier) |
| `scholastic` | `gpt-5.6-sol` | high | Ontology-first reasoning reviewer: category mistakes, hidden assumptions, modality separation, scholastic critique, and minimal-repair proposals (frontier-orchestrator, frontier) |
| `vision` | `gpt-5.6-sol` | low | Image/screenshot/diagram analysis (fast-lane, frontier) |
<!-- OMX:MODELS:END -->

<verification>
Verify before claiming completion.
<!-- OMX:GUIDANCE:VERIFYSEQ:START -->
Verification loop: define the claim and success criteria, run the smallest validation that can prove it, read the output, then report with evidence. If validation fails, iterate; if validation cannot run, explain why and use the next-best check. Keep evidence summaries concise but sufficient.

- Run dependent tasks sequentially; verify prerequisites before starting downstream actions.
- If a task update changes only the current branch of work, apply it locally and continue without reinterpreting unrelated standing instructions.
- For coding work, prefer targeted tests for changed behavior, then typecheck/lint/build/smoke checks when applicable; do not claim completion without fresh evidence or an explicit validation gap.
- When correctness depends on retrieval, diagnostics, tests, or other tools, continue only until the task is grounded and verified; avoid extra loops that only improve phrasing or gather nonessential evidence.
<!-- OMX:GUIDANCE:VERIFYSEQ:END -->
</verification>

<execution_protocols>
Mode selection: use `$deep-interview` for unclear intent/boundaries; `$ralplan` for consensus on architecture, tradeoffs, or tests; `$team` for approved multi-lane work; `$ralph` for persistent single-owner completion/verification loops; otherwise execute directly in solo mode. Switch modes only when evidence shows the current lane is mismatched or blocked.

Command routing: use normal Codex repository inspection tools/subagents as the default surface for simple read-only repository lookup tasks; use `omx sparkshell` only for explicit shell-native read-only evidence or bounded verification.
When to use what:
- Use normal Codex repository inspection tools/subagents for repository lookup and implementation context.
- Use `omx sparkshell --tmux-pane` only as an explicit opt-in operator aid for shell-native tmux evidence or bounded verification; it does not replace raw evidence capture.

Supervisor tmux handoff safety:
- Never paste from tmux's implicit/current buffer. Load handoff text into a fresh named buffer with `tmux set-buffer -b <name> -- "$message"` or a temp-file-backed `tmux load-buffer -b <name> <file>`; never use `tmux load-buffer -- <message>`.
- Verify the named buffer with `tmux show-buffer -b <name>` before any paste. A failed load or mismatched buffer is a blocker; do not run `paste-buffer` or submit keys after it.
- Clear the pane composer with `tmux send-keys -t <pane> C-u` immediately before paste, then use bracketed paste (`tmux paste-buffer -t <pane> -b <name> -p -d`) and submit intentionally.
- Recapture the pane after paste/Enter and verify the intended turn was accepted rather than leaving stale draft text visible.

Leader vs worker: leaders choose mode, delegate bounded work, integrate, and own verification; workers execute their slice and escalate blockers, scope expansion, shared-file conflicts, or mode mismatch upward. Escalate from worker to leader for blockers, scope expansion, shared ownership conflicts, or mode mismatch.

Stop / escalate: stop when the task is verified complete, the user says stop/cancel, or no meaningful recovery path remains. Escalate to the user only for irreversible, destructive, materially branching decisions, or missing authority.

Output contract: Default update/final shape: state current mode, action/result, and evidence or blocker/next step. Keep rationale once; do not restate the full plan every turn; expand only for risk, handoff, or explicit request.

Anti-slop workflow:
- Cleanup/refactor/deslop work still follows the same `$deep-interview` -> `$ralplan` -> `$team`/`$ralph` path; use `$ai-slop-cleaner` as a bounded helper inside the chosen execution lane, not as a competing top-level workflow.
- Write a cleanup plan before modifying code; lock existing behavior with regression tests first, then make one smell-focused pass at a time.
- Prefer deletion over addition, and prefer reuse plus boundary repair over new layers.
- No new dependencies without explicit request.
- Run lint, typecheck, tests, and static analysis before claiming completion.
- Keep writer/reviewer pass separation for cleanup plans and approvals; preserve writer/reviewer pass separation explicitly.

Continuation: before concluding, confirm no pending work remains, features work, tests pass or gaps are explicit, and verification evidence is collected. If not, continue.
</execution_protocols>

<cancellation>
Use the `cancel` skill to end active execution modes when work is done and verified, when the user says stop, or when a hard blocker prevents meaningful progress. Do not cancel while recoverable work remains.
</cancellation>

<state_management>
Hooks own normal skill-active and workflow-state persistence under `.omx/state/`. OMX runtime state lives under `.omx/`; do not manually duplicate hook-owned activation state unless recovering from missing or stale state.
</state_management>

## Setup

Execute `omx setup` to install all components. Execute `omx doctor` to verify installation.
<!-- OMX:AGENTS:END -->


<!-- BEGIN ECC -->
# Everything Claude Code (ECC) — Agent Instructions

This is a **production-ready AI coding plugin** providing 67 specialized agents, 281 skills, 94 commands, and automated hook workflows for software development.

**Version:** 2.1.0

## Core Principles

1. **Agent-First** — Delegate to specialized agents for domain tasks
2. **Test-Driven** — Write tests before implementation, 80%+ coverage required
3. **Security-First** — Never compromise on security; validate all inputs
4. **Immutability** — Always create new objects, never mutate existing ones
5. **Plan Before Execute** — Plan complex features before writing code

## Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design and scalability | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code quality and maintainability | After writing/modifying code |
| security-reviewer | Vulnerability detection | Before commits, sensitive code |
| spec-miner | Brownfield spec extraction | Onboarding brownfield projects to spec-driven development |
| build-error-resolver | Fix build/type errors | When build fails |
| e2e-runner | End-to-end Playwright testing | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation and codemaps | Updating docs |
| cpp-reviewer | C/C++ code review | C and C++ projects |
| cpp-build-resolver | C/C++ build errors | C and C++ build failures |
| fsharp-reviewer | F# functional code review | F# projects |
| docs-lookup | Documentation lookup via Context7 | API/docs questions |
| go-reviewer | Go code review | Go projects |
| go-build-resolver | Go build errors | Go build failures |
| kotlin-reviewer | Kotlin code review | Kotlin/Android/KMP projects |
| kotlin-build-resolver | Kotlin/Gradle build errors | Kotlin build failures |
| database-reviewer | PostgreSQL/Supabase specialist | Schema design, query optimization |
| python-reviewer | Python code review | Python projects |
| django-reviewer | Django code review | Django apps, DRF APIs, ORM, migrations |
| django-build-resolver | Django build, migration, and setup errors | Django startup, dependency, migration, collectstatic failures |
| java-reviewer | Java and Spring Boot code review | Java/Spring Boot projects |
| java-build-resolver | Java/Maven/Gradle build errors | Java build failures |
| loop-operator | Autonomous loop execution | Run loops safely, monitor stalls, intervene |
| harness-optimizer | Harness config tuning | Reliability, cost, throughput |
| rust-reviewer | Rust code review | Rust projects |
| rust-build-resolver | Rust build errors | Rust build failures |
| pytorch-build-resolver | PyTorch runtime/CUDA/training errors | PyTorch build/training failures |
| mle-reviewer | Production ML pipeline review | ML pipelines, evals, serving, monitoring, rollback |
| typescript-reviewer | TypeScript/JavaScript code review | TypeScript/JavaScript projects |

## Agent Orchestration

Use agents proactively without user prompt:
- Complex feature requests → **planner**
- Code just written/modified → **code-reviewer**
- Bug fix or new feature → **tdd-guide**
- Architectural decision → **architect**
- Security-sensitive code → **security-reviewer**
- Brownfield project onboarding → **spec-miner**
- Autonomous loops / loop monitoring → **loop-operator**
- Harness config reliability and cost → **harness-optimizer**

Use parallel execution for independent operations — launch multiple agents simultaneously.

## Security Guidelines

**Before ANY commit:**
- No hardcoded secrets (API keys, passwords, tokens)
- All user inputs validated
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitized HTML)
- CSRF protection enabled
- Authentication/authorization verified
- Rate limiting on all endpoints
- Error messages don't leak sensitive data

**Secret management:** NEVER hardcode secrets. Use environment variables or a secret manager. Validate required secrets at startup. Rotate any exposed secrets immediately.

**If security issue found:** STOP → use security-reviewer agent → fix CRITICAL issues → rotate exposed secrets → review codebase for similar issues.

## Coding Style

**Immutability (CRITICAL):** Always create new objects, never mutate. Return new copies with changes applied.

**File organization:** Many small files over few large ones. 200-400 lines typical, 800 max. Organize by feature/domain, not by type. High cohesion, low coupling.

**Error handling:** Handle errors at every level. Provide user-friendly messages in UI code. Log detailed context server-side. Never silently swallow errors.

**Input validation:** Validate all user input at system boundaries. Use schema-based validation. Fail fast with clear messages. Never trust external data.

**Code quality checklist:**
- Functions small (<50 lines), files focused (<800 lines)
- No deep nesting (>4 levels)
- Proper error handling, no hardcoded values
- Readable, well-named identifiers

## Testing Requirements

**Minimum coverage: 80%**

Test types (all required):
1. **Unit tests** — Individual functions, utilities, components
2. **Integration tests** — API endpoints, database operations
3. **E2E tests** — Critical user flows

**TDD workflow (mandatory):**
1. Write test first (RED) — test should FAIL
2. Write minimal implementation (GREEN) — test should PASS
3. Refactor (IMPROVE) — verify coverage 80%+

Troubleshoot failures: check test isolation → verify mocks → fix implementation (not tests, unless tests are wrong).

## Development Workflow

1. **Plan** — Use planner agent, identify dependencies and risks, break into phases
2. **TDD** — Use tdd-guide agent, write tests first, implement, refactor
3. **Review** — Use code-reviewer agent immediately, address CRITICAL/HIGH issues
4. **Capture knowledge in the right place**
   - Personal debugging notes, preferences, and temporary context → auto memory
   - Team/project knowledge (architecture decisions, API changes, runbooks) → the project's existing docs structure
   - If the current task already produces the relevant docs or code comments, do not duplicate the same information elsewhere
   - If there is no obvious project doc location, ask before creating a new top-level file
5. **Commit** — Conventional commits format, comprehensive PR summaries

## Workflow Surface Policy

- `skills/` is the canonical workflow surface.
- New workflow contributions should land in `skills/` first.
- `commands/` is a legacy slash-entry compatibility surface and should only be added or updated when a shim is still required for migration or cross-harness parity.

## Git Workflow

**Commit format:** `<type>: <description>` — Types: feat, fix, refactor, docs, test, chore, perf, ci

**PR workflow:** Analyze full commit history → draft comprehensive summary → include test plan → push with `-u` flag.

## Architecture Patterns

**API response format:** Consistent envelope with success indicator, data payload, error message, and pagination metadata.

**Repository pattern:** Encapsulate data access behind standard interface (findAll, findById, create, update, delete). Business logic depends on abstract interface, not storage mechanism.

**Skeleton projects:** Search for battle-tested templates, evaluate with parallel agents (security, extensibility, relevance), clone best match, iterate within proven structure.

## Performance

**Context management:** Avoid last 20% of context window for large refactoring and multi-file features. Lower-sensitivity tasks (single edits, docs, simple fixes) tolerate higher utilization.

**Build troubleshooting:** Use build-error-resolver agent → analyze errors → fix incrementally → verify after each fix.

## Project Structure

```
agents/          — 67 specialized subagents
skills/          — 281 workflow skills and domain knowledge
commands/        — 94 slash commands
hooks/           — Trigger-based automations
rules/           — Always-follow guidelines (common + per-language)
scripts/         — Cross-platform Node.js utilities
mcp-configs/     — 14 MCP server configurations
tests/           — Test suite
```

`commands/` remains in the repo for compatibility, but the long-term direction is skills-first.

## Success Metrics

- All tests pass with 80%+ coverage
- No security vulnerabilities
- Code is readable and maintainable
- Performance is acceptable
- User requirements are met


---

# Codex Supplement (From ECC .codex/AGENTS.md)

# ECC for Codex CLI

This supplements the root `AGENTS.md` with Codex-specific guidance.

For repo navigation, surface ownership, and PR diff packet guidance, read
`docs/CODEX-NAVIGATION-GUIDE.md` after this supplement.

## Model Recommendations

| Task Type | Recommended Model |
|-----------|------------------|
| Routine coding, tests, formatting | GPT 5.5 |
| Complex features, architecture | GPT 5.5 |
| Debugging, refactoring | GPT 5.5 |
| Security review | GPT 5.5 |

## Skills Discovery

Skills are auto-loaded from `.agents/skills/`. Each skill contains:
- `SKILL.md` — Detailed instructions and workflow
- `agents/openai.yaml` — Codex interface metadata

Available skills:
- tdd-workflow — Test-driven development with 80%+ coverage
- security-review — Comprehensive security checklist
- coding-standards — Universal coding standards
- frontend-patterns — React/Next.js patterns
- frontend-slides — Viewport-safe HTML presentations and PPTX-to-web conversion
- article-writing — Long-form writing from notes and voice references
- content-engine — Platform-native social content and repurposing
- market-research — Source-attributed market and competitor research
- investor-materials — Decks, memos, models, and one-pagers
- investor-outreach — Personalized investor outreach and follow-ups
- backend-patterns — API design, database, caching
- e2e-testing — Playwright E2E tests
- eval-harness — Eval-driven development
- strategic-compact — Context management
- api-design — REST API design patterns
- verification-loop — Build, test, lint, typecheck, security
- deep-research — Multi-source research with firecrawl and exa MCPs
- exa-search — Neural search via Exa MCP for web, code, and companies
- claude-api — Anthropic Claude API patterns and SDKs
- x-api — X/Twitter API integration for posting, threads, and analytics
- crosspost — Multi-platform content distribution
- fal-ai-media — AI image/video/audio generation via fal.ai
- dmux-workflows — Multi-agent orchestration with dmux

## MCP Servers

Treat the project-local `.codex/config.toml` as the default Codex baseline for ECC. The current ECC baseline enables GitHub, Context7, Exa, Memory, Playwright, and Sequential Thinking; add heavier extras in `~/.codex/config.toml` only when a task actually needs them.

ECC's canonical Codex section name is `[mcp_servers.context7]`. The launcher package remains `@upstash/context7-mcp`; only the TOML section name is normalized for consistency with `codex mcp list` and the reference config.

### Automatic config.toml merging

The sync script (`scripts/sync-ecc-to-codex.sh`) uses a Node-based TOML parser to safely merge ECC MCP servers into `~/.codex/config.toml`:

- **Add-only by default** — missing ECC servers are appended; existing servers are never modified or removed.
- **7 managed servers** — Supabase, Playwright, Context7, Exa, GitHub, Memory, Sequential Thinking.
- **Canonical naming** — ECC manages Context7 as `[mcp_servers.context7]`; legacy `[mcp_servers.context7-mcp]` entries are treated as aliases during updates.
- **Package-manager aware** — uses the project's configured package manager (npm/pnpm/yarn/bun) instead of hardcoding `pnpm`.
- **Drift warnings** — if an existing server's config differs from the ECC recommendation, the script logs a warning.
- **`--update-mcp`** — explicitly replaces all ECC-managed servers with the latest recommended config (safely removes subtables like `[mcp_servers.supabase.env]`).
- **User config is always preserved** — custom servers, args, env vars, and credentials outside ECC-managed sections are never touched.

## External Action Boundaries

Treat networked tools as read-only by default. Search, inspect, and draft freely within the user's requested scope, but require explicit user approval before posting, publishing, pushing, merging, opening paid jobs, dispatching remote agents, changing third-party resources, or modifying credentials.

When approval is ambiguous, produce a local plan or draft artifact instead of taking the external action. Preserve user config and private state unless the user specifically asks for a scoped change.

## Multi-Agent Support

Codex now supports multi-agent workflows behind the experimental `features.multi_agent` flag.

- Enable it in `.codex/config.toml` with `[features] multi_agent = true`
- Define project-local roles under `[agents.<name>]`
- Point each role at a TOML layer under `.codex/agents/`
- Use `/agent` inside Codex CLI to inspect and steer child agents

Sample role configs in this repo:
- `.codex/agents/explorer.toml` — read-only evidence gathering
- `.codex/agents/reviewer.toml` — correctness/security review
- `.codex/agents/docs-researcher.toml` — API and release-note verification

## Key Differences from Claude Code

| Feature | Claude Code | Codex CLI |
|---------|------------|-----------|
| Hooks | 8+ event types | Not yet supported |
| Context file | CLAUDE.md + AGENTS.md | AGENTS.md only |
| Skills | Skills loaded via plugin | `.agents/skills/` directory |
| Commands | `/slash` commands | Instruction-based |
| Agents | Subagent Task tool | Multi-agent via `/agent` and `[agents.<name>]` roles |
| Security | Hook-based enforcement | Instruction + sandbox |
| MCP | Full support | Supported via `config.toml` and `codex mcp add` |

## Security Without Hooks

Since Codex lacks hooks, security enforcement is instruction-based:
1. Always validate inputs at system boundaries
2. Never hardcode secrets — use environment variables
3. Run `npm audit` / `pip audit` before committing
4. Review `git diff` before every push
5. Use `sandbox_mode = "workspace-write"` in config

<!-- END ECC -->
