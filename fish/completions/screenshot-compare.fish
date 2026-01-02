complete -c screenshot-compare -f
complete -c screenshot-compare -s h -l help -d "Display help message and exit"
complete -c screenshot-compare -n "test (count (commandline -opc)) -lt 3" -a "(__fish_complete_suffix .png .jpg .jpeg .webp)" -d "Screenshot file"
