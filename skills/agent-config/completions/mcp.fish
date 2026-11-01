# Fish completion script for mcp

function __fish_mcp_servers
    mcp list --json 2>/dev/null | string match -r '"name": "[^"]*"' | string replace -r '.*"name": "([^"]*)"' '$1' | sort -u
end

function __fish_mcp_log_servers
    set -l state $XDG_STATE_HOME
    test -n "$state"; or set state ~/.local/state
    for log in $state/*/mcp.jsonl
        basename (dirname $log)
    end
end

set -l commands list ls add remove rm doctor logs
set -l config_commands list ls add remove rm doctor

complete -c mcp -f
complete -c mcp -s h -l help -d 'Show help and exit'

complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a list -d 'List configured servers per agent and scope'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a ls -d 'List configured servers (alias)'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a add -d 'Add a remote or stdio server'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a remove -d 'Remove servers'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a rm -d 'Remove servers (alias)'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a doctor -d 'Check each agent\'s MCP configuration'
complete -c mcp -n "not __fish_seen_subcommand_from $commands" -a logs -d "Print this repository's MCP servers' request records"

complete -c mcp -n "__fish_seen_subcommand_from $config_commands" -l agent -xa 'claude codex opencode' -d 'Operate on one agent'
complete -c mcp -n "__fish_seen_subcommand_from $config_commands" -l scope -xa 'user workspace' -d Scope
complete -c mcp -n "__fish_seen_subcommand_from list ls" -l json -d 'Print servers as JSON'
complete -c mcp -n "__fish_seen_subcommand_from add" -s e -l env -x -d 'Environment variable for a stdio server (KEY=VALUE)'
complete -c mcp -n "__fish_seen_subcommand_from add" -s H -l header -x -d "HTTP header for a remote server ('NAME: VALUE')"
complete -c mcp -n "__fish_seen_subcommand_from remove rm" -a '(__fish_mcp_servers)' -d Server

complete -c mcp -n "__fish_seen_subcommand_from logs" -F -d 'Log file or directory'
complete -c mcp -n "__fish_seen_subcommand_from logs" -s n -l tail -xa 'all 10 50 100' -d 'Print the last N records'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l since -xa '15m 1h 1d 1w' -d 'Only records from an age or time on'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l server -xa '(__fish_mcp_log_servers)' -d "Only this server's records"
complete -c mcp -n "__fish_seen_subcommand_from logs" -s f -l follow -d 'Keep printing records as they are written'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l json -d 'Print each record as a JSON line'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l summary -d 'Print statistics over the records'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l gap -x -d 'With --summary, the longest pause within a chain'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l serve -d 'Serve a live page of records and their summary'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l host -x -d 'With --serve, the HTTP address'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l port -x -d 'With --serve, the HTTP port'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l allow-host -x -d 'With --serve, also accept requests addressed to HOST'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l access-team -x -d 'Cloudflare Access team domain'
complete -c mcp -n "__fish_seen_subcommand_from logs" -l access-aud -x -d 'Cloudflare Access audience tag'
