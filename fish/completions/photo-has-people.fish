# completions for photo-has-people
complete -c photo-has-people -F -a '(__fish_complete_suffix .jpg .jpeg .png .heic .heif .webp .gif .tiff .tif)' -d 'Image file'
complete -c photo-has-people -s q -l quiet -d 'Suppress output; exit code only'
complete -c photo-has-people -s h -l help -d 'Display help'
