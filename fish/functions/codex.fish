# Wrapper for codex that automatically includes TMPDIR in context
function codex --description 'Run codex with TMPDIR automatically included in context'
    set -lx TMPDIR (mktemp -d)
    command codex --add-dir $TMPDIR --sandbox workspace-write --ask-for-approval on-request $argv
end
