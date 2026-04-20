# completions for video-index

complete -c video-index -f
complete -c video-index -l help -d 'Display help'
complete -c video-index -l force -d 'Regenerate screenshots even if they already exist'
complete -c video-index -l output -r -d 'Directory where INDEX.md and screenshots are written'
complete -c video-index -a "(__fish_complete_directories)" -d 'Directory to scan'
