Commit, push, and create a PR:
1. Run `git status` and `git diff --stat` to understand scope
2. **GitNexus impact check**: If repo indexed (`gitnexus status`), run `detect_changes` MCP tool on uncommitted changes. Warn if unexpected flows affected. Include summary in commit body. Skip silently if not indexed.
3. Invoke `superpowers:requesting-code-review` on changed files. Follow `superpowers:receiving-code-review` discipline. Fix CRITICAL issues. For HIGH issues: auto-fix if `CLAUDE_REMOTE=1`, otherwise list and ask.
4. **Silent failure review**: Invoke `pr-review-toolkit:silent-failure-hunter` on changed files. Fix any silent failures, swallowed errors, or bad fallbacks before staging.
5. Stage all changes: `git add .`
6. Write a clear commit message based on the changes
7. Push to the current branch
8. Create a PR with `gh pr create --fill`
9. Show the PR URL
