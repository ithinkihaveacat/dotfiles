if test -n "$WINDOWID"
  function terminal-frontmost
    test "$WINDOWID" = (windowid-frontmost)
  end function
else
  function terminal-frontmost
    # tmp so that an empty tty-frontmost results in an empty string; see
    # https://github.com/fish-shell/fish-shell/issues/159
    set tmp (tty-frontmost)
    test (tty) = "$tmp"
  end function
end if
