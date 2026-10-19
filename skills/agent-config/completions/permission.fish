# Fish completion script for permission

function __fish_permission_cmd_patterns
    permission cmd list 2>/dev/null | string trim | string match -rv '^\[.*\]$|:$'
end

function __fish_permission_path_patterns
    permission path list 2>/dev/null | string trim | string match -rv '^\[.*\]$|:$'
end

# Complete namespaces and top-level commands
complete -f -c permission -n __fish_use_subcommand -a cmd -d 'Manage command permissions'
complete -f -c permission -n __fish_use_subcommand -a command -d 'Manage command permissions (alias)'
complete -f -c permission -n __fish_use_subcommand -a path -d 'Manage filesystem path permissions'
complete -f -c permission -n __fish_use_subcommand -a dir -d 'Manage filesystem path permissions (alias)'
complete -f -c permission -n __fish_use_subcommand -a list -d 'List all permission rules (commands and paths)'
complete -f -c permission -n __fish_use_subcommand -a ls -d 'List all permission rules (alias)'
complete -f -c permission -n __fish_use_subcommand -a apply -d 'Pre-approve safe commands and paths from installed skills'
complete -f -c permission -n __fish_use_subcommand -a clean -d 'Clear configured permission rules'
complete -f -c permission -n __fish_use_subcommand -a doctor -d 'Report missing or drifted rules'

# Namespace: cmd
complete -f -c permission -n '__fish_seen_subcommand_from cmd command' -a add -d 'Add command patterns'
complete -f -c permission -n '__fish_seen_subcommand_from cmd command' -a remove -d 'Remove command patterns'
complete -f -c permission -n '__fish_seen_subcommand_from cmd command' -a rm -d 'Remove command patterns (alias)'
complete -f -c permission -n '__fish_seen_subcommand_from cmd command' -a list -d 'List command patterns'
complete -f -c permission -n '__fish_seen_subcommand_from cmd command' -a ls -d 'List command patterns (alias)'
complete -f -c permission -n '__fish_seen_subcommand_from cmd command; and __fish_seen_subcommand_from add' -l deny -d 'Add to the denylist'
complete -f -c permission -n '__fish_seen_subcommand_from cmd command; and __fish_seen_subcommand_from add' -l ask -d 'Add to the ask list (always prompt)'
complete -f -c permission -n '__fish_seen_subcommand_from cmd command; and __fish_seen_subcommand_from remove rm' -a '(__fish_permission_cmd_patterns)' -d Pattern

# Namespace: path
complete -f -c permission -n '__fish_seen_subcommand_from path dir' -a add -d 'Grant filesystem path permissions'
complete -f -c permission -n '__fish_seen_subcommand_from path dir' -a remove -d 'Revoke filesystem path permissions'
complete -f -c permission -n '__fish_seen_subcommand_from path dir' -a rm -d 'Revoke filesystem path permissions (alias)'
complete -f -c permission -n '__fish_seen_subcommand_from path dir' -a list -d 'List granted filesystem paths'
complete -f -c permission -n '__fish_seen_subcommand_from path dir' -a ls -d 'List granted filesystem paths (alias)'
complete -f -c permission -n '__fish_seen_subcommand_from path dir; and __fish_seen_subcommand_from add' -l ro -l read-only -d 'Grant read-only access'
complete -f -c permission -n '__fish_seen_subcommand_from path dir; and __fish_seen_subcommand_from add' -l rw -l read-write -d 'Grant read-write access (default)'
complete -f -c permission -n '__fish_seen_subcommand_from path dir; and __fish_seen_subcommand_from add' -l workspace -l local -d 'Scope to workspace'
complete -f -c permission -n '__fish_seen_subcommand_from path dir; and __fish_seen_subcommand_from add' -l global -l user -d 'Scope user-wide (default)'
complete -c permission -n '__fish_seen_subcommand_from path dir; and __fish_seen_subcommand_from add' -a '(__fish_complete_directories)'
complete -f -c permission -n '__fish_seen_subcommand_from path dir; and __fish_seen_subcommand_from remove rm' -a '(__fish_permission_path_patterns)' -d Path

# Clean options
complete -f -c permission -n '__fish_seen_subcommand_from clean' -a 'cmd path' -d 'Target rules to clean'

# General options
complete -f -c permission -s h -l help -d 'Display help and exit'
complete -f -c permission -l plugin-template -d 'Output a template for creating a Permission plugin'
complete -x -c permission -l agent -a 'agy jetski jetski-web claude codex' -d 'Operate on a single agent backend'
