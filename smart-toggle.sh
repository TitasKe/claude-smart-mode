#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="${CLAUDE_SMART_DIR:-$HOME/.claude}"
CONFIG_ENV="$CLAUDE_DIR/smart-config.env"
CONFIG_MD="$CLAUDE_DIR/smart-config.md"
SETTINGS="$CLAUDE_DIR/settings.json"
STATE_FILE="/tmp/claude-smart-${CLAUDE_SESSION_ID:-default}"
ULTRACODE_STATE_FILE="/tmp/claude-smart-ultracode-${CLAUDE_SESSION_ID:-default}"

NANO_MODEL="haiku"
LIGHT_MODEL="sonnet"
STANDARD_MODEL="sonnet[1m]"
DEEP_MODEL="opus"
ARCHITECT_MODEL="opus[1m]"
ULTRACODE_MODEL="opus[1m]"
ULTRACODE_SUBAGENT_LIMIT="8"

usage() {
  cat <<'EOF'
Usage:
  smart                    Toggle Claude smart mode for this session.
  smart status             Show install/status details.
  smart doctor             Check install health.
  smart why "task"         Explain route selection without running Claude.
  smart models             Show configured tier model mapping.
  smart config init|show|path
  smart effort ultracode     Toggle ultracode dynamic workflow mode.
  smart effort status        Show effort state.
  smart release-check      Check repo readiness before publishing.
  smart uninstall          Remove installed files and managed hooks.
EOF
}

load_config() {
  [[ -f "$CONFIG_ENV" ]] || return 0
  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    [[ "$line" == *"="* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    key="${key//[[:space:]]/}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    value="${value%\"}"
    value="${value#\"}"
    case "$key" in
      NANO_MODEL) NANO_MODEL="$value" ;;
      LIGHT_MODEL) LIGHT_MODEL="$value" ;;
      STANDARD_MODEL) STANDARD_MODEL="$value" ;;
      DEEP_MODEL) DEEP_MODEL="$value" ;;
      ARCHITECT_MODEL) ARCHITECT_MODEL="$value" ;;
      ULTRACODE_MODEL) ULTRACODE_MODEL="$value" ;;
      ULTRACODE_SUBAGENT_LIMIT) ULTRACODE_SUBAGENT_LIMIT="$value" ;;
    esac
  done < "$CONFIG_ENV"
}

toggle() {
  if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
    echo "Smart mode OFF"
  else
    touch "$STATE_FILE"
    echo "Smart mode ON - every prompt will auto-select model, effort, permission mode, and plan mode. Resets when session ends."
  fi
}

effort_cmd() {
  local sub="${1:-status}"
  case "$sub" in
    ultracode)
      if [[ -f "$ULTRACODE_STATE_FILE" ]]; then
        rm "$ULTRACODE_STATE_FILE"
        echo "Ultracode OFF"
      else
        touch "$ULTRACODE_STATE_FILE"
        echo "Ultracode ON - Claude will run at xhigh and decide when complex tasks warrant a dynamic workflow with coordinated subagents."
      fi
      ;;
    off)
      rm -f "$ULTRACODE_STATE_FILE"
      echo "Ultracode OFF"
      ;;
    status)
      echo "smart=$([[ -f "$STATE_FILE" ]] && echo ON || echo OFF)"
      echo "ultracode=$([[ -f "$ULTRACODE_STATE_FILE" ]] && echo ON || echo OFF)"
      ;;
    *)
      echo "Usage: smart effort ultracode|off|status" >&2
      return 2
      ;;
  esac
}

status() {
  echo "claude-smart-mode"
  echo "  state:    $([[ -f "$STATE_FILE" ]] && echo ON || echo OFF)"
  echo "  ultra:    $([[ -f "$ULTRACODE_STATE_FILE" ]] && echo ON || echo OFF)"
  echo "  settings: $SETTINGS"
  echo "  config:   $CONFIG_ENV"
  echo "  prompt:   $CONFIG_MD"
  echo
  usage
}

doctor_check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   $label"
    return 0
  fi
  echo "fail $label"
  return 1
}

