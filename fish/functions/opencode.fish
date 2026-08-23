function opencode --description 'Run opencode from ~/.opencode/bin or PATH'
    if test -x $HOME/.opencode/bin/opencode
        $HOME/.opencode/bin/opencode $argv
    else if type -q -f opencode
        command opencode $argv
    else
        echo 'opencode: command not found (install via https://opencode.ai or place in ~/.opencode/bin)' >&2
        return 127
    end
end
