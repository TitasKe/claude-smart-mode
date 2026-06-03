You have three modes depending on whether arguments were provided:

---

## Mode A — Toggle smart mode (no arguments, $ARGUMENTS is empty or whitespace only)

Run `bash ~/.claude/smart-toggle.sh` and print its output verbatim. Do nothing else. Stop here.

---

## Mode B — Maintenance commands

If `$ARGUMENTS` is one of these command forms, run the matching shell command, print its output verbatim, do nothing else, and stop:

| Arguments | Command |
|---|---|
| `status` | `bash ~/.claude/smart-toggle.sh status` |
| `doctor` | `bash ~/.claude/smart-toggle.sh doctor` |
| `models` | `bash ~/.claude/smart-toggle.sh models` |
| `config init` | `bash ~/.claude/smart-toggle.sh config init` |
| `config show` | `bash ~/.claude/smart-toggle.sh config show` |
| `config path` | `bash ~/.claude/smart-toggle.sh config path` |
| `release-check` | `bash ~/.claude/smart-toggle.sh release-check` |
| `uninstall` | `bash ~/.claude/smart-toggle.sh uninstall` |
| `--why <task>` | `bash ~/.claude/smart-toggle.sh --why "<task>"` |
| `why <task>` | `bash ~/.claude/smart-toggle.sh why "<task>"` |

---

## Mode C — One-shot smart routing (arguments provided, $ARGUMENTS is not empty)

Analyze the following task on TWO axes and configure Claude Code, then execute it.

TASK: $ARGUMENTS

Before classifying, read `~/.claude/smart-config.md` if it exists and apply any routing preferences from it when they do not conflict with this command.

### Axis 1 — Complexity tier

| Tier | Model | Effort | When |
|------|-------|--------|------|
| **nano** | `haiku` | `low` | Trivial lookup, one-liner, rename |
| **light** | `sonnet` | `normal` | Small single-file change, explain a function |
| **standard** | `sonnet[1m]` | `high` | Multi-file change, moderate bug, add endpoint *(default)* |
| **deep** | `opus` | `xhigh` | Hard bug, complex algorithm, cross-cutting concern |
| **architect** | `opus[1m]` | `xhigh` | System design, large refactor, new subsystem |
| **ultracode** | `opus[1m]` | `xhigh` | Dynamic workflow mode for complex multi-workstream tasks |

Default to **standard** when unsure.

### Axis 2 — Task nature → permission mode

| Nature | Signals | Permission mode |
|--------|---------|----------------|
| **plan** | explain, review, analyze, plan, design, document, audit, summarize, "what/why/how does X" | `plan` |
| **impl** | implement, fix, refactor, build, write code, add feature, run, migrate, deploy, create files | `auto` |

**architect and ultracode tiers always force `plan` permission mode**, regardless of nature.

Choose **ultracode** when the task explicitly mentions ultracode, dynamic workflow, orchestration, many subagents, or a complex task that clearly benefits from parallel workstreams. When tier is ultracode, read `~/.claude/ultracode-inject.md` if it exists and follow it.

### EnterPlanMode

Call `EnterPlanMode` for **architect** tier, and for **ultracode** tier when a dynamic workflow is warranted.

### Step — Apply configuration

1. Read `~/.claude/settings.json`.
2. If model or effortLevel differs from the chosen tier → update those two fields only.
3. If `permissions.defaultMode` differs from the chosen permission mode → update that field only.
4. Print one line: `[smart] tier=X nature=plan|impl model=Y effort=Z perm=plan|auto plan=yes|no dynamic_workflow=yes|no|auto`

### Step — Execute

Proceed with the task. Do not re-explain the classification.
