# Seed default skills, check skill health, and synchronize git hooks before
# launching a CLI agent (claude/codex/agy).
#
# Usage: _agent_preflight LABEL [SKILL_OPTION...]
#
# LABEL names the caller for messages (e.g. "claude"); SKILL_OPTIONs go to
# 'skill' before the command (e.g. --scope session). One 'skill add --defaults'
# call links the defaults and fails if errors remain, so a launch pays for a
# single 'skill' run. Inside a git repository (other than ~), 'hook apply
# --quiet' synchronizes AGENT_REQUIRED_HOOKS so the agent commit-msg hook is in
# place before the session starts.
#
# Returns non-zero only to abort the launch. Uses `return`, never `exit`, so it
# never kills the interactive shell.
function _agent_preflight --description 'Seed default skills and synchronize git hooks before launching an agent' --argument-names label
    test -n "$label"; or set label agent
    # _agent_preflight_skip is the legacy spelling, honored for old configs.
    if set -q AGENT_PREFLIGHT_SKIP; or set -q _agent_preflight_skip
        echo "$label: skill check skipped (AGENT_PREFLIGHT_SKIP set)" >&2
        return 0
    end
    # 'skill' is a 'uv run --script' helper, and uv inspects any active virtual
    # environment, so a project venv whose interpreter is gone (e.g. after a
    # Homebrew Python upgrade) would otherwise block the launch.
    if not env -u VIRTUAL_ENV skill $argv[2..-1] add --quiet --defaults
        echo "$label: to launch anyway: AGENT_PREFLIGHT_SKIP=1 $label" >&2
        return 1
    end
    if test (pwd -P) != (realpath $HOME 2>/dev/null; or echo $HOME)
        and command git rev-parse --git-dir >/dev/null 2>&1
        if not hook apply --quiet
            echo "$label: to launch anyway: AGENT_PREFLIGHT_SKIP=1 $label" >&2
            return 1
        end
    end
end
