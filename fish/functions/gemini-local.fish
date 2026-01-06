function gemini-local --description 'Run gemini (local version)'
    set -l executable $HOME/.local/bin/gemini
    if not test -f $executable
        echo "gemini-local: $executable not found" >&2
        return 1
    end

    set -lx TMPDIR (mktemp -d)
    $executable --include-directories $TMPDIR $argv
end
