#!/usr/bin/env node
// GSD Phase Worktree Guard — PreToolUse (matcher: Write|Edit|MultiEdit)
// Forces GSD phase execution into a worktree by blocking SOURCE writes to the MAIN
// checkout while .planning/STATE.md reports `status: executing`.
//
// BLOCK (exit 2) only when ALL hold:
//   - tool is Write/Edit/MultiEdit
//   - cwd is a git repo MAIN checkout (NOT a linked worktree)
//   - <repoRoot>/.planning/STATE.md frontmatter has `status: executing`
//   - target is inside the repo, NOT under .planning/ and NOT under tasks/
//   - GSD_ALLOW_INLINE is unset (escape hatch for Pattern-C / gap-closure plans)
// No-op (exit 0) otherwise and on ANY error (fail-open).

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const SPAWNOPT = { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 2000, windowsHide: true };
function git(args, cwd) { return spawnSync('git', args, { ...SPAWNOPT, cwd }); }
function realOrSelf(p) { try { return fs.realpathSync(p); } catch { return p; } }

const EDIT_TOOLS = new Set(['Write', 'Edit', 'MultiEdit']);
// `status:` line inside the leading YAML frontmatter, value exactly `executing`.
const EXECUTING = /^\s*status:\s*executing\s*$/im;

// macOS/Windows filesystems are case-insensitive, but git emits the on-disk
// canonical case (e.g. /Users/x/Repo) while the harness may pass cwd/file_path in a
// different case (/Users/x/repo). String prefix checks must be case-folded there, or
// the insideRepo/exempt comparisons silently fail and the guard never fires (#caseskew).
const CASE_INSENSITIVE = process.platform === 'darwin' || process.platform === 'win32';
function norm(p) { return CASE_INSENSITIVE ? p.toLowerCase() : p; }
function isUnder(child, parentDir) { return norm(child).startsWith(norm(parentDir) + path.sep); }

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', c => (input += c));
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    // Escape hatch: knowingly running a Pattern-C / gap-closure inline plan.
    if (process.env.GSD_ALLOW_INLINE) process.exit(0);

    const data = JSON.parse(input);
    if (!EDIT_TOOLS.has(data.tool_name)) process.exit(0);

    const target = data.tool_input?.file_path;
    if (!target) process.exit(0);
    const cwd = data.cwd || process.cwd();

    // Must be a git repo (cwd ~ is not) → else pass.
    const gitDir = git(['rev-parse', '--git-dir'], cwd);
    if (gitDir.status !== 0 || !gitDir.stdout) process.exit(0);

    // Already inside a linked worktree → desired state → pass.
    if (/[/\\]\.git[/\\]worktrees[/\\]/.test(gitDir.stdout.trim())) process.exit(0);

    // Main checkout. Resolve repo root.
    const top = git(['rev-parse', '--show-toplevel'], cwd);
    if (top.status !== 0 || !top.stdout) process.exit(0);
    const repoRoot = realOrSelf(top.stdout.trim());

    // Is a GSD phase mid-execution? Read STATE.md frontmatter.
    const statePath = path.join(repoRoot, '.planning', 'STATE.md');
    let state = '';
    try { state = fs.readFileSync(statePath, 'utf8'); } catch { process.exit(0); } // no STATE → pass
    // Only inspect the frontmatter block (between the first two `---` fences).
    const fm = state.split(/^---\s*$/m)[1] || '';
    if (!EXECUTING.test(fm)) process.exit(0); // not executing → not our business

    // Resolve absolute target (may not exist yet → resolve parent, rejoin basename).
    const resolved = path.resolve(realOrSelf(cwd), target);
    const absTarget = path.join(realOrSelf(path.dirname(resolved)), path.basename(resolved));
    const insideRepo = norm(absTarget) === norm(repoRoot) || isUnder(absTarget, repoRoot);
    if (!insideRepo) process.exit(0);

    // Exempt orchestrator bookkeeping + plan/spec files.
    if (isUnder(absTarget, path.join(repoRoot, '.planning'))) process.exit(0);
    if (isUnder(absTarget, path.join(repoRoot, 'tasks'))) process.exit(0);

    // BLOCK: source write into MAIN checkout during phase execution.
    process.stdout.write(JSON.stringify({
      decision: 'block',
      reason:
        `GSD worktree required: STATE.md reports status: executing but you are writing '${target}' ` +
        `in the MAIN checkout (cwd: '${cwd}'), not a worktree. Phase execution must run in an ` +
        `isolated worktree. Spawn the executor with Agent(subagent_type="gsd-executor", ` +
        `isolation="worktree"), or EnterWorktree before editing. ` +
        `If this is an INTENDED inline plan (Decision-checkpoint Pattern C, or a gap-closure with ` +
        `no PLAN), set GSD_ALLOW_INLINE=1 for this session to authorize main-checkout writes. ` +
        `Writes under .planning/ and tasks/ are always allowed.`,
    }));
    process.exit(2);
  } catch {
    process.exit(0); // fail-open — never crash the event
  }
});
