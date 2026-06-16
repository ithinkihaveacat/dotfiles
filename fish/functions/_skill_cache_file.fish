# Path to the skill-doctor health cache file for a repository.
#
# Usage: _skill_cache_file TOPLEVEL
#
# The repo's toplevel path is flattened into a single filename (slashes to
# underscores) under $XDG_CACHE_HOME/skill-doctor (falling back to
# ~/.cache/skill-doctor). Both the writer (_agent_preflight) and the reader
# (_skill_doctor_fresh_ok) call this so the key scheme stays in one place.
function _skill_cache_file --description 'Path to the skill-doctor cache file for a repo toplevel' --argument-names toplevel
    set -l cache_dir "$HOME/.cache/skill-doctor"
    set -q XDG_CACHE_HOME; and set cache_dir "$XDG_CACHE_HOME/skill-doctor"
    echo "$cache_dir/"(string replace -a / _ -- "$toplevel")
end
