function __getsecret_names
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

complete -c getsecret -f -a "(__getsecret_names)"
