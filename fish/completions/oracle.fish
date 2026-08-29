# Fish completion for oracle
complete -c oracle -l force -d "Bypass context size limits (1MB text, 20MB media)"
complete -c oracle -l maps -d "Use Google Maps grounding instead of Google Search"
complete -c oracle -l code -d "Enable Python code execution sandbox"
complete -c oracle -l dry-run -d "Output summary of payload without calling API"
complete -c oracle -l model -x -d "Gemini model to use (default: gemini-pro-latest)"
complete -c oracle -l serialize -d "Save payload and answer to state directory (default: on)"
complete -c oracle -l no-serialize -d "Disable saving payload and answer to state directory"
complete -c oracle -s h -l help -d "Display help message and exit"
