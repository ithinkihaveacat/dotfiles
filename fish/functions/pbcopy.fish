function pbcopy
    set -l cmdline
    set -l is_tty_stdin 0
    if isatty stdin
        set is_tty_stdin 1
    end

    if test $is_tty_stdin -eq 1
        set cmdline (commandline --current-selection | fish_indent --only-indent | string collect)
        test -n "$cmdline"; or set cmdline (commandline | fish_indent --only-indent | string collect)
    else
        # Slurp the entire input (-0777).
        # If the string contains no internal newlines (m/\n./s would mean a newline followed by something),
        # strip the trailing newline.
        # We use -pe to auto-print.
        set cmdline (string collect --no-trim-newline | perl -0777 -pe 's/\n$// if !/\n./')
    end

    if not is_remote; and type -q pbcopy
        printf '%s' "$cmdline" | command pbcopy
        return
    end

    if not type -q base64; or test "$TERM" = dumb
        echo "pbcopy: cannot copy (no base64 or dumb terminal)" >&2
        return 1
    end

    # OSC 52 needs to be sent to the terminal
    # Write to /dev/tty to work even if stdout is redirected
    set -l encoded (printf '%s' "$cmdline" | base64 | string join '')
    printf '\e]52;c;%s\a' "$encoded" >/dev/tty
end
