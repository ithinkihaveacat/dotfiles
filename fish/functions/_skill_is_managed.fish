# True when the current repository has skills managed by the `skill` tool.
#
# Usage: _skill_is_managed [TOPLEVEL]
#
# Detection mirrors what `skill` records: a marker line plus one or more
# managed-skill entries in .git/info/exclude. TOPLEVEL may be passed to reuse an
# already-computed value (the prompt does this); otherwise it is derived from
# the current directory. Returns 0 if managed, 1 otherwise.
function _skill_is_managed --description "True if the repo has skills managed by 'skill'" --argument-names toplevel
    if test -z "$toplevel"
        __fish_is_git_repository; or return 1
        set toplevel (git rev-parse --show-toplevel 2>/dev/null)
    end
    test -n "$toplevel"; or return 1

    set -l exclude_file "$toplevel/.git/info/exclude"
    if not test -f "$exclude_file"
        set exclude_file (git rev-parse --git-path info/exclude 2>/dev/null)
    end
    test -f "$exclude_file"; or return 1

    string match -q -r ">>> skills >>>" <"$exclude_file"; or return 1

    set -l managed_skills (string replace -r '^/\.(claude|agents)/skills/([^/]+)$' '$2' <"$exclude_file" | string match -r '^[^/#]+$')
    set -l unique_skills (printf '%s\n' $managed_skills | sort -u | string match -r '\S+')
    test (count $unique_skills) -gt 0
end