doctor() {
  local failed=0
  echo "claude-smart doctor"
  doctor_check "claude command is available" command -v claude || failed=1
  doctor_check "smart-toggle.sh syntax" bash -n "${BASH_SOURCE[0]}" || failed=1
  [[ -f "$CLAUDE_DIR/commands/smart.md" ]] && echo "ok   slash command installed" || { echo "fail slash command missing"; failed=1; }
  [[ -f "$CLAUDE_DIR/smart-inject.md" ]] && echo "ok   smart injection prompt installed" || { echo "fail smart injection prompt missing"; failed=1; }
  [[ -f "$SETTINGS" ]] && echo "ok   settings file exists" || echo "warn settings file does not exist yet"
  if [[ -f "$SETTINGS" ]] && grep -q 'claude-smart' "$SETTINGS"; then
    echo "ok   managed hooks are present"
  else
    echo "warn managed hooks not found in settings"
  fi
  [[ -f "$CONFIG_ENV" ]] && echo "ok   config env exists" || echo "info config env not found; run: smart config init"
  [[ -f "$CLAUDE_DIR/commands/effort.md" ]] && echo "ok   /effort command installed" || echo "warn /effort command missing"
  [[ -f "$CLAUDE_DIR/ultracode-inject.md" ]] && echo "ok   ultracode injection prompt installed" || echo "warn ultracode injection prompt missing"
  return "$failed"
}

why() {
  load_config
  local prompt="${*:-}"
  local prompt_lc
  prompt_lc="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')"
  local tier="standard"
  local nature="impl"
  local model="$STANDARD_MODEL"
  local effort="high"
  local perm="auto"
  local plan="no"
  local dynamic="no"
  local reasons=()

  [[ "$prompt_lc" =~ (explain|what\ does|what\ is|why\ does|how\ does|summari[sz]e|review|audit|analy[sz]e|plan|design|document|docs) ]] && nature="plan" && reasons+=("nature=plan matched analysis/review/documentation signals")
  [[ "$prompt_lc" =~ (fix|implement|add|change|update|build|run|test|debug|deploy|install|create|refactor) ]] && nature="impl" && reasons+=("nature=impl matched implementation signals")
  [[ "$prompt_lc" =~ (typo|spelling|format|rename|one-line|simple|quick|trivial) ]] && tier="nano" && reasons+=("tier=nano matched trivial signals")
  [[ "$prompt_lc" =~ (small|single-file|one\ file) ]] && tier="light" && reasons+=("tier=light matched small task signals")
  [[ "$prompt_lc" =~ (hard|complex|security|auth|login|production|deploy|migration|billing|stripe|database) ]] && tier="deep" && reasons+=("tier=deep matched high-risk/deep-work signals")
  [[ "$prompt_lc" =~ (architecture|architect|system\ design|large\ refactor|new\ subsystem) ]] && tier="architect" && nature="plan" && reasons+=("tier=architect matched architecture signals")
  [[ "$prompt_lc" =~ (ultracode|dynamic\ workflow|subagents|sub-agents|orchestrat) ]] && tier="ultracode" && nature="plan" && reasons+=("tier=ultracode matched dynamic workflow/subagent signals")

  case "$tier" in
    nano) model="$NANO_MODEL"; effort="low" ;;
    light) model="$LIGHT_MODEL"; effort="normal" ;;
    standard) model="$STANDARD_MODEL"; effort="high" ;;
    deep) model="$DEEP_MODEL"; effort="xhigh" ;;
    architect) model="$ARCHITECT_MODEL"; effort="xhigh"; plan="yes" ;;
    ultracode) model="$ULTRACODE_MODEL"; effort="xhigh"; plan="yes"; dynamic="yes-if-warranted" ;;
  esac
  [[ "$nature" == "plan" ]] && perm="plan"

  echo "[smart] tier=$tier nature=$nature model=$model effort=$effort perm=$perm plan=$plan dynamic_workflow=$dynamic"
  echo "why:"
  if [[ ${#reasons[@]} -eq 0 ]]; then
    echo "  - default route"
  else
    printf '  - %s\n' "${reasons[@]}"
  fi
}

models() {
  load_config
  cat <<EOF
nano       $NANO_MODEL       low
light      $LIGHT_MODEL      normal
standard   $STANDARD_MODEL   high
deep       $DEEP_MODEL       xhigh
architect  $ARCHITECT_MODEL  xhigh
ultracode  $ULTRACODE_MODEL  xhigh dynamic-workflow-auto
EOF
}

config_init() {
  mkdir -p "$CLAUDE_DIR"
  if [[ ! -f "$CONFIG_ENV" ]]; then
    cat > "$CONFIG_ENV" <<'EOF'
# claude-smart-mode config
NANO_MODEL=haiku
LIGHT_MODEL=sonnet
STANDARD_MODEL=sonnet[1m]
DEEP_MODEL=opus
ARCHITECT_MODEL=opus[1m]
ULTRACODE_MODEL=opus[1m]
ULTRACODE_SUBAGENT_LIMIT=8
EOF
    echo "Created $CONFIG_ENV"
  else
    echo "Config already exists: $CONFIG_ENV"
  fi

  if [[ ! -f "$CONFIG_MD" ]]; then
    cat > "$CONFIG_MD" <<'EOF'
[SMART MODE USER CONFIG]
Use the default tier table unless this file is edited.
EOF
    echo "Created $CONFIG_MD"
  fi
}

config_cmd() {
  case "${1:-}" in
    init) config_init ;;
    path) echo "$CONFIG_ENV" ;;
    show)
      [[ -f "$CONFIG_ENV" ]] && sed -n '1,220p' "$CONFIG_ENV" || echo "No config at $CONFIG_ENV"
      ;;
    *) echo "Usage: smart config init|show|path" ;;
  esac
}

