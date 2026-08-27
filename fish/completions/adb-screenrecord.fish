# completions for adb-screenrecord

complete -c adb-screenrecord -s s -l serial -r -d 'Target device serial'
complete -c adb-screenrecord -s o -l output -r -F -d 'The path to save the screen recording to'
complete -c adb-screenrecord -s t -l duration -r -d 'Max recording duration in seconds'
complete -c adb-screenrecord -l time-limit -r -d 'Max recording duration in seconds'
complete -c adb-screenrecord -l raw -d 'Force raw frame capture using ffmpeg'
complete -c adb-screenrecord -l no-raw -d 'Disable raw frame capture (force scrcpy)'
complete -c adb-screenrecord -s h -l help -d 'Display help message and exit'
