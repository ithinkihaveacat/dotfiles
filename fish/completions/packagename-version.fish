# completions for packagename-version
complete -c packagename-version -f -a '(__fish_android_packages)' -d 'Package name'
complete -c packagename-version -s h -l help -d 'Display help'
