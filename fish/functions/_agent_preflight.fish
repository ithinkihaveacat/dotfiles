# Verify skill health before launching a CLI agent (claude/codex/agy).
#
# Usage: _agent_preflight [LABEL]
#
# LABEL names the caller for messages (e.g. "claude"). Behaviour:
#   - If `_agent_preflight_skip` is set, skip the check and allow the launch.
#   - In a repo with no skills managed by `skill`, warn and allow the launch
#     (nothing to verify; no cache is written).
#   - In a managed repo, run `skill doctor`. On success cache "ok" and return 0;
#     on failure cache "fail", let doctor's own drift report through, return 1.
#
# Returns non-zero only to abort the launch. Uses `return`, never `exit`, so it
# never kills the interactive shell. The cache it writes is read by the prompt
# via _skill_doctor_fresh_ok.
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

    set -l toplevel (git rev-parse --show-toplevel 2>/dev/null)
    set -l cache_file (_skill_cache_file "$toplevel")

    set -l content
    if skill doctor
        set content ok
    else
        set content fail
    end

    # Atomic write so concurrent launches can't produce a torn read.
    set -l cache_dir (path dirname -- "$cache_file")
    mkdir -p "$cache_dir" 2>/dev/null
    set -l tmp (mktemp "$cache_dir/tmp.XXXXXX" 2>/dev/null)
    if test -n "$tmp"
        echo "$content" >"$tmp"
        mv -f "$tmp" "$cache_file"
    end

    test "$content" = ok
end
