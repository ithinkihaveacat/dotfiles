# Load a dotfiles overlay repo into the current fish session.
#
# Usage: _load_overlay ROOT
#
# ROOT is expected to follow the same layout as ~/.dotfiles:
#   fish/functions/   prepended to fish_function_path (autoloaded)
#   fish/completions/ prepended to fish_complete_path (autoloaded)
#   fish/conf.d/      *.fish files sourced immediately at startup
#
# Called from config.fish for ~/.private and ~/.corp. Silently does
# nothing if ROOT does not exist or has no fish/ subdirectories.
# See README.md §Overlays for the full overlay system description.
function _load_overlay --argument-names root
    test -d $root/fish/functions; and set -p fish_function_path $root/fish/functions
    test -d $root/fish/completions; and set -p fish_complete_path $root/fish/completions
    if test -d $root/fish/conf.d
        for f in $root/fish/conf.d/*.fish
            source $f
        end
    end
end
