# completions for markdown-format
complete -c markdown-format -F -a '(__fish_complete_suffix .md .markdown)' -d 'Markdown file'
complete -c markdown-format -s h -l help -d 'Display help'
complete -c markdown-format -l mdx -d 'Use MDX parser to format text inside HTML-like tags'
