# completions for adb-log

complete -c adb-log -f
complete -c adb-log -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-log -s h -l help -d 'Display help message and exit'
