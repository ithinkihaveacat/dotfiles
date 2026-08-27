# completions for adb-tile-add
complete -c adb-tile-add -f
complete -c adb-tile-add -s s -l serial -r -d 'Target device serial'
complete -c adb-tile-add -l no-show -d 'Do not show the tile after adding it'
complete -c adb-tile-add -l wait -d 'Wait for the tile to be visible (default)'
complete -c adb-tile-add -l no-wait -d 'Do not wait for visibility (return immediately)'
complete -c adb-tile-add -l type -d 'Tile type' -r -a 'FULLSCREEN LARGE SMALL'
complete -c adb-tile-add -s h -l help -d 'Display help message and exit'
