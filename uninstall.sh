#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="${CLAUDE_SMART_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "Uninstalling claude-smart-mode..."
rm -f \
  "$CLAUDE_DIR/commands/smart.md" \
  "$CLAUDE_DIR/smart-inject.md" \
  "$CLAUDE_DIR/smart-toggle.sh" \
  "$CLAUDE_DIR/smart-uninstall.sh"

if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "$SETTINGS.smart-uninstall-backup.$(date +%Y%m%d-%H%M%S)"
  python3 - "$SETTINGS" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
settings = json.loads(p.read_text() or "{}")
hooks = settings.get("hooks", {})

for event_name in list(hooks):
    new_entries = []
    for entry in hooks[event_name]:
        entry_hooks = entry.get("hooks", [])
        kept_hooks = [
            hook for hook in entry_hooks
            if "claude-smart" not in str(hook.get("command", ""))
            and "smart-inject.md" not in str(hook.get("command", ""))
        ]
        if kept_hooks:
            entry = dict(entry)
            entry["hooks"] = kept_hooks
            new_entries.append(entry)
    if new_entries:
        hooks[event_name] = new_entries
    else:
        del hooks[event_name]

if hooks:
    settings["hooks"] = hooks
else:
    settings.pop("hooks", None)

p.write_text(json.dumps(settings, indent=2) + "\n")
PY
fi

for SHELL_RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [[ -f "$SHELL_RC" ]] || continue
  python3 - "$SHELL_RC" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
text = p.read_text()
start = "# >>> claude-smart-mode smart alias >>>"
end = "# <<< claude-smart-mode smart alias <<<"
while start in text and end in text:
    a = text.index(start)
    b = text.index(end, a) + len(end)
    if a > 0 and text[a - 1] == "\n":
        a -= 1
    text = text[:a] + text[b:]
text = text.replace("\nalias smart='bash ~/.claude/smart-toggle.sh'\n", "\n")
p.write_text(text)
PY
done

echo "Removed managed command files, hooks, and shell alias."
