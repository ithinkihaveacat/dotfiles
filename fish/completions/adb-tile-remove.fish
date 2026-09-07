# completions for adb-tile-remove

complete -c adb-tile-remove -f
complete -c adb-tile-remove -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-tile-remove -s h -l help -d 'Display help message and exit'
