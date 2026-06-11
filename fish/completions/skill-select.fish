# Fish completion script for skill-select

complete -c skill-select -l help -d "Display help message and exit"
complete -c skill-select -l context -r -d "Comprehensive, self-contained context to guide selection"
complete -c skill-select -l search-dirs -r -d "Colon-separated search directories (overrides environment)"
complete -c skill-select -l catalog -d "Print the full catalog of available skills and exit"
complete -c skill-select -l json -d "Emit structured output instead of bare names"
complete -c skill-select -l update -d "Re-fetch a plugin-provided catalog entry by name"
complete -c skill-select -l doctor -d "Diagnose drift between desired and on-disk skills"
complete -c skill-select -l resolve -r -d "Print the source path for a skill"
complete -c skill-select -l repair -d "Repair catalog index (heal missing stubs)"
complete -c skill-select -l plugin-template -d "Output a template for creating a Python plugin"
