# Fish completion script for permission

function __fish_permission_patterns
    permission list 2>/dev/null | string trim | string match -rv '^\[.*\]$|:$'
end

# Complete subcommands
complete -f -c permission -n __fish_use_subcommand -a add -d 'Add permission rules'
complete -f -c permission -n __fish_use_subcommand -a remove -d 'Remove permission rules'
complete -f -c permission -n __fish_use_subcommand -a rm -d 'Remove permission rules (alias of remove)'
complete -f -c permission -n __fish_use_subcommand -a list -d 'List permission rules per agent'
complete -f -c permission -n __fish_use_subcommand -a ls -d 'List permission rules per agent (alias of list)'
complete -f -c permission -n __fish_use_subcommand -a apply -d 'Pre-approve safe commands from installed skills'
complete -f -c permission -n __fish_use_subcommand -a clean -d 'Clear all workspace permission rules'
complete -f -c permission -n __fish_use_subcommand -a doctor -d 'Report missing or drifted rules'

# Options
complete -f -c permission -l help -d 'Display help and exit'
complete -x -c permission -l agent -a 'agy claude' -d 'Operate on a single agent backend'
complete -f -c permission -n '__fish_seen_subcommand_from add' -l deny -d 'Add to the denylist'
complete -f -c permission -n '__fish_seen_subcommand_from add' -l ask -d 'Add to the ask list (Claude Code only)'

# remove: complete from currently configured patterns
complete -f -c permission -n '__fish_seen_subcommand_from remove rm' -a '(__fish_permission_patterns)' -d Pattern
