# completions for adb-logcat-package
complete -c adb-logcat-package -f -a '(__fish_android_packages)' -d 'Package name'
complete -c adb-logcat-package -s h -l help -d 'Display help'
