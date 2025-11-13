# completions for apk-packagename
complete -c apk-packagename -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-packagename -s h -l help -d 'Display help'
