# Fish completion script for mcp

function __fish_mcp_servers
    mcp list --json 2>/dev/null | string match -r '"name": "[^"]*"' | string replace -r '.*"name": "([^"]*)"' '$1' | sort -u
end

set -l commands list ls add remove rm doctor

complete -c mcp -f
complete -c mcp -s h -l help -d 'Show help and exit'

complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a list -d 'List configured servers per agent and scope'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a ls -d 'List configured servers (alias)'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a add -d 'Add a remote or stdio server'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a remove -d 'Remove servers'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a rm -d 'Remove servers (alias)'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a doctor -d 'Check each agent\'s MCP configuration'

complete -c mcp -n "__fish_seen_subcommand_from $commands" -l agent -xa 'claude codex opencode' -d 'Operate on one agent'
complete -c mcp -n "__fish_seen_subcommand_from $commands" -l scope -xa 'user workspace' -d Scope
complete -c mcp -n "__fish_seen_subcommand_from list ls" -l json -d 'Print servers as JSON'
complete -c mcp -n "__fish_seen_subcommand_from add" -s e -l env -x -d 'Environment variable for a stdio server (KEY=VALUE)'
complete -c mcp -n "__fish_seen_subcommand_from add" -s H -l header -x -d "HTTP header for a remote server ('NAME: VALUE')"
complete -c mcp -n "__fish_seen_subcommand_from remove rm" -a '(__fish_mcp_servers)' -d Server
