function pbpaste
    if not is_remote
        if type -q pbpaste
            command pbpaste
            return
        end
    end

    # For remote sessions, try OSC 52 clipboard read
    if test "$TERM" = dumb
        return 1
    end

    if not type -q base64
        return 1
    end

    # OSC 52 query: \e]52;c;?\a asks the terminal for clipboard contents
    # The terminal responds with \e]52;c;<base64-data>\e\\ or \e]52;c;<base64-data>\a
    # Note: Ghostty prompts the user before allowing clipboard reads

    # Save terminal state and configure for reading response
    set -l old_stty (command stty -g 2>/dev/null)
    if test $status -ne 0
        return 1
    end

    # Set terminal to raw mode with timeout (10 deciseconds = 1 second)
    command stty raw -echo min 0 time 10 2>/dev/null

    # Send OSC 52 query to terminal
    printf '\e]52;c;?\a' >/dev/tty

    # Read response from terminal
    set -l response (command dd bs=1024 count=1 2>/dev/null </dev/tty)

    # Restore terminal state
    command stty $old_stty 2>/dev/null

    # Parse the response to extract base64 data
    # Response format: \e]52;c;<base64>\a or \e]52;c;<base64>\e\\
    # Using string match to extract the base64 portion
    set -l match (string match -r '\]52;c;([A-Za-z0-9+/=]+)' -- $response)
    if test (count $match) -ge 2
        printf '%s' $match[2] | base64 -d 2>/dev/null
        return $status
    end

    return 1
end
