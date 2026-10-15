# completions for adb-tile-switch

complete -c adb-tile-switch -f
complete -c adb-tile-switch -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-tile-switch -s h -l help -d 'Display help message and exit'
