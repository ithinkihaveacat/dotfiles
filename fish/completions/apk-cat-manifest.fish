# completions for apk-cat-manifest
complete -c apk-cat-manifest -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-cat-manifest -s h -l help -d 'Display help'
