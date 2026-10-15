# completions for avd-to-png
complete -c avd-to-png -s o -l output -r -F -d 'Path to output PNG file'
complete -c avd-to-png -s h -l help -d 'Display help'
complete -c avd-to-png -F -a '(__fish_complete_suffix .xml)' -d 'Android Vector Drawable XML file'
