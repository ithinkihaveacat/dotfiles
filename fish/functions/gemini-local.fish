function gemini-local --description 'Run gemini (local version)'
    set -l executable $HOME/.local/bin/gemini
    if not test -f $executable
        echo "gemini-local: $executable not found" >&2
        echo "It needs to be added by running 'npm install -g .' (from the repository directory)" >&2
        return 1
    end

    # Check if older than a week (604800 seconds)
    set -l mtime (date -r $executable +%s 2>/dev/null)
    set -l now (date +%s)
    if test -n "$mtime"
        if test (math "$now - $mtime") -gt 604800
            echo "gemini-local: Warning: $executable is more than a week old." >&2
            echo "It potentially needs to be rebuilt by updating the source, and then running `npm ci` in the repository directory." >&2
        end
    end

    set -lx TMPDIR (mktemp -d)
    $executable --include-directories $TMPDIR $argv
end
