# completions for apk-decode
complete -c apk-decode -F -a '(__fish_complete_suffix .apk .zip)' -d 'APK or ZIP file'
complete -c apk-decode -s o -l output -x -a '(__fish_complete_directories)' -d 'Directory to decode the APK into'
complete -c apk-decode -s h -l help -d 'Display help'
