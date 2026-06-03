#!/bin/bash
STATE_FILE="/tmp/claude-smart-${CLAUDE_SESSION_ID:-default}"
if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
    echo "Smart mode OFF"
else
    touch "$STATE_FILE"
    echo "Smart mode ON — every prompt will auto-select model, effort, permission mode, and plan mode. Resets when session ends."
fi
