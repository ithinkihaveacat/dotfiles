if test -n "$WINDOWID"

  # X Windows
  function terminal-frontmost -d "Returns 0 if terminal is frontmost, otherwise 1"
    set -l tmp (printf "%d" (string split -m 1 -r " " (xprop -root _NET_ACTIVE_WINDOW))[2])
    test "$WINDOWID" = "$tmp"
  end function

else if test -n "$TERM_SESSION_ID"

  # macOS
  function terminal-frontmost -d "Returns 0 if terminal is frontmost, otherwise 1"
    set -l tmp (osascript \
      -e 'tell application "Terminal"' \
      -e '  if frontmost is true' \
      -e '    repeat with w in windows' \
      -e '      if (frontmost of w) is true then' \
      -e '        set t to (selected tab of w)' \
      -e '        return (tty of t) as string' \
      -e '      end if' \
      -e '    end repeat' \
      -e '  end if' \
      -e 'end tell' \
    )
    test (tty) = "$tmp"
  end function

else

  # Unknown/other
  function terminal-frontmost -d "Returns 0 if terminal is frontmost, otherwise 1"
    return 0 # Always frontmost
  end function

end if
