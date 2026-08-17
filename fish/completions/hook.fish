complete -c hook -f

complete -c hook -n __fish_use_subcommand -a apply -d 'Synchronize hooks to match AGENT_REQUIRED_HOOKS'
complete -c hook -n __fish_use_subcommand -a add -d 'Add a hook profile'
complete -c hook -n __fish_use_subcommand -a remove -d 'Remove a hook profile'
complete -c hook -n __fish_use_subcommand -a rm -d 'Remove a hook profile'
complete -c hook -n __fish_use_subcommand -a list -d 'List the hook profiles installed in this repository'
complete -c hook -n __fish_use_subcommand -a ls -d 'List the hook profiles installed in this repository'
complete -c hook -n __fish_use_subcommand -a catalog -d 'List the hook profiles available to add'
complete -c hook -n __fish_use_subcommand -a doctor -d 'Report missing, drifted or unmanaged hooks (read-only)'
complete -c hook -n __fish_use_subcommand -a clean -d 'Remove every profile this tool manages'

# Profile names, completed for the commands that take one.
complete -c hook -n '__fish_seen_subcommand_from add remove rm' -a agent -d 'Commit message format and trailer hygiene'
complete -c hook -n '__fish_seen_subcommand_from add remove rm' -a markdown -d 'markdown-format verification of staged .md files'
complete -c hook -n '__fish_seen_subcommand_from add remove rm' -a node -d 'prettier formatting of staged .ts and .md files'
complete -c hook -n '__fish_seen_subcommand_from add remove rm' -a gerrit -d 'Gerrit Change-Id trailer'

complete -c hook -n '__fish_seen_subcommand_from add apply' -l copy -d 'Copy the hook source instead of installing a trampoline'
complete -c hook -n '__fish_seen_subcommand_from clean' -l all -d 'Delete the entire hooks directory (requires --force)'
complete -c hook -n '__fish_seen_subcommand_from clean' -l force -d 'Confirm the deletion'
complete -c hook -s h -l help -d 'Display help message and exit'
