complete -c screenshot-compare -f
complete -c screenshot-compare -s h -l help -d "Display help message and exit"
complete -c screenshot-compare -l version -d "Display version number and exit"
complete -c screenshot-compare -l model -x -d "Gemini model to use"
complete -c screenshot-compare -n "test (count (commandline -opc)) -lt 3" -a "(__fish_complete_suffix .png .jpg .jpeg .webp)" -d "Screenshot file"
