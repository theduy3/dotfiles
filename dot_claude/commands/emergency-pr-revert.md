Emergency PR revert — auto-detects last merged PR, reverts it, pushes, and deploys. Target recovery time: ~5 minutes.

## Step 1: Find last merge commits

Run:
```bash
git log --merges --oneline -5
```

Show the output. Auto-select the MOST RECENT merge commit (first line in the list).

Display clearly:
```
🚨 EMERGENCY REVERT
Last merged commit: <hash> "<message>"
─────────────────────────────────────────
[list of last 5 merge commits shown above]
```

## Step 2: Safety confirmation

Ask the user ONE question:
"Revert commit <hash> ('<message>')? Type YES to proceed, or paste a different hash from the list above."

Wait for their response. If they provide a different hash, use that one instead of the auto-selected one.
If they type anything other than YES or a valid hash, abort and tell them: "Revert cancelled."

## Step 3: Revert

Run:
```bash
git revert -m 1 <confirmed-hash> --no-edit
```

`--no-edit` skips the commit message editor for speed — do not remove this flag.

If a merge conflict occurs: STOP immediately. Do NOT auto-resolve conflicts.
Show the conflicting files and tell the user:
"Conflict in: <files>. Resolve manually, then run: git revert --continue && git push origin HEAD"

## Step 4: Push

Run:
```bash
git push origin HEAD
```

Show the new revert commit hash from the output.

## Step 5: Deploy

Invoke /deploy to trigger production deployment immediately.

## Step 6: Final status report

Show a summary:
```
✅ REVERT COMPLETE
─────────────────────────────────────
Reverted:  <original-hash> "<original-message>"
Revert commit: <new-hash>
Pushed: yes
Deploy: triggered
─────────────────────────────────────
Estimated recovery: depends on your deploy pipeline
```
