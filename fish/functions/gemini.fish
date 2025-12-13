# Wrapper for gemini that automatically includes TMPDIR in context
function gemini --description 'Run gemini with TMPDIR automatically included in context'
    set -lx TMPDIR (mktemp -d)
    command gemini --include-directories $TMPDIR $argv
end
