# Wrapper for claude that automatically includes TMPDIR in context
function claude --description 'Run claude with TMPDIR automatically added to context'
    command claude --add-dir $TMPDIR $argv
end
