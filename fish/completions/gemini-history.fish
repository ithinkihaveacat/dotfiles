# completions for gemini-history
complete -c gemini-history -f
complete -c gemini-history -s h -l help -d 'Display this help message and exit'
complete -c gemini-history -l dir -d 'Output the directory where history is stored and exit'

# Offer directories for the main argument
complete -c gemini-history -a "(__fish_complete_directories)"
