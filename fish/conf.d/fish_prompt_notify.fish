function fish_prompt_notify --on-event fish_prompt
    # If a command takes longer than 10 seconds, notify on completion when
    # Terminal is in the background. Avoids false positives from long-running
    # interactive commands like man. Inspired by:
    # https://github.com/jml/undistract-me/issues/32
    if test $CMD_DURATION
        if test $CMD_DURATION -gt 10000
            if not terminal-frontmost
                set secs (math "$CMD_DURATION / 1000")
                notify "$history[1]" "(status $status; $secs secs)"
            end
        end
    end
end
