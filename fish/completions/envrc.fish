# Fish completion script for envrc

# Helper function: check if we need a command
function __fish_envrc_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

# Helper function: check if using specific command
function __fish_envrc_using_command
    set -l cmd (commandline -opc)
    test (count $cmd) -gt 1; and test $argv[1] = $cmd[2]
end

# Helper function: list available types
function __fish_envrc_types
    echo -e "git-identity-beebo\nnode\nfirebase\nappengine\ngit-hooks-agent"
end

# Complete subcommands
complete -c envrc -f -n __fish_envrc_needs_command -a add -d 'Add or update a configuration block'
complete -c envrc -f -n __fish_envrc_needs_command -a remove -d 'Remove a configuration block'
complete -c envrc -f -n __fish_envrc_needs_command -a rm -d 'Remove a configuration block'
complete -c envrc -f -n __fish_envrc_needs_command -a list -d 'List active configuration types in .envrc'
complete -c envrc -f -n __fish_envrc_needs_command -a types -d 'List available configuration types'

# Complete types for add and remove
complete -c envrc -f -n '__fish_envrc_using_command add' -a '(__fish_envrc_types)'
complete -c envrc -f -n '__fish_envrc_using_command remove' -a '(__fish_envrc_types)'
complete -c envrc -f -n '__fish_envrc_using_command rm' -a '(__fish_envrc_types)'

# Complete flags
complete -c envrc -f -l help -d 'Display help message and exit'
complete -c envrc -r -l output -d 'Path to the output file'
