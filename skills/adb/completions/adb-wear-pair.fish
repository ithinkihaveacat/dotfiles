# Fish completion for adb-wear-pair

complete -c adb-wear-pair -f
complete -c adb-wear-pair -s p -l phone -x -a '(__fish_android_devices)' -d 'Target phone emulator serial'
complete -c adb-wear-pair -s w -l watch -x -a '(__fish_android_devices)' -d 'Target Wear OS emulator serial'
complete -c adb-wear-pair -l port -x -d 'TCP port to bridge on the host (default: 5601)'
complete -c adb-wear-pair -l status -d 'Display current pairing status instead of pairing'
complete -c adb-wear-pair -s v -l verbose -d 'Include verbose dumpsys output during status checks'
complete -c adb-wear-pair -s h -l help -d 'Display help message and exit'
