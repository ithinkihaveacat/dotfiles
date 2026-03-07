# Wrapper for gemini that automatically includes TMPDIR in context
function gemini --description 'Run gemini with TMPDIR automatically included in context'
    set -l mktemp_base /tmp
    if test -d $HOME/.gemini/tmp
        set mktemp_base $HOME/.gemini/tmp
    end
    set -lx TMPDIR (mktemp -d $mktemp_base/gemini.XXXXXXXXXX)
    command gemini $argv
end
