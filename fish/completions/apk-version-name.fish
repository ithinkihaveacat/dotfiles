# completions for apk-version-name
complete -c apk-version-name -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-version-name -s h -l help -d 'Display help'
