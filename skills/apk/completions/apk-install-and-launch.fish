# completions for apk-install-and-launch
complete -c apk-install-and-launch -F -a '(__fish_complete_suffix .apk .apks .zip)' -d 'APK, split archive, or directory'
complete -c apk-install-and-launch -s s -l serial -x -a '(__fish_android_devices)' -d 'Target device serial'
complete -c apk-install-and-launch -s f -d 'Force uninstall before install'
complete -c apk-install-and-launch -s h -l help -d 'Display help'
