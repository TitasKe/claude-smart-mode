#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "Installing claude-smart-mode..."
mkdir -p "$COMMANDS_DIR"

install -m 644 "$SCRIPT_DIR/commands/smart.md" "$COMMANDS_DIR/smart.md"
install -m 644 "$SCRIPT_DIR/commands/effort.md" "$COMMANDS_DIR/effort.md"
install -m 644 "$SCRIPT_DIR/smart-inject.md" "$CLAUDE_DIR/smart-inject.md"
install -m 644 "$SCRIPT_DIR/ultracode-inject.md" "$CLAUDE_DIR/ultracode-inject.md"
install -m 755 "$SCRIPT_DIR/smart-toggle.sh" "$CLAUDE_DIR/smart-toggle.sh"
install -m 755 "$SCRIPT_DIR/uninstall.sh" "$CLAUDE_DIR/smart-uninstall.sh"

if [[ ! -f "$CLAUDE_DIR/smart-config.env" ]]; then
  install -m 644 "$SCRIPT_DIR/smart-config.env" "$CLAUDE_DIR/smart-config.env"
fi
if [[ ! -f "$CLAUDE_DIR/smart-config.md" ]]; then
  install -m 644 "$SCRIPT_DIR/smart-config.md" "$CLAUDE_DIR/smart-config.md"
fi

echo "Copied command files."

SMART_ALIAS_START="# >>> claude-smart-mode smart alias >>>"
for SHELL_RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [[ -f "$SHELL_RC" ]] && grep -q "$SMART_ALIAS_START" "$SHELL_RC"; then
    echo "Shell smart alias already exists in $SHELL_RC"
  elif grep -q "alias smart='bash ~/.claude/smart-toggle.sh'" "$SHELL_RC" 2>/dev/null; then
    echo "Legacy smart alias already exists in $SHELL_RC"
  else
    cat >> "$SHELL_RC" <<'EOF'

# >>> claude-smart-mode smart alias >>>
alias smart='bash ~/.claude/smart-toggle.sh'
# <<< claude-smart-mode smart alias <<<
EOF
    echo "Added 'smart' alias to $SHELL_RC"
  fi
done

if [[ ! -f "$SETTINGS" ]]; then
  echo '{}' > "$SETTINGS"
fi

cp "$SETTINGS" "$SETTINGS.smart-backup.$(date +%Y%m%d-%H%M%S)"

python3 - "$SETTINGS" "$SCRIPT_DIR/hooks-snippet.json" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
snippet_path = Path(sys.argv[2])

settings = json.loads(settings_path.read_text() or "{}")
snippet = json.loads(snippet_path.read_text())
settings.setdefault("hooks", {})

for event_name, entries in snippet.items():
    target_entries = settings["hooks"].setdefault(event_name, [])
    existing_commands = {
        hook.get("command")
        for entry in target_entries
        for hook in entry.get("hooks", [])
        if isinstance(hook, dict)
    }
    for entry in entries:
        hooks = entry.get("hooks", [])
        commands = [hook.get("command") for hook in hooks if isinstance(hook, dict)]
        if any(command in existing_commands for command in commands):
            continue
        target_entries.append(entry)
        existing_commands.update(command for command in commands if command)

settings_path.write_text(json.dumps(settings, indent=2) + "\n")
PY

echo "Merged managed hooks into $SETTINGS."
echo
echo "Done. Restart Claude Code, then:"
echo "  /smart                  - toggle smart mode ON/OFF for the session"
echo "  /smart <task>           - one-shot smart routing for a single task"
echo "  /effort ultracode       - toggle ultracode dynamic workflow mode"
echo "  smart doctor            - check install health"
echo "  smart --why \"task\"      - explain route selection"
