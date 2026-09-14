# completions for markdown-clean
complete -c markdown-clean -s h -l help -d 'Display help and exit'
complete -c markdown-clean -s o -l output -r -d 'Path to write output file'
complete -c markdown-clean -s n -l dry-run -d 'Preview changes without modifying files'
complete -c markdown-clean -l check -d 'Check if inputs would be changed (exit 1 if dirty)'
complete -c markdown-clean -s q -l quiet -d 'Suppress summary statistics on stderr'
complete -c markdown-clean -l keep-dividers -d "Preserve horizontal rule dividers ('---')"
