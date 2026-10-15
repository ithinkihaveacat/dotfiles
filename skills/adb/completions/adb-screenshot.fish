# Fish completion for adb-screenshot

complete -c adb-screenshot -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c adb-screenshot -s o -l output -r -F -d 'The path to save the screenshot to'
complete -c adb-screenshot -l preview -d 'Display a preview of the image using chafa'
complete -c adb-screenshot -l no-preview -d 'Disable preview (default)'
complete -c adb-screenshot -l copy -d 'Copy the image to the clipboard (macOS only)'
complete -c adb-screenshot -l no-copy -d 'Do not copy to clipboard (default)'
complete -c adb-screenshot -s h -l help -d 'Display help message and exit'
