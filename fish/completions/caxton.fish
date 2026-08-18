complete -c caxton -f

complete -c caxton -s o -l output -r -d "Copy source to directory first and operate on the copy"
complete -c caxton -l inline -d "Inline text files into initial prompt context (default)"
complete -c caxton -l no-inline -d "Pass only the file tree listing in initial prompt"
complete -c caxton -l force -d "Bypass the 1MB text context threshold for inlining"
complete -c caxton -l read-only -d "Disable file modification tools (inspection/audit only)"
complete -c caxton -l model -x -d "Gemini model to use"
complete -c caxton -l thinking -x -a "high low none" -d "Thinking level (default: high)"
complete -c caxton -l max-steps -x -d "Maximum agent execution steps (default: 100)"
complete -c caxton -l timeout -x -d "Maximum execution time in seconds (default: 300)"
complete -c caxton -s h -l help -d "Display help message and exit"
