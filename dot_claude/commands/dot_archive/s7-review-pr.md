---
context: fork
---
Review the current branch's PR:
1. Run `gh pr view` to show PR details
2. Run `gh pr checks` — show CI status, note any failures prominently
3. Run the /pr-review-toolkit:review-pr skill to perform comprehensive review covering:
   - Code quality and adherence to CLAUDE.md
   - Test coverage gaps
   - Silent failure patterns and error handling
   - Comment accuracy
   If the project uses TypeScript, also review type design quality.
4. Aggregate results into: APPROVE or REQUEST CHANGES with prioritized findings
   (Critical → Important → Suggestions)
5. If REQUEST CHANGES: list specific issues with file:line references,
   then say "After fixing, re-run /s3-verify-app and /s7-review-pr to confirm"
