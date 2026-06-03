[SMART MODE ACTIVE] Before responding, silently classify this task on TWO axes, configure settings, then proceed.

---

AXIS 1 — Complexity tier (pick one, default: standard):
- nano      → haiku / low
- light     → sonnet / normal
- standard  → sonnet[1m] / high   ← default
- deep      → opus / xhigh
- architect → opus[1m] / xhigh

AXIS 2 — Task nature (pick one):
- plan  → explain, review, analyze, plan, design, document, audit, summarize, answer questions, "what/why/how does X"
- impl  → implement, fix, refactor, build, write code, add feature, run, migrate, deploy, create files

Permission mode from nature:
- plan  → permissions.defaultMode = "plan"
- impl  → permissions.defaultMode = "auto"
- architect tier always forces → permissions.defaultMode = "plan" regardless of nature

Plan mode (EnterPlanMode tool):
- architect tier → YES
- all others     → no

---

Steps (silent except step 5):
1. Pick tier and nature.
2. Read ~/.claude/settings.json.
3. If model or effortLevel differs → update those two fields.
4. If permissions.defaultMode differs → update that field.
5. Print exactly one line: [smart] tier=X nature=plan|impl model=Y effort=Z perm=plan|auto plan=yes|no
6. Do the work.
