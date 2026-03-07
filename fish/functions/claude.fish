# Wrapper for claude that automatically includes TMPDIR in context
function claude --description 'Run claude with TMPDIR automatically added to context'
    set -lx TMPDIR (mktemp -d /tmp/claude.XXXXXXXXXX)
    command claude --add-dir $TMPDIR $argv
end
