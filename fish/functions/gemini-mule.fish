function gemini-mule --description 'Run gemini (mule version)'
    set -l executable /usr/local/bin/gemini
    if not test -f $executable
        echo "gemini-mule: $executable not found" >&2
        return 1
    end

    # Set TMPDIR to a directory gemini can access without permission
    set -lx TMPDIR $HOME/.gemini/tmp
    $executable -m gemini-3-flash-preview $argv
end
