function apk.get -d "Downloads APK from device"

  if test ( count $argv ) -eq 0
    printf "usage: %s package # e.g. %s com.spotify.music\n" (status current-command) (status current-command)
    return
  end

  set -l path (adb shell pm path $argv[1] | cut -f 2 -d :)

  if test -z "$path"
    printf "error: %s not found on device\n" $argv[1]
  return
  end
  
  adb pull $path (printf "%s.apk" $argv[1])

end
