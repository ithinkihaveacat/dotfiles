# Set up AGENTS_TMPDIR for agent workspaces
if not set -q TMPDIR
    set -x TMPDIR (mktemp -d)
end

set -x AGENTS_TMPDIR "$TMPDIR/agents"
