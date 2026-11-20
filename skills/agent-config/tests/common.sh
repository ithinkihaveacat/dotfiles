# shellcheck shell=bash
#
# Shared setup and helpers for the skill tests.
#
# The `skill` tests were split from one 2,000-line monolith into focused files
# (test-skill-workspace, test-skill-reconcile, ...). Each of those files sources
# this file, which builds one hermetic, offline sandbox (isolated HOME, XDG
# dirs, SKILL_SOURCE_DIRS, a mock PATH) and defines the shared helpers.
#
# It is named `common.sh` rather than after the skill script so it can grow to
# serve the other scripts' tests here (envrc, permission) as their shared setup
# converges; today only the `skill` tests use it. It is not a `test-*` file, so
# `prove` never runs it directly.
#
# Every sourcing test gets its own `mktemp -d` sandbox, so the files are
# independent and parallel-safe. Assertions prefer structured output (`skill
# doctor --json`, `skill list --json`) over matching human-readable report
# strings; string checks are reserved for the user-facing formatting
# contracts (remediation hints).

# Resolve the tests/ directory from this file's own path, so a sourcing test
# need not compute it. SCRIPT is the skill under test; REPO_ROOT reaches the
# repository top for fish functions and the local plugin fixture.
COMMON_SH_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${COMMON_SH_DIR}/../scripts/skill"
REPO_ROOT="$(cd -P "${COMMON_SH_DIR}/../../.." && pwd)"

# Build the hermetic sandbox and export the isolated environment. Call once,
# near the top of each test file, before the first assertion.
skill_test_init() {
  TMPDIR=$(mktemp -d)
  TMPDIR=$(cd -P "$TMPDIR" && pwd)
  MOCK_BIN_DIR=$(mktemp -d)
  MOCK_HOME="${TMPDIR}/mock_home"
  mkdir -p "$MOCK_HOME/.claude" "$MOCK_HOME/.gemini/antigravity-cli"
  # shellcheck disable=SC2064  # expand the paths now, at trap-install time
  trap "rm -rf -- '${TMPDIR}' '${MOCK_BIN_DIR}'" EXIT

  # Save host uv cache before overriding HOME, so tests that need cached PyPI
  # packages (e.g. PyYAML in test-skill-doctor) can still reach them offline.
  HOST_UV_CACHE="${UV_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/uv}"
  export HOST_UV_CACHE

  # scripts/skill uses Python >=3.11 stdlib only; invoke directly via python3
  # when >=3.11 is available to avoid per-call uv launcher overhead.
  if python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 11))' 2>/dev/null; then
    SKILL_CMD=(python3 "$SCRIPT")
  else
    SKILL_CMD=("$SCRIPT")
  fi

  # Mock executables so skill detects both Claude and Codex paths by default.
  touch "$MOCK_BIN_DIR/claude" "$MOCK_BIN_DIR/codex"
  chmod +x "$MOCK_BIN_DIR/claude" "$MOCK_BIN_DIR/codex"

  # Central source skills, each with a valid SKILL.md.
  mkdir -p "${TMPDIR}/sources/coding-standards" \
    "${TMPDIR}/sources/emumanager" "${TMPDIR}/sources/test-skill"
  printf -- '---\nname: coding-standards\ndescription: Rules for coding standards\n---\nbody\n' \
    >"${TMPDIR}/sources/coding-standards/SKILL.md"
  printf -- '---\nname: emumanager\ndescription: Manage emulators\n---\nbody\n' \
    >"${TMPDIR}/sources/emumanager/SKILL.md"
  printf -- '---\nname: test-skill\ndescription: Test skill\n---\nbody\n' \
    >"${TMPDIR}/sources/test-skill/SKILL.md"

  # Warm the uv cache using the host's credentials/network before isolating
  # HOME and locking down UV_OFFLINE, so tests run strictly offline.
  TEST_UV_CACHE="${TMPDIR}/.cache/uv"
  if [ -z "${UV_CACHE_DIR:-}" ]; then
    export UV_CACHE_DIR="$TEST_UV_CACHE"
  fi
  if [ -z "${UV_OFFLINE:-}" ]; then
    "${SCRIPT}" --help >/dev/null 2>&1 || true
  fi
  export UV_OFFLINE=1

  # Isolate from the user's/system git config (signing, hooks, templates).
  export HOME="$MOCK_HOME"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
  export SKILL_SOURCE_DIRS="${TMPDIR}/sources"
  export XDG_CONFIG_HOME="${TMPDIR}/.config"
  mkdir -p "${XDG_CONFIG_HOME}/skill/plugins"
  cp "${REPO_ROOT}/config/skill/plugins/05_local.py" \
    "${XDG_CONFIG_HOME}/skill/plugins/05_local.py"
  export XDG_CACHE_HOME="${TMPDIR}/.cache"
  export XDG_STATE_HOME="${TMPDIR}/.local/state"
  # Ensure p4 is not found by default during Git/Unmanaged tests.
  export PATH="$MOCK_BIN_DIR:$PATH"
  # Run the same whether or not the suite itself runs inside an agent session
  # (Claude, Codex, Antigravity/Jetski) or with skill's own overrides set.
  unset AGENT_SESSION_DIR AGENT_SESSION_ID CLAUDE_CODE_SESSION_ID \
    CODEX_SESSION_ID ANTIGRAVITY_CONVERSATION_ID JETSKI_CONVERSATION_ID \
    ANTIGRAVITY_APP_DATA_DIR AGY_APP_DATA_DIR \
    SKILL_CACHE_DIR SKILL_DEST_DIRS SKILL_DEBUG AGENT_OFFLINE \
    NO_COLOR FORCE_COLOR

  # A dummy p4 that fails, so we never accidentally detect Perforce.
  cat <<'EOF' >"$MOCK_BIN_DIR/p4"
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "$MOCK_BIN_DIR/p4"
}

