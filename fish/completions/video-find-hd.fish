# completions for video-find-hd

complete -c video-find-hd -f
complete -c video-find-hd -l help -d 'Display help'
complete -c video-find-hd -l min-width -r -d 'Minimum video width in pixels'
complete -c video-find-hd -l min-height -r -d 'Minimum video height in pixels'
complete -c video-find-hd -l min-kbps-per-megapixel -r -d 'Minimum bitrate density in kilobits per second per megapixel'
complete -c video-find-hd -a "(__fish_complete_directories)" -d 'Directory to scan'
