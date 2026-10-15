# completions for adb-device-properties
complete -c adb-device-properties -f
complete -c adb-device-properties -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-device-properties -s h -l help -d 'Display help'
