if test -n "$WINDOWID"
  # X Windows
  function terminal-frontmost
    test "$WINDOWID" = (windowid-frontmost)
  end function
else if test -n "$TERM_SESSION_ID"
  # macOS
  function terminal-frontmost
    # tmp so that an empty tty-frontmost results in an empty string; see
    # https://github.com/fish-shell/fish-shell/issues/159
    set tmp (tty-frontmost)
    test (tty) = "$tmp"
  end function
else
  # Not a graphical environment, or unknown
  function terminal-frontmost
    return 0
  end function
end if
