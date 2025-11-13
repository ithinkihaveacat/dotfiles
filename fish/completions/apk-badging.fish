# completions for apk-badging
complete -c apk-badging -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-badging -s h -l help -d 'Display help'
