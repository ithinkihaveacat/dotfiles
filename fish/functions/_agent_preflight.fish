# Seed default skills and check skill health before launching a CLI agent
# (claude/codex/agy).
#
# Usage: _agent_preflight LABEL [SKILL_OPTION...]
#
# LABEL names the caller for messages (e.g. "claude"); SKILL_OPTIONs go to
# 'skill' before the command (e.g. --scope session). One 'skill add --defaults'
# call links the defaults and fails if errors remain, so a launch pays for a
# single 'skill' run.
#
# Returns non-zero only to abort the launch. Uses `return`, never `exit`, so it
# never kills the interactive shell.
function _agent_preflight --description 'Seed default skills and check skill health before launching an agent' --argument-names label
    test -n "$label"; or set label agent
    # _agent_preflight_skip is the legacy spelling, honored for old configs.
    if set -q AGENT_PREFLIGHT_SKIP; or set -q _agent_preflight_skip
        echo "$label: skill check skipped (AGENT_PREFLIGHT_SKIP set)" >&2
        return 0
    end
    if not skill $argv[2..-1] add --quiet --defaults
        echo "$label: to launch anyway: AGENT_PREFLIGHT_SKIP=1 $label" >&2
        return 1
    end
end
