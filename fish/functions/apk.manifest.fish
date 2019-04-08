function apk.manifest -d "Extracts manifest from APK"

  if test ( count $argv ) -eq 0
    printf "usage: %s apk # e.g. %s com.spotify.music.apk\n" (status current-command) (status current-command)
	return
  end
  
  if test ! -f $argv[1] -o ! -r $argv[1]
    printf "error: file [%s] is not readable\n" $argv[1]
    return
  end

  apkanalyzer manifest print $argv[1]
  
end
