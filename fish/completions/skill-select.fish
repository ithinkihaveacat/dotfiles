# Fish completion script for skill-select

complete -c skill-select -s h -l help -d "Display help message and exit"
complete -c skill-select -l context -r -d "Comprehensive, self-contained context to guide selection"
complete -c skill-select -l search-dirs -r -d "Colon-separated search directories (overrides environment)"
complete -c skill-select -l list -d "Print the full catalog of available skills and exit"
complete -c skill-select -l json -d "Emit structured output instead of bare names"
complete -c skill-select -l llm -d "Force the LLM fallback instead of using deterministic rules"
complete -c skill-select -l model -r -d "Gemini model ID to use (default: gemini-3.5-flash)"
