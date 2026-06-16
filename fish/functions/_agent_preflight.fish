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

    # Resolve final required skills (handling whitespace and subtractions cleanly)
    set -l required_set
    for spec in (string match -a -r '\S+' -- "$AGENT_REQUIRED_SKILLS")
        if string match -q -r '^[-!]' -- "$spec"
            set -l clean_name (string replace -r '^[-!]' '' -- "$spec")
            if set -l index (contains -i -- "$clean_name" $required_set)
                set -e required_set[$index]
            end
        else if not contains -- "$spec" $required_set
            set -a required_set "$spec"
        end
    end

    if not _skill_is_managed
        # If the directory has no skills managed, abort only if required skills are configured
        if test (count $required_set) -gt 0
            set -l c_red (set_color -o red)
            set -l c_green (set_color -o green)
            set -l c_reset (set_color normal)

            echo -e "\n$c_red$label: Launch aborted! This directory has no skills managed, but required skills are configured.$c_reset\n" >&2
            echo "  Required:  "(string join ', ' $required_set) >&2
            echo -e "\nTo initialize skill management with the required skills, run:" >&2
            echo -e "  $c_green""skill add "(string join ' ' $required_set)"$c_reset\n" >&2
            return 1
        end
        echo "$label: not a skill-managed repo; skipping skill doctor" >&2
        return 0
    end

    # Enforce presence of all required skills
    if test (count $required_set) -gt 0
        set -l active_skills (skill list 2>/dev/null | string replace -r '\s+->.*$' '')
        set -l missing_skills

        for req in $required_set
            if not contains -- "$req" $active_skills
                set -a missing_skills "$req"
            end
        end

        if test (count $missing_skills) -gt 0
            set -l c_red (set_color -o red)
            set -l c_green (set_color -o green)
            set -l c_reset (set_color normal)

            echo -e "\n$c_red$label: Launch aborted due to missing required skills in this repository!$c_reset\n" >&2
            echo "  Required:  "(string join ', ' $required_set) >&2
            echo "  Active:    "(string join ', ' $active_skills) >&2
            echo -e "  $c_red""Missing:   "(string join ', ' $missing_skills)"$c_reset\n" >&2
            echo "To resolve this, run the following command in the repository root:" >&2
            echo -e "  $c_green""skill add "(string join ' ' $missing_skills)"$c_reset\n" >&2
            return 1
        end
    end

    skill doctor
end
