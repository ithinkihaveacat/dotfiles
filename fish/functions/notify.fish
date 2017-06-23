function notify -a body -a title -d "Posts a notification using the native notification system"

  if [ -z "$body" ]
    set body done
  end
  if [ -z "$title" ]
    set title Terminal
  end

  if type -q osascript
    # https://developer.apple.com/library/mac/documentation/applescript/conceptual/applescriptlangguide/reference/aslr_cmds.html#//apple_ref/doc/uid/TP40000983-CH216-SW224
    osascript -e "display notification \"$body\" with title \"$title\""
    return
  end

  if type -q notify-send
    notify-send $title $body
    return
  end

  echo "error: unsupported system"
  return 1

end
