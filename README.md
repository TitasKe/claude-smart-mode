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

## Install

```bash
git clone https://github.com/TitasSul/claude-smart-mode.git
cd claude-smart-mode
chmod +x install.sh
./install.sh
```

Then restart Claude Code.

## Manual install

1. Copy `commands/smart.md` → `~/.claude/commands/smart.md`
2. Copy `smart-inject.md` → `~/.claude/smart-inject.md`
3. Merge `hooks-snippet.json` into the `"hooks"` key of `~/.claude/settings.json`

## How it works

- `/smart` (toggle) creates/deletes `/tmp/claude-smart-<session-id>` — a session-scoped flag file
- A `UserPromptSubmit` hook checks for that file on every prompt; if present, injects `smart-inject.md` as context
- A `Stop` hook cleans up the flag file when the session ends, so new sessions always start with smart mode OFF
- When smart mode picks a different model/effort than your current settings, it patches `~/.claude/settings.json` directly (model + effortLevel only)

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `node` or `python3` (for the installer's JSON patching)
