Merge the current branch's PR:
1. Run `gh pr view` to confirm the PR
2. Run `gh pr checks` — if any checks are failing or pending, STOP. Do not merge. Report which checks failed and wait for resolution.
3. Detect if in a worktree (`git rev-parse --git-common-dir` vs `git rev-parse --git-dir` — if they differ, you're in a worktree). If in a worktree, run `gh pr merge --squash` (without `--delete-branch`). If NOT in a worktree, run `gh pr merge --squash --delete-branch`.
4. Confirm the merge was successful
5. Watch deploy workflow: sleep 10 seconds, then `gh run list --workflow=deploy.yml --branch=main --limit=1 --json databaseId,status,conclusion`. If a run is found with status "in_progress" or "queued", watch it: `gh run watch <run-id> --exit-status` (cancel if it runs longer than 10 min). Exit 0 → "Deploy succeeded ✓". Exit 1 → "Deploy FAILED" + `gh run view <run-id> --web`. Cancelled/timed out after 10 min → "Deploy timed out after 10 min" with link. If no run found, warn: "No deploy workflow detected — check GitHub Actions manually"
