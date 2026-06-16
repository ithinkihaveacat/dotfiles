# Verify skill health before launching a CLI agent (claude/codex/agy).
#
# Usage: _agent_preflight [LABEL]
#
# LABEL names the caller for messages (e.g. "claude").
# Delegates the validation entirely to the python 'skill preflight' command,
# protecting the parent shell from being killed on exit.
#
# Returns non-zero only to abort the launch. Uses `return`, never `exit`, so it
# never kills the interactive shell.
function _agent_preflight --description 'Verify skill health before launching an agent' --argument-names label
    test -n "$label"; or set label agent
    skill preflight "$label"
end
