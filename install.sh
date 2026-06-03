#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "Installing claude-smart-mode..."

# Create commands dir if needed
mkdir -p "$COMMANDS_DIR"

# Copy command and inject files
cp commands/smart.md "$COMMANDS_DIR/smart.md"
cp smart-inject.md "$CLAUDE_DIR/smart-inject.md"
cp smart-toggle.sh "$CLAUDE_DIR/smart-toggle.sh"
chmod +x "$CLAUDE_DIR/smart-toggle.sh"

echo "Copied command files."

# Add shell alias
SHELL_RC="$HOME/.zshrc"
[ -n "$BASH_VERSION" ] && SHELL_RC="$HOME/.bashrc"

if grep -q "alias smart=" "$SHELL_RC" 2>/dev/null; then
  echo "Shell alias already exists in $SHELL_RC, skipping."
else
  echo "\nalias smart='bash ~/.claude/smart-toggle.sh'" >> "$SHELL_RC"
  echo "Added 'smart' alias to $SHELL_RC — run 'source $SHELL_RC' or restart your terminal."
fi

# Patch settings.json with the hooks
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Check if hooks already exist
if grep -q '"UserPromptSubmit"' "$SETTINGS"; then
  echo ""
  echo "WARNING: Your settings.json already has hooks defined."
  echo "Merge the following into $SETTINGS manually:"
  cat hooks-snippet.json
  echo ""
else
  # Use node if available, otherwise python3
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const settings = JSON.parse(fs.readFileSync('$SETTINGS', 'utf8'));
      const hooks = JSON.parse(fs.readFileSync('hooks-snippet.json', 'utf8'));
      settings.hooks = hooks;
      fs.writeFileSync('$SETTINGS', JSON.stringify(settings, null, 2));
    "
  elif command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('$SETTINGS') as f: s = json.load(f)
with open('hooks-snippet.json') as f: h = json.load(f)
s['hooks'] = h
with open('$SETTINGS', 'w') as f: json.dump(s, f, indent=2)
"
  else
    echo "No node or python3 found. Merge hooks-snippet.json into $SETTINGS manually."
    exit 1
  fi
  echo "Hooks added to settings.json."
fi

echo ""
echo "Done! Restart Claude Code, then:"
echo "  /smart          — toggle smart mode ON/OFF for the session"
echo "  /smart <task>   — one-shot smart routing for a single task"
