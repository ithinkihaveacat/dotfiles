# completions for adb-tile-dump

complete -c adb-tile-dump -f
complete -c adb-tile-dump -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-tile-dump -s o -l output -r -F -d 'Write the .rc document to FILE'
complete -c adb-tile-dump -s h -l help -d 'Display help message and exit'
