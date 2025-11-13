# completions for apk-unzip
complete -c apk-unzip -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-unzip -s h -l help -d 'Display help'
