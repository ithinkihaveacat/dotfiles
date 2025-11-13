# completions for apk-cat-launcher
complete -c apk-cat-launcher -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-cat-launcher -s h -l help -d 'Display help'
