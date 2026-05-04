function add_path
    # Modify PATH directly via fish_add_path -gP rather than using fish_user_paths.
    # fish_user_paths is useful for sharing paths across shells when set as a
    # universal variable, but can accumulate stale entries over time. Using -gP
    # keeps PATH management explicit and predictable. The -m flag moves existing
    # entries to avoid duplicates. See
    # https://github.com/fish-shell/fish-shell/issues/527#issuecomment-253775156
    for p in $argv
        test -d $p; and fish_add_path -gPm $p
    end
end
