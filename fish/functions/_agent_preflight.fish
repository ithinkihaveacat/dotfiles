# Verify skill health before launching a CLI agent (claude/codex/agy).
#
# Usage: _agent_preflight [LABEL]
#
# LABEL names the caller for messages (e.g. "claude"). Behaviour:
#   - If `_agent_preflight_skip` is set, skip the check and allow the launch.
#   - In a repo with no skills managed by `skill`, warn and allow the launch
#     (nothing to verify).
#   - In a managed repo, run `skill doctor`. On success return 0; on failure,
#     let doctor's own drift report through, return 1.
#
# Returns non-zero only to abort the launch. Uses `return`, never `exit`, so it
# never kills the interactive shell.
function _agent_preflight --description 'Verify skill health before launching an agent' --argument-names label
    test -n "$label"; or set label agent

    if set -q _agent_preflight_skip
        echo "$label: skill check skipped (_agent_preflight_skip set)" >&2
        return 0
    end

    if not _skill_is_managed
        echo "$label: not a skill-managed repo; skipping skill doctor" >&2
        return 0
    end

    skill doctor
end
