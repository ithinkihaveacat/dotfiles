# Fish completion script for skill-select

function __fish_skill_select_catalog
    skill-select catalog --json 2>/dev/null | jq -r '.[].name'
end

# Complete subcommands
complete -f -c skill-select -n __fish_use_subcommand -a suggest -d 'Recommend skills for a directory via the Gemini API'
complete -f -c skill-select -n __fish_use_subcommand -a catalog -d 'List every available skill and its source'
complete -f -c skill-select -n __fish_use_subcommand -a resolve -d 'Print the source path for a skill'
complete -f -c skill-select -n __fish_use_subcommand -a update -d 'Re-fetch plugin-provided catalog entries'
complete -f -c skill-select -n __fish_use_subcommand -a doctor -d 'Diagnose drift in the catalog index'
complete -f -c skill-select -n __fish_use_subcommand -a repair -d 'Repair the catalog index (heal missing stubs)'

# suggest
complete -c skill-select -n '__fish_seen_subcommand_from suggest' -l context -r -d 'Self-contained context to guide selection'
complete -c skill-select -n '__fish_seen_subcommand_from suggest' -l search-dirs -r -d 'Colon-separated skill search directories'
complete -c skill-select -f -n '__fish_seen_subcommand_from suggest' -l json -d 'Emit structured output'

# catalog
complete -c skill-select -f -n '__fish_seen_subcommand_from catalog' -l json -d 'Emit structured output'
complete -c skill-select -n '__fish_seen_subcommand_from catalog' -l search-dirs -r -d 'Colon-separated skill search directories'

# resolve
complete -c skill-select -f -n '__fish_seen_subcommand_from resolve' -a '(__fish_skill_select_catalog)' -d 'Catalog skill'
complete -c skill-select -n '__fish_seen_subcommand_from resolve' -l search-dirs -r -d 'Colon-separated skill search directories'

# update
complete -c skill-select -f -n '__fish_seen_subcommand_from update' -a '(__fish_skill_select_catalog)' -d 'Catalog skill'
complete -c skill-select -f -n '__fish_seen_subcommand_from update' -a catalog -d 'Refresh the whole metadata index'

# Complete flags
complete -c skill-select -f -l help -d 'Display help message and exit'
complete -c skill-select -f -l plugin-template -d 'Output a template for creating a skill-select plugin'
