function add_path
    # Adds directories to PATH via fish_add_path -gPm rather than fish_user_paths,
    # which can accumulate stale entries. Silently skips non-existent directories.
    for p in $argv
        test -d $p; and fish_add_path -gPm $p
    end
end
