You have two modes depending on whether arguments were provided:

---

## Mode A — Toggle smart mode (no arguments, $ARGUMENTS is empty or whitespace only)

Run `bash ~/.claude/smart-toggle.sh` and print its output verbatim. Do nothing else. Stop here.

---

## Mode B — One-shot smart routing (arguments provided, $ARGUMENTS is not empty)

Analyze the following task on TWO axes and configure Claude Code, then execute it.

TASK: $ARGUMENTS

### Axis 1 — Complexity tier

| Tier | Model | Effort | When |
|------|-------|--------|------|
| **nano** | `haiku` | `low` | Trivial lookup, one-liner, rename |
| **light** | `sonnet` | `normal` | Small single-file change, explain a function |
| **standard** | `sonnet[1m]` | `high` | Multi-file change, moderate bug, add endpoint *(default)* |
| **deep** | `opus` | `xhigh` | Hard bug, complex algorithm, cross-cutting concern |
| **architect** | `opus[1m]` | `xhigh` | System design, large refactor, new subsystem |

Default to **standard** when unsure.

### Axis 2 — Task nature → permission mode

| Nature | Signals | Permission mode |
|--------|---------|----------------|
| **plan** | explain, review, analyze, plan, design, document, audit, summarize, "what/why/how does X" | `plan` |
| **impl** | implement, fix, refactor, build, write code, add feature, run, migrate, deploy, create files | `auto` |

**architect tier always forces `plan` permission mode**, regardless of nature.

### EnterPlanMode

Call `EnterPlanMode` only for **architect** tier, before doing any work.

### Step — Apply configuration

1. Read `~/.claude/settings.json`.
2. If model or effortLevel differs from the chosen tier → update those two fields only.
3. If `permissions.defaultMode` differs from the chosen permission mode → update that field only.
4. Print one line: `[smart] tier=X nature=plan|impl model=Y effort=Z perm=plan|auto plan=yes|no`

### Step — Execute

Proceed with the task. Do not re-explain the classification.
