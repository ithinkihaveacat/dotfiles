# shellcheck shell=bash
#
# Shared setup and helpers for the taskgo bash tests.
#
# The taskgo bash tests were split from one monolith into focused files
# (test-taskgo-apply, test-taskgo-crud, ...), plus test-taskgo-cache. Each
# sources this file for hermetic environment isolation, temp directory cleanup,
# cached script Python resolution, and common fixture setup.
#
# Not named `test-*`, so `prove` never runs it directly.

TEST_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$TEST_DIR/../scripts/taskgo"
# shellcheck disable=SC2034
MCP_BIN="$TEST_DIR/../scripts/taskgo-mcp"
# shellcheck disable=SC2034
MARKDOWN_FORMAT="$TEST_DIR/../../coding-standards/scripts/markdown-format"

# Isolate test suite from ambient styling, agent runtime variables, and git
# author settings, create TEST_ROOT, and resolve TASKGO_PY once.
taskgo_test_init() {
  # Color styling is asserted explicitly per test; isolate from inherited
  # NO_COLOR/FORCE_COLOR.
  unset NO_COLOR FORCE_COLOR

  # Isolate test suite from ambient agent runtime variables.
  unset AI_AGENT INVOKER_INFO_NAME
  unset JETSKI_CONVERSATION_ID ANTIGRAVITY_CONVERSATION_ID ANTIGRAVITY_SESSION
  unset CLAUDE_CODE_SESSION_ID CLAUDE_CODE_REMOTE_SESSION_ID CLAUDE_SESSION_ID CLAUDE_PROJECT_ID
  unset OPENCODE_SESSION_ID CODEX_SESSION_ID
  unset CONVERSATION_ID
  unset TASKGO_ROOT

  export GIT_AUTHOR_NAME="Taskgo Test"
  export GIT_AUTHOR_EMAIL="taskgo@example.com"
  export GIT_COMMITTER_NAME="Taskgo Test"
  export GIT_COMMITTER_EMAIL="taskgo@example.com"
  export AGENT_OFFLINE="${AGENT_OFFLINE:-1}"

  TEST_ROOT="$(mktemp -d)"
  trap 'rm -rf -- "$TEST_ROOT"' EXIT
  export UV_CACHE_DIR="${UV_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/uv}"
  export XDG_CACHE_HOME="$TEST_ROOT/xdg-cache"
  export TASKGO_MCP_LOG="$TEST_ROOT/mcp-requests.jsonl"

  if [[ -z "${TASKGO_PY:-}" ]]; then
    TASKGO_PY=$(uv sync -q --script "$BIN" </dev/null && uv python find --script "$BIN")
  fi
  export TASKGO_PY
  # scripts/taskgo shares exact mdformat + ruamel.yaml pins with markdown-format.
  # shellcheck disable=SC2034
  export MDFMT_PY="${MDFMT_PY:-$TASKGO_PY}"
}

# Run taskgo directly with its pre-synced script Python to skip per-call
# `uv run --script` startup overhead in repetitive test setups and checks.
tg() {
  "$TASKGO_PY" "$BIN" "$@"
}

# Run markdown-format directly with its pre-synced Python to skip cold `uv` runs.
mdfmt() {
  "$MDFMT_PY" "$MARKDOWN_FORMAT" "$@"
}

# Initialize a minimal git-backed taskgo repository at TARGET with AGENTS.md,
# INBOX.md, and `<project>/{README.md,tasks}` for each optional PROJECT arg.
create_taskgo_repo() {
  local target="$1"
  shift
  mkdir -p "$target"
  git -C "$target" init -q -b main
  printf '%s\n' \
    '# Agent instructions' \
    '' \
    'This repository follows taskgo:' \
    '<https://github.com/ithinkihaveacat/dotfiles/tree/main/skills/taskgo>.' \
    >"$target/AGENTS.md"
  printf '# Inbox\n' >"$target/INBOX.md"
  local proj
  for proj in "$@"; do
    mkdir -p "$target/$proj/tasks"
    printf '# %s\n' "$proj" >"$target/$proj/README.md"
  done
}

init_base_repo() {
  local target="${1:-$TEST_ROOT/repo}"
  mkdir -p "$target/example/tasks"
  git -C "$target" init -q
  printf '%s\n' '# Agent instructions' '' 'This repository follows taskgo:' \
    '<https://github.com/ithinkihaveacat/dotfiles/tree/main/skills/taskgo>.' >"$target/AGENTS.md"
  printf '# Inbox\n' >"$target/INBOX.md"
  printf '# Example project\n' >"$target/example/PROJECT.md"
  printf '# Plan\n' >"$target/example/PLAN.md"
  printf '%s\n' '---' 'id: TASK-A1B2C' 'status: todo' '---' '' \
    '# Confirm generated status formatting' >"$target/example/tasks/TASK-A1B2C-confirm-status.md"
}
