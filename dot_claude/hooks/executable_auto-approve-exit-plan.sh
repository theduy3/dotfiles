#!/bin/bash
# Auto-approve ExitPlanMode to bypass interactive multi-option select UI.
# Required for Android remote control which only supports binary allow/deny,
# not arrow-key navigable selection menus.
# Always approves with default behavior (continue in same context, manually approve edits).
echo '{"decision": "approve"}'
