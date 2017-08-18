function notify -a title -a body -d "Posts a notification using the native notification system"

  if [ -z "$title" ]
    echo "usage: $_ title [body]"
    return
  end
  if [ -z "$body" ]
    set body ""
  end

  if type -q osascript
    # https://developer.apple.com/library/mac/documentation/applescript/conceptual/applescriptlangguide/reference/aslr_cmds.html#//apple_ref/doc/uid/TP40000983-CH216-SW224
    osascript -e "on run argv" -e "display notification (item 2 of argv) with title (item 1 of argv)" -e "end run" $title $body
    return
  end

  if type -q notify-send
    notify-send --icon=terminal $title $body
    return
  end

  echo "error: unsupported system"
  return 1

end
