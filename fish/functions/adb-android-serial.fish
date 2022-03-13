function adb-android-serial -d "Sets ANDROID_SERIAL, the default device for adb"

  if test ( count $argv ) -eq 0
    printf "usage: %s model # e.g. %s TicWatch\n" (status current-command) (status current-command)
	printf "\n"
    adb devices -l | tail +2
    return
  end

  set -xU ANDROID_SERIAL (adb devices -l | tail +2 | grep -m 1 -i $argv[1] | awk '{ print $1 }')
  printf "ANDROID_SERIAL=%s\n" $ANDROID_SERIAL

end
