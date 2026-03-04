function gemini-mule --description 'Run gemini (mule version)'
    set -l executable /usr/local/bin/gemini
    if not test -f $executable
        echo "gemini-mule: $executable not found" >&2
        return 1
    end

    set -lx TMPDIR (mktemp -d)
    $executable --include-directories $TMPDIR -m gemini-3-flash-preview $argv
end
