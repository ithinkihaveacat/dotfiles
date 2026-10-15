# completions for adb-watchface-set
complete -c adb-watchface-set -f -d 'Watchface component name'
complete -c adb-watchface-set -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-watchface-set -s h -l help -d 'Display help'
