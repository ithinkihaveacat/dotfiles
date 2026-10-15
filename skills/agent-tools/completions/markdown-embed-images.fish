# completions for markdown-embed-images
complete -c markdown-embed-images -s h -l help -d 'Display help and exit'
complete -c markdown-embed-images -s o -l output -r -d 'Path to write output file'
complete -c markdown-embed-images -l max-size-kb -r -d 'Maximum total Base64 image payload in kilobytes (default: 300)'
complete -c markdown-embed-images -s n -l dry-run -d 'Preview actions without modifying or creating files'
