# completions for adb-battery-stats

complete -c adb-battery-stats -f
complete -c adb-battery-stats -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-battery-stats -s h -l help -d 'Display help message and exit'
