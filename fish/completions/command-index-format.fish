complete -c command-index-format -s h -l help -d "Display help message and exit"
complete -c command-index-format -l check -d "Do not write; exit 1 if any file is stale"
complete -c command-index-format -l all -d "Process every *.md with generated markers under the current directory"
complete -c command-index-format -a "(__fish_complete_suffix .md)" -d "Markdown file"
