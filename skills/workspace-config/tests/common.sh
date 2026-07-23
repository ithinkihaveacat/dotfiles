# shellcheck shell=bash
#
# Shared setup and helpers for the workspace-config tests.
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
# doctor --json`, the in-process ReconcilePlan) over matching human-readable
# report strings; string checks are reserved for the user-facing formatting
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
  TMPDIR=$(python3 -c "import pathlib; print(pathlib.Path('${TMPDIR}').resolve())")
  MOCK_BIN_DIR=$(mktemp -d)
  MOCK_HOME="${TMPDIR}/mock_home"
  mkdir -p "$MOCK_HOME/.claude" "$MOCK_HOME/.gemini/antigravity-cli"
  # shellcheck disable=SC2064  # expand the paths now, at trap-install time
  trap "rm -rf -- '${TMPDIR}' '${MOCK_BIN_DIR}'" EXIT

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
  # HOME, but only when the caller has not already pointed UV_CACHE_DIR at a
  # shared (already-warm) cache. Afterwards resolve strictly offline.
  TEST_UV_CACHE="${TMPDIR}/.cache/uv"
  if [ -z "${UV_CACHE_DIR:-}" ]; then
    UV_CACHE_DIR="$TEST_UV_CACHE" "${SCRIPT}" --help >/dev/null 2>&1 || true
    export UV_CACHE_DIR="$TEST_UV_CACHE"
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
  # Ensure p4 is not found by default during Git/Unmanaged tests.
  export PATH="$MOCK_BIN_DIR:$PATH"

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
# loudly enough). Extra args (e.g. env overrides) are ignored here on purpose:
# callers set SKILL_SOURCE_DIRS/AGENT_REQUIRED_SKILLS in the environment.
doctor_json() {
  "${SCRIPT}" doctor --json 2>/dev/null || true
}

# json_get JSON EXPR -- evaluate a Python expression against the parsed JSON
# (bound to `d`) and print it in a shell-friendly form: bools as true/false,
# lists space-joined, None as empty. Used to read `skill doctor --json` /
# `skill list --json` output without depending on jq.
json_get() {
  printf '%s' "$1" | python3 -c '
import sys, json
d = json.load(sys.stdin)
safe = {n: getattr(__builtins__, n, None) if not isinstance(__builtins__, dict) else __builtins__[n]
        for n in ("next", "len", "sorted", "any", "all", "set", "list", "str", "int")}
v = eval(sys.argv[1], {"__builtins__": {}}, dict(d=d, **safe))
if isinstance(v, bool):
    print("true" if v else "false")
elif isinstance(v, (list, tuple)):
    print(" ".join(str(x) for x in v))
elif v is None:
    print("")
else:
    print(v)
' "$2"
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

# run_module SNIPptr -- exec the skill script as module `m`, then run the
# snippet. AGENT_REQUIRED_SKILLS may be passed as $2.
run_module() {
  AGENT_REQUIRED_SKILLS="${2:-}" python3 -c "
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader('m', '${SCRIPT}')
spec = importlib.util.spec_from_loader('m', loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)
$1
"
}

# run_parser SPECS -- print "<required>|<negated>" for a given
# AGENT_REQUIRED_SKILLS value, exercising get_parsed_skills() directly.
run_parser() {
  run_module "
req, neg = m.get_parsed_skills()
print(','.join(req) + '|' + ','.join(neg))" "$1"
}

# run_plan SNIPptr [SPECS] -- exec the skill module as `m` with a common
# preamble: a FakeWorkspace class and a resolver mapping any name under
# ${PLAN_SRC}/<name> to that directory (missing dirs raise -> unresolvable).
# PLAN_SRC is supplied by the sourcing test (its directory must exist first).
# shellcheck disable=SC2154  # PLAN_SRC is a documented caller-provided input
run_plan() {
  AGENT_REQUIRED_SKILLS="${2:-}" python3 -c "
import importlib.machinery, importlib.util, os
from pathlib import Path

loader = importlib.machinery.SourceFileLoader('m', '${SCRIPT}')
spec = importlib.util.spec_from_loader('m', loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)

PLAN_SRC = Path('${PLAN_SRC}')


def fake_resolve(spec):
    name = spec.split(':', 1)[-1]
    p = PLAN_SRC / name
    if not p.is_dir():
        raise ValueError(f\"cannot resolve skill '{spec}'\")
    return p, name


m.resolve_skill_spec = fake_resolve
m.check_env_freshness = lambda ws: None


class FakeWorkspace:
    def __init__(self, root, dests, expected, actual, tracked=()):
        self.root = Path(root)
        self._dests = [Path(d) for d in dests]
        self._expected = list(expected)
        self._actual = actual  # (set, unmanaged_list, dangling_list)
        self._tracked = set(str(t) for t in tracked)

    def get_expected_skills(self):
        return self._expected

    def get_dest_dirs(self):
        return self._dests

    def get_actual_skills(self):
        s, u, d = self._actual
        return set(s), list(u), list(d)

    def is_tracked(self, path):
        return str(path) in self._tracked

$1
"
}
