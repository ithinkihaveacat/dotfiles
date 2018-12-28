if type -q osascript

  function notify -a title -a body -d "Posts a notification using the native notification system"
    test -n "$title" ; or begin ; printf "usage: %s title [body]\n"	(status current-command) ; return ; end
    test -n "$body"  ; or set -l body ""
    # https://developer.apple.com/library/mac/documentation/applescript/conceptual/applescriptlangguide/reference/aslr_cmds.html#//apple_ref/doc/uid/TP40000983-CH216-SW224
    osascript -e "on run argv" -e "display notification (item 2 of argv) with title (item 1 of argv)" -e "end run" $title $body
  end

else if type -q notify-send

  function notify -a title -a body -d "Posts a notification using the native notification system"
    test -n "$title" ; or begin ; printf "usage: %s title [body]\n" (status current-command); return ; end
    test -n "$body"  ; or set -l body ""
    notify-send --icon=terminal $title $body
  end

else

  function notify -a title -a body -d "Posts a notification using the native notification system"
    test -n "$title" ; or begin ; printf "usage: %s title [body]\n" (status current-command); return ; end
    test -n "$body"  ; or set -l body ""
    echo "$title: $body"
  end

end
