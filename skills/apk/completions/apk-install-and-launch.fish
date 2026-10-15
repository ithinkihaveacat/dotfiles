# completions for apk-install-and-launch
complete -c apk-install-and-launch -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-install-and-launch -s f -d 'Force uninstall before install'
complete -c apk-install-and-launch -s h -l help -d 'Display help'
