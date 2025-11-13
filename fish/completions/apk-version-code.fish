# completions for apk-version-code
complete -c apk-version-code -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-version-code -s h -l help -d 'Display help'
