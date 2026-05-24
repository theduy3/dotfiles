Preview the app locally:
1. Detect package manager: if `bun.lock` exists use `bun`, otherwise use `npm` (call it $PM)
2. Run `$PM install` if node_modules doesn't exist
3. Run `$PM run dev` to start the dev server
4. Tell the user to open the URL in their browser
5. Ask if the UI looks correct
6. If not, ask what needs to be fixed
7. After fixes are applied, re-run /s3-verify-app to confirm nothing broke, then re-check the preview
