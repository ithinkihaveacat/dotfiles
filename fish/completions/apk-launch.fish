# completions for apk-launch
complete -c apk-launch -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-launch -s h -l help -d 'Display help'
