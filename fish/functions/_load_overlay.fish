function _load_overlay --argument-names root
    test -d $root/fish/functions; and set -p fish_function_path $root/fish/functions
    test -d $root/fish/completions; and set -p fish_complete_path $root/fish/completions
    if test -d $root/fish/conf.d
        for f in $root/fish/conf.d/*.fish
            source $f
        end
    end
end