# ---------------------------------------------------------------------------
# Structured-output helpers
# ---------------------------------------------------------------------------

# Run `skill doctor --json` in the current directory and print the JSON blob to
# stdout. doctor exits non-zero on an unhealthy workspace, which is expected, so
# swallow the status (callers inspect the JSON, and json_get on empty fails
# loudly enough). Callers set SKILL_SOURCE_DIRS and the like in the
# environment.
doctor_json() {
  "${SKILL_CMD[@]}" doctor --json 2>/dev/null || true
}

# json_get JSON EXPR -- evaluate a Python expression against the parsed JSON
# (bound to `d`) and print it in a shell-friendly form: bools as true/false,
# lists space-joined, None as empty. Used to read `skill doctor --json` /
# `skill list --json` output without depending on jq.
json_get() {
  json_gets "$1" "$2"
}

# json_gets JSON EXPR... -- evaluate one or more Python expressions against a
# single parsed JSON blob, printing one line per expression.
json_gets() {
  local json_input="$1"
  shift
  printf '%s' "$json_input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
safe = {n: getattr(__builtins__, n, None) if not isinstance(__builtins__, dict) else __builtins__[n]
        for n in ("next", "len", "sorted", "any", "all", "set", "list", "str", "int")}
for expr in sys.argv[1:]:
    v = eval(expr, {"__builtins__": {}}, dict(d=d, **safe))
    if isinstance(v, bool):
        print("true" if v else "false")
    elif isinstance(v, (list, tuple)):
        print(" ".join(str(x) for x in v))
    elif v is None:
        print("")
    else:
        print(v)
' "$@"
}

# catalog_field JSONL NAME FIELD -- print one field of the `skill catalog --json`
# record named NAME.
catalog_field() {
  catalog_fields "$1" "$2" "$3"
}

# catalog_fields JSONL NAME FIELD... -- print multiple fields (one per line) of
# the `skill catalog --json` record named NAME. Prints "null" for a JSON null,
# "<absent>" if the record lacks the field, and "<missing>" if no record matches.
catalog_fields() {
  local jsonl="$1" name="$2"
  shift 2
  printf '%s' "$jsonl" | python3 -c '
import sys, json
name, fields = sys.argv[1], sys.argv[2:]
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    d = json.loads(line)
    if d["name"] == name:
        for field in fields:
            v = d.get(field, "<absent>")
            print("null" if v is None else v)
        break
else:
    for _ in fields:
        print("<missing>")
' "$name" "$@"
}

# check_status JSON NAME -- print the status (OK/WARNING/ERROR) of the doctor
# check named NAME, or "MISSING" if that check is absent from the report.
check_status() {
  printf '%s' "$1" | python3 -c '
import sys, json
d = json.load(sys.stdin)
name = sys.argv[1]
for c in d["checks"]:
    if c["name"] == name:
        print(c["status"])
        break
else:
    print("MISSING")
' "$2"
}

# ---------------------------------------------------------------------------
# In-process Python helpers (import the skill module as `m`)
# ---------------------------------------------------------------------------

# run_module SNIPPET -- exec the skill script as module `m`, then run the
# snippet.
run_module() {
  python3 -c "
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader('m', '${SCRIPT}')
spec = importlib.util.spec_from_loader('m', loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)
$1
"
}

# require_node [--ts] -- set NODE_BIN to a Node.js binary with node:test (and
# native TypeScript support when --ts is passed), or print a TAP SKIP and exit.
require_node() {
  local flag="${1:-}" data="${XDG_DATA_HOME:-$HOME/.local/share}/node" cand
  local expr='import "node:test"; process.exit(process.argv[1] === "--ts" && !process.features.typescript ? 1 : 0)'
  for cand in "$(command -v node 2>/dev/null || true)" "$data/default/bin/node" $(compgen -G "$data/versions/node-v*/bin/node" | sort -V -r || true); do
    if [[ -x "$cand" ]] && "$cand" --input-type=module -e "$expr" -- "$flag" >/dev/null 2>&1; then
      export NODE_BIN="$cand"
      PATH="${cand%/*}:$PATH"
      return 0
    fi
  done
  echo "1..0 # SKIP Node.js with node:test${flag:+ and native TypeScript} is not installed"
  exit 0
}
