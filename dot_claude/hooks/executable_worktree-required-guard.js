#!/usr/bin/env node
// Worktree Required Guard — PreToolUse hook (matcher: Write|Edit|MultiEdit)
// Enforces the "every /s* task runs in a worktree, regardless of scope" rule at the
// tooling layer. Blocks edits to the MAIN checkout while an approved/implementing
// /s* task is active — forcing implementation to happen inside the task's worktree.
//
// Action: BLOCK (exit 2) ONLY when ALL of these hold:
//   - tool is Write/Edit/MultiEdit
//   - cwd is a git repo's MAIN checkout (NOT a linked worktree)
//   - a tasks/todo-*.md exists with status: plan-approved | implementing
//   - the target file is inside the repo AND NOT under tasks/
// No-op (exit 0) otherwise, and on ANY error (fail-open). This narrowness means
// ad-hoc editing is never blocked: no active task → pass; ~ (not a git repo) → pass;
// already in a worktree → pass; editing the plan/spec under tasks/ → pass.

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const SPAWNOPT = { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 2000, windowsHide: true };
function git(args, cwd) { return spawnSync('git', args, { ...SPAWNOPT, cwd }); }
// Canonicalize a path (resolve symlinks like /var → /private/var on macOS). Returns
// the input unchanged if it can't be resolved (e.g. doesn't exist yet).
function realOrSelf(p) { try { return fs.realpathSync(p); } catch { return p; } }

const EDIT_TOOLS = new Set(['Write', 'Edit', 'MultiEdit']);
// Matches the s1 metadata block fields, one per line, inside its HTML comment.
const ACTIVE_STATUS = /^\s*status:\s*(plan-approved|implementing)\b/im;

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    if (!EDIT_TOOLS.has(data.tool_name)) process.exit(0);

    // Write/Edit/MultiEdit all carry the target under tool_input.file_path.
    const target = data.tool_input?.file_path;
    if (!target) process.exit(0);
    const cwd = data.cwd || process.cwd();

    // Must be a git repo — else pass (e.g. cwd is ~, which is not a repo).
    const gitDirRes = git(['rev-parse', '--git-dir'], cwd);
    if (gitDirRes.status !== 0 || !gitDirRes.stdout) process.exit(0);

    // Already inside a linked worktree → exactly the desired state → pass.
    // (Same detection as worktree-branch-guard.js: .git/worktrees/ in the git-dir path.)
    if (/[/\\]\.git[/\\]worktrees[/\\]/.test(gitDirRes.stdout.trim())) process.exit(0);

    // Main checkout. Resolve repo root.
    const topRes = git(['rev-parse', '--show-toplevel'], cwd);
    if (topRes.status !== 0 || !topRes.stdout) process.exit(0);
    const repoRoot = realOrSelf(topRes.stdout.trim());

    // Is there an active /s* task? Scan <repoRoot>/tasks/todo-*.md for an active status.
    const tasksDir = path.join(repoRoot, 'tasks');
    let files;
    try { files = fs.readdirSync(tasksDir); } catch { process.exit(0); } // no tasks/ → pass
    let activeFile = '';
    for (const f of files) {
      if (!/^todo-.*\.md$/.test(f)) continue;
      let body = '';
      try { body = fs.readFileSync(path.join(tasksDir, f), 'utf8'); } catch { continue; }
      if (ACTIVE_STATUS.test(body)) { activeFile = f; break; }
    }
    if (!activeFile) process.exit(0); // no approved/implementing task → not our business

    // Exemptions: edits to the plan/spec/todo themselves, and edits outside the repo.
    // Canonicalize the target so a symlinked cwd (e.g. /var → /private/var) still
    // compares correctly against git's canonical repoRoot. The file may not exist yet
    // (Write), so resolve symlinks on its existing parent dir, then rejoin the basename.
    const resolved = path.resolve(realOrSelf(cwd), target);
    const absTarget = path.join(realOrSelf(path.dirname(resolved)), path.basename(resolved));
    const insideRepo = absTarget === repoRoot || absTarget.startsWith(repoRoot + path.sep);
    if (!insideRepo) process.exit(0); // editing outside the repo is not "implementing into main"
    if (absTarget.startsWith(tasksDir + path.sep)) process.exit(0); // plan/spec/todo edits allowed

    // BLOCK: implementing into the MAIN checkout while a worktree task is active.
    const output = {
      decision: 'block',
      reason:
        `Worktree required: an approved /s* task is active (tasks/${activeFile}) but you are in the ` +
        `MAIN checkout (cwd: '${cwd}'), not its worktree. Every /s* task runs in a worktree — no ` +
        `matter the scope. EnterWorktree (or cd into the linked worktree) before editing ` +
        `'${target}'. Editing tasks/ (the plan/spec) and files outside the repo is still allowed.`,
    };
    process.stdout.write(JSON.stringify(output));
    process.exit(2);
  } catch {
    process.exit(0); // fail-open — never block on hook error
  }
});