release_check() {
  local failed=0
  local root
  local p1 p2 p3 p4 p5 p6 p7 secret_re
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
  p1="gh"; p1="${p1}o_"
  p2="gh"; p2="${p2}p_"
  p3="github"; p3="${p3}_pat_"
  p4="sk"; p4="${p4}-[A-Za-z0-9]{20,}"
  p5="OPENAI"; p5="${p5}_API_KEY="
  p6="ANTHROPIC"; p6="${p6}_API_KEY="
  p7="Authorization:"; p7="${p7} Bearer"
  secret_re="$p1|$p2|$p3|$p4|$p5|$p6|$p7"
  echo "claude-smart release-check"
  echo "root=$root"
  bash -n "$root/install.sh" && echo "ok   install.sh syntax" || failed=1
  bash -n "$root/smart-toggle.sh" && echo "ok   smart-toggle.sh syntax" || failed=1
  [[ -f "$root/uninstall.sh" ]] && bash -n "$root/uninstall.sh" && echo "ok   uninstall.sh syntax"
  if rg -n "$secret_re" "$root" -g '!*.git/*'; then
    echo "fail possible secret-looking text found"
    failed=1
  else
    echo "ok   no obvious secret patterns"
  fi
  if git -C "$root" log --format='%an <%ae>' --all | rg -v 'TitasKe <97993783\+TitasKe@users\.noreply\.github\.com>' >/dev/null 2>&1; then
    echo "warn git history contains author metadata outside the configured noreply identity"
  else
    echo "ok   git author metadata uses noreply identity"
  fi
  return "$failed"
}

uninstall() {
  "$CLAUDE_DIR/smart-uninstall.sh"
}

case "${1:-toggle}" in
  toggle) toggle ;;
  status) status ;;
  doctor) doctor ;;
  why|--why)
    shift || true
    why "$@"
    ;;
  models)
    shift || true
    models "$@"
    ;;
  effort)
    shift || true
    effort_cmd "$@"
    ;;
  ultracode)
    effort_cmd ultracode
    ;;
  config)
    shift || true
    config_cmd "$@"
    ;;
  release-check) release_check ;;
  uninstall) uninstall ;;
  -h|--help|help) usage ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 2
    ;;
esac
