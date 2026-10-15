# completions for adb-settings-theme

complete -c adb-settings-theme -f
complete -c adb-settings-theme -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-settings-theme -s h -l help -d 'Display help message and exit'
