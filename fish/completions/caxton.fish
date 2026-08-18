complete -c caxton -f

complete -c caxton -a "(__fish_complete_directories)" -d "Source directory"

complete -c caxton -s i -l in-place -d "Apply transformations in-place on source directory"
complete -c caxton -s o -l output -r -a "(__fish_complete_directories)" -d "Copy source to directory first and operate on the copy"
complete -c caxton -s n -l dry-run -d "Print the payload that would be sent and exit"
complete -c caxton -l inline -d "Inline text files into initial prompt context (default)"
complete -c caxton -l no-inline -d "Pass only the file tree listing in initial prompt"
complete -c caxton -l force -d "Bypass safety checks (context threshold, dirty worktree)"
complete -c caxton -l model -x -d "Gemini model to use"
complete -c caxton -l thinking -x -a "high low none" -d "Thinking level (default: high)"
complete -c caxton -l search -d "Enable Google Search grounding for external context (default)"
complete -c caxton -l no-search -d "Disable Google Search grounding"
complete -c caxton -l code -d "Enable Python code execution in cloud sandbox (default)"
complete -c caxton -l no-code -d "Disable Python code execution in cloud sandbox"
complete -c caxton -l max-steps -x -d "Maximum agent execution steps (default: 100)"
complete -c caxton -l timeout -x -d "Maximum execution time in seconds (default: 1800)"
complete -c caxton -s h -l help -d "Display help message and exit"
