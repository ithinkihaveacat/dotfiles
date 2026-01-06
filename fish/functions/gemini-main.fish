function gemini-main --description 'Run gemini (main bundle)'
    set -l executable $HOME/workspace/gemini-cli/bundle/gemini.js
    if not test -f $executable
        echo "gemini-main: $executable not found" >&2
        return 1
    end

    set -lx TMPDIR (mktemp -d)
    node $executable --include-directories $TMPDIR $argv
end
