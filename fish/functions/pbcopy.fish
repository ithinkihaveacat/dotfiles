function pbcopy
    set -l cmdline
    set -l is_tty_stdin 0
    if isatty stdin
        set is_tty_stdin 1
    end

    if test $is_tty_stdin -eq 1
        set cmdline (commandline --current-selection | fish_indent --only-indent | string collect)
        test -n "$cmdline"; or set cmdline (commandline | fish_indent --only-indent | string collect)
    end

    if not is_remote; and type -q pbcopy
        if test $is_tty_stdin -eq 1
            printf '%s' $cmdline | command pbcopy
        else
            command pbcopy
        end
        return
    end

    if test $is_tty_stdin -eq 0
        while read -lz line
            set -a cmdline $line
        end
    end

    if not type -q base64; or test "$TERM" = dumb
        echo "pbcopy: cannot copy (no base64 or dumb terminal)" >&2
        return 1
    end

    # OSC 52 needs to be sent to the terminal
    # Write to /dev/tty to work even if stdout is redirected
    set -l encoded (printf '%s' $cmdline | base64 | string join '')
    printf '\e]52;c;%s\a' "$encoded" >/dev/tty
end
