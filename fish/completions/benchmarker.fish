complete -c benchmarker -f

complete -c benchmarker -s c -l cmd -r -d "Command template with {placeholders}"
complete -c benchmarker -s d -l dim -x -d "Define a dimension (e.g. script=v0,v1)"
complete -c benchmarker -s t -l tasks -r -F -d "Task fixtures directory"
complete -c benchmarker -s o -l output-dir -r -F -d "Directory for output artifacts (default: .benchmarks)"
complete -c benchmarker -s n -l trials -x -d "Number of trials per permutation (default: 1)"
complete -c benchmarker -s j -l workers -x -d "Maximum concurrent worker processes (default: 4)"
complete -c benchmarker -l timeout -x -d "Execution timeout per run in seconds (default: 600)"
complete -c benchmarker -l dry-run -d "Print resolved list of runs without executing"
complete -c benchmarker -s h -l help -d "Display help message and exit"
