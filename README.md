# claude-smart-mode

A `/smart` command for [Claude Code](https://claude.ai/code) that automatically selects the best model, effort level, and plan mode for each task — saving tokens on simple tasks and upgrading automatically for complex ones.

## What it does

### Session toggle
```
/smart        → Smart mode ON  (persists for this session, resets on close)
/smart        → Smart mode OFF
```

When ON, every prompt is classified on **two axes** before Claude responds:

**Axis 1 — Complexity tier** (controls model + effort):

| Tier | Model | Effort | When |
|------|-------|--------|------|
| nano | haiku | low | Trivial lookups, one-liners |
| light | sonnet | normal | Small single-file changes |
| standard | sonnet[1m] | high | Multi-file work *(default)* |
| deep | opus | xhigh | Hard bugs, complex reasoning |
| architect | opus[1m] | xhigh | System design, large refactors |
| ultracode | opus[1m] | xhigh | Dynamic workflow orchestration for complex tasks |

**Axis 2 — Task nature** (controls permission mode):

| Nature | Signals | Permission mode |
|--------|---------|----------------|
| plan | explain, review, analyze, plan, design, document, audit | `--permission-mode plan` |
| impl | implement, fix, build, write code, run, migrate, deploy | `--permission-mode auto` |

`architect` tier always forces `plan` permission mode regardless of nature.

Each response starts with a single line like:
```
[smart] tier=standard nature=impl model=sonnet[1m] effort=high perm=auto plan=no
```

### One-shot (no toggle)
```
/smart refactor the auth module to use JWT
```
Runs smart routing on that task only, without affecting the session toggle.

### Maintenance commands
```
/smart doctor
/smart status
/smart --why "fix auth bug in production"
/smart models
/smart config init
/smart release-check
```

### Ultracode effort
```
/effort ultracode
```

`ultracode` is an xhigh effort mode that lets Claude decide whether a task warrants a dynamic workflow. When it does, Claude acts as the orchestrator, writes a short orchestration brief, and can fan out focused workstreams to subagents before merging and verifying the final result.

Use it for genuinely complex tasks: large refactors, hard bugs, security/auth work, migrations, release work, broad audits, and tasks that benefit from parallel investigation. It intentionally avoids dynamic workflows for small edits and simple questions.

Turn it off:
```
/effort off
```

Shell alias equivalents:
```
smart doctor
smart status
smart why "fix auth bug in production"
smart models
smart config init
smart effort ultracode
smart release-check
smart uninstall
```

## Install

```bash
git clone https://github.com/TitasKe/claude-smart-mode.git
cd claude-smart-mode
chmod +x install.sh
./install.sh
```

Then restart your terminal and Claude Code.

After install you get two ways to toggle:

| Method | Where | Speed |
|--------|-------|-------|
| `smart` (shell alias) | any terminal | instant — no Claude involved |
| `/smart` (slash command) | inside Claude Code | fast — single bash call |
| `/effort ultracode` | inside Claude Code | toggles dynamic workflow mode |

## Manual install

1. Copy `commands/smart.md` → `~/.claude/commands/smart.md`
2. Copy `smart-inject.md` → `~/.claude/smart-inject.md`
3. Copy `smart-toggle.sh` → `~/.claude/smart-toggle.sh` and `chmod +x` it
3. Merge `hooks-snippet.json` into the `"hooks"` key of `~/.claude/settings.json`

## How it works

- `/smart` (toggle) creates/deletes `/tmp/claude-smart-<session-id>` — a session-scoped flag file
- A `UserPromptSubmit` hook checks for that file on every prompt; if present, injects `smart-inject.md` as context
- `/effort ultracode` creates/deletes `/tmp/claude-smart-ultracode-<session-id>` and injects `ultracode-inject.md`
- A `Stop` hook cleans up the flag file when the session ends, so new sessions always start with smart mode OFF
- When smart mode picks a different model/effort than your current settings, it patches `~/.claude/settings.json` directly (model + effortLevel only)
- `install.sh` safely merges the managed hooks into existing Claude settings and writes a timestamped backup before editing
- `smart release-check` verifies shell syntax, obvious secret patterns, and git author metadata before publishing

## Config

Run:
```
smart config init
```

This creates:
```
~/.claude/smart-config.env
~/.claude/smart-config.md
```

`smart-config.env` customizes shell-side model mappings:
```
NANO_MODEL=haiku
LIGHT_MODEL=sonnet
STANDARD_MODEL=sonnet[1m]
DEEP_MODEL=opus
ARCHITECT_MODEL=opus[1m]
ULTRACODE_MODEL=opus[1m]
ULTRACODE_SUBAGENT_LIMIT=8
```

`smart-config.md` is injected alongside smart mode so you can add personal routing preferences.

## Uninstall

```
smart uninstall
```

The uninstaller removes only the managed smart-mode command files, managed hook entries, and managed shell alias. It writes a settings backup before changing `~/.claude/settings.json`.

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `python3` (for safe JSON hook merging)
