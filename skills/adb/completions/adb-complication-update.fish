# completions for adb-complication-update
complete -c adb-complication-update -f -d 'Complication ID'
complete -c adb-complication-update -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-complication-update -s h -l help -d 'Display help'
