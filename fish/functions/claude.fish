# Wrapper for claude that gives each session its own directory, for scratch
# files (TMPDIR) and per-session skills (AGENT_SESSION_DIR, read by
# 'skill --scope session').
function claude --description 'Run claude with a per-session directory for scratch files and skills'
    _agent_preflight claude; or return
    set -lx TMPDIR (mktemp -d /tmp/claude.XXXXXXXXXX)
    set -lx AGENT_SESSION_DIR $TMPDIR
    set -lx AGENT_SESSION_ID

    # Bind AGENT_SESSION_DIR to this session's ID, so a nested agent that
    # inherits the environment cannot write into it. Claude keeps the ID on
    # '--resume ID' and rejects '--session-id' when resuming without
    # '--fork-session'; '--continue' and the '--resume' picker leave the ID
    # unknown, so the directory stays unbound.
    set -l session_id
    set -l resume_id
    set -l resuming
    set -l forking
    set -l n (count $argv)
    for i in (seq $n)
        set -l next
        test $i -lt $n; and set next $argv[(math $i + 1)]
        switch $argv[$i]
            case --
                break
            case --session-id
                set session_id $next
            case '--session-id=*'
                set session_id (string replace -- --session-id= '' $argv[$i])
            case -c --continue
                set resuming 1
            case -r --resume
                set resuming 1
                string match -qr '^[0-9a-fA-F-]{36}$' -- "$next"; and set resume_id $next
            case '--resume=*'
                set resuming 1
                set resume_id (string replace -- --resume= '' $argv[$i])
            case --fork-session
                set forking 1
        end
    end

    set -l session_args
    if test -n "$session_id"
        set AGENT_SESSION_ID $session_id
    else if test -n "$resuming"; and test -z "$forking"
        set AGENT_SESSION_ID $resume_id
    else
        if test -r /proc/sys/kernel/random/uuid
            read session_id </proc/sys/kernel/random/uuid
        else
            set session_id (uuidgen | string lower)
        end
        set session_args --session-id $session_id
        set AGENT_SESSION_ID $session_id
    end

    command claude --add-dir $TMPDIR $session_args $argv
end
