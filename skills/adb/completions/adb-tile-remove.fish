# completions for adb-tile-remove

complete -c adb-tile-remove -f
complete -c adb-tile-remove -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-tile-remove -l vertical -d 'Remove widget from standalone renderer vertical carousel (WidgetTrayActivity)'
complete -c adb-tile-remove -l all -d 'With --vertical, remove every widget in the tray'
complete -c adb-tile-remove -s h -l help -d 'Display help message and exit'
