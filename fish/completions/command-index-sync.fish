complete -c command-index-sync -l help -d "Display help message and exit"
complete -c command-index-sync -l check -d "Do not write; exit 1 if any file is stale"
complete -c command-index-sync -l all -d "Process every *.md with generated markers under the current directory"
complete -c command-index-sync -a "(__fish_complete_suffix .md)" -d "Markdown file"
