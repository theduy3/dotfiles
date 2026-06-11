#!/usr/bin/env node
// Worktree Branch Guard — PreToolUse hook (matcher: Bash)
// Blocks `git commit` when CWD is inside a linked worktree AND the current
// branch is the repo's default (main/master/...). Committing to the default
// branch from inside a feature worktree is a recurring footgun — this enforces
// the "never commit to main in a worktree" rule at the tooling layer.
//
// Action: BLOCK (exit 2) only in the narrow dangerous case (worktree + default branch + git commit).
// No-op (exit 0): non-commit commands, main repo, feature branches, hook errors (fail-open).

const { spawnSync } = require('child_process');
const SPAWNOPT = { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 2000, windowsHide: true };
function git(args, cwd) { return spawnSync('git', args, { ...SPAWNOPT, cwd }); }

// Is this command a `git commit`? Tolerant of `git -C x commit`, `git commit -am`,
// compound commands (`git add . && git commit`). Excludes commit-tree/commit-graph.
function isGitCommit(cmd) {
  if (!/\bgit\b[\s\S]*\bcommit\b/.test(cmd)) return false;
  if (/\bcommit-(tree|graph)\b/.test(cmd)) return false;
  return true;
}

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    if (data.tool_name !== 'Bash') process.exit(0);

    const cmd = data.tool_input?.command || '';
    if (!isGitCommit(cmd)) process.exit(0);

    const cwd = data.cwd || process.cwd();

    // Linked-worktree detection: --git-dir contains .git/worktrees/ as a component.
    const gitDirRes = git(['rev-parse', '--git-dir'], cwd);
    if (gitDirRes.status !== 0 || !gitDirRes.stdout) process.exit(0); // not a repo — pass
    if (!/[/\\]\.git[/\\]worktrees[/\\]/.test(gitDirRes.stdout.trim())) process.exit(0); // main repo — pass

    // Current branch.
    const branchRes = git(['rev-parse', '--abbrev-ref', 'HEAD'], cwd);
    if (branchRes.status !== 0 || !branchRes.stdout) process.exit(0); // detached/unknown — fail open
    const branch = branchRes.stdout.trim();

    // Default branch: prefer origin/HEAD; fall back to the conventional set.
    let defaults = ['main', 'master'];
    const symRes = git(['symbolic-ref', '--short', 'refs/remotes/origin/HEAD'], cwd);
    if (symRes.status === 0 && symRes.stdout) {
      const def = symRes.stdout.trim().replace(/^origin\//, '');
      if (def) defaults = [def];
    }

    if (!defaults.includes(branch)) process.exit(0); // on a feature branch — allow

    // BLOCK: committing to the default branch inside a worktree.
    const output = {
      decision: 'block',
      reason:
        `Worktree branch guard: refusing to commit to '${branch}' inside a linked worktree ` +
        `(cwd: '${cwd}'). Committing to the default branch from a feature worktree is almost ` +
        `always a mistake. Checkout the feature branch first (\`git checkout -b <feature>\`), ` +
        `or commit from the main checkout if this is intentional.`,
    };
    process.stdout.write(JSON.stringify(output));
    process.exit(2);
  } catch {
    process.exit(0); // fail-open — never block on hook error
  }
});
