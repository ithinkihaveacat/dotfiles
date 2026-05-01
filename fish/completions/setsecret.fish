function __setsecret_names
    set -l file $HOME/.private/fish/secrets.fish
    test -r $file; or return
    fish --no-config -c '
        set -l before (set --names -g)
        source $argv[1] 2>/dev/null
        for v in (set --names -g)
            contains -- $v $before; or echo $v
        end
    ' $file
end

complete -c setsecret -f -l if-unset -d 'Skip already-set names instead of erroring'
complete -c setsecret -f -a "(__setsecret_names)"
