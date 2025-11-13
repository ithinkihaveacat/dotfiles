# completions for apk-complications
complete -c apk-complications -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-complications -s h -l help -d 'Display help'
