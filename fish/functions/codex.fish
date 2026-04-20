# Wrapper for codex that keeps a few local write/network allowances readable.
function codex --description 'Run codex with local writable dirs and sandbox defaults'
    set -lx TMPDIR (mktemp -d /tmp/codex.XXXXXXXXXX)

    set -l codex_writable_dirs \
        $TMPDIR \
        $HOME/.cache/uv

    set -l codex_config_overrides \
        sandbox_workspace_write.network_access=true

    set -l codex_args \
        --sandbox workspace-write \
        --ask-for-approval on-request

    for dir in $codex_writable_dirs
        set -a codex_args --add-dir $dir
    end

    for override in $codex_config_overrides
        set -a codex_args --config $override
    end

    command codex $codex_args $argv
end
