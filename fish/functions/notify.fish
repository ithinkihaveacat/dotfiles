function notify -a body -a title -d "Posts a notification using the Notification Center"
  # https://developer.apple.com/library/mac/documentation/applescript/conceptual/applescriptlangguide/reference/aslr_cmds.html#//apple_ref/doc/uid/TP40000983-CH216-SW224
  if [ -z "$body" ]
    set body done
  end
  if [ -z "$title" ]
    echo here
    set title Terminal
  end
  osascript -e "display notification \"$body\" with title \"$title\""
end
