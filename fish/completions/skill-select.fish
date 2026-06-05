# Fish completion script for skill-select

complete -c skill-select -l help -d "Display help message and exit"
complete -c skill-select -l context -r -d "Comprehensive, self-contained context to guide selection"
complete -c skill-select -l search-dirs -r -d "Colon-separated search directories (overrides environment)"
complete -c skill-select -l catalog -d "Print the full catalog of available skills and exit"
complete -c skill-select -l json -d "Emit structured output instead of bare names"
