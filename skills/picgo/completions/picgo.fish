# Fish completion script for picgo

function __fish_picgo_needs_command
    set -l tokens (commandline -opc)
    set -e tokens[1]
    while set -q tokens[1]
        switch $tokens[1]
            case --dir
                set -e tokens[1]
            case '-*'
            case '*'
                return 1
        end
        set -e tokens[1]
    end
    return 0
end

function __fish_picgo_using_command
    set -l tokens (commandline -opc)
    set -e tokens[1]
    while set -q tokens[1]
        switch $tokens[1]
            case --dir
                set -e tokens[1]
            case '-*'
            case '*'
                contains -- $tokens[1] $argv
                return
        end
        set -e tokens[1]
    end
    return 1
end

# Commands
complete -f -c picgo -n __fish_picgo_needs_command -a upload -d 'Add images or videos'
complete -f -c picgo -n __fish_picgo_needs_command -a get -d 'Read the latest item, or ID, as bytes'
complete -f -c picgo -n __fish_picgo_needs_command -a list -d 'Show the stored items, newest first'
complete -f -c picgo -n __fish_picgo_needs_command -a delete -d 'Remove items'
complete -f -c picgo -n __fish_picgo_needs_command -a mcp -d 'Serve the store over MCP'
complete -f -c picgo -n __fish_picgo_needs_command -a doctor -d 'Check the store and image support'

# Global options
complete -c picgo -n __fish_picgo_needs_command -l dir -x -a '(__fish_complete_directories)' -d 'The store'
complete -f -c picgo -s h -l help -d 'Display help message and exit'

# Command options
complete -f -c picgo -n '__fish_picgo_using_command upload' -l json -d 'Print JSON'
complete -f -c picgo -n '__fish_picgo_using_command list' -l json -d 'Print JSON'
complete -f -c picgo -n '__fish_picgo_using_command get' -l json -d 'Print metadata, not bytes'
complete -c picgo -n '__fish_picgo_using_command get' -s o -l output -r -F -d 'Write to FILE'
complete -f -c picgo -n '__fish_picgo_using_command mcp' -l dir -x -a '(__fish_complete_directories)' -d 'The store'
complete -f -c picgo -n '__fish_picgo_using_command mcp' -l http -d 'Serve HTTP at /mcp, not stdio'
complete -c picgo -n '__fish_picgo_using_command mcp' -l host -x -d 'HTTP address'
complete -c picgo -n '__fish_picgo_using_command mcp' -l port -x -d 'HTTP port'
complete -f -c picgo -n '__fish_picgo_using_command mcp' -l allow-host -x -d "Also accept this host"
complete -f -c picgo -n '__fish_picgo_using_command mcp' -l access-team -x -d 'Cloudflare Access team domain'
complete -f -c picgo -n '__fish_picgo_using_command mcp' -l access-aud -x -d 'Cloudflare Access audience tag'
complete -c picgo -n '__fish_picgo_using_command mcp' -l log -r -F -d 'Request log'
complete -f -c picgo -n '__fish_picgo_using_command mcp' -s h -l help -d 'Display help message and exit'
