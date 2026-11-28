# Fish completion script for daybrief

function __fish_daybrief_needs_command
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

function __fish_daybrief_using_command
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
complete -f -c daybrief -n __fish_daybrief_needs_command -a init -d 'Initialize the Daybrief state directory'
complete -f -c daybrief -n __fish_daybrief_needs_command -a collect -d 'Build a read-only context snapshot'
complete -f -c daybrief -n __fish_daybrief_needs_command -a generate -d 'Generate and store a morning briefing'
complete -f -c daybrief -n __fish_daybrief_needs_command -a show -d 'Display the latest or named briefing'
complete -f -c daybrief -n __fish_daybrief_needs_command -a list -d 'List stored briefings, newest first'
complete -f -c daybrief -n __fish_daybrief_needs_command -a feedback -d 'Record explicit feedback or snooze'
complete -f -c daybrief -n __fish_daybrief_needs_command -a retro -d 'Run or roll back editorial retrospective'
complete -f -c daybrief -n __fish_daybrief_needs_command -a mcp -d 'Serve stored briefings over MCP'
complete -f -c daybrief -n __fish_daybrief_needs_command -a doctor -d 'Check store, constitution, and sources'

# Global options
complete -c daybrief -n __fish_daybrief_needs_command -l dir -x -a '(__fish_complete_directories)' -d 'State directory'
complete -f -c daybrief -s h -l help -d 'Display this help message and exit'

# init
complete -f -c daybrief -n '__fish_daybrief_using_command init' -l json -d 'Print JSON'

# collect
complete -c daybrief -n '__fish_daybrief_using_command collect' -l date -x -d 'Reference date (YYYY-MM-DD)'
complete -f -c daybrief -n '__fish_daybrief_using_command collect' -l pull -d 'Fetch managed mirror clones first'
complete -f -c daybrief -n '__fish_daybrief_using_command collect' -l json -d 'Print JSON'
complete -c daybrief -n '__fish_daybrief_using_command collect' -s o -l output -r -F -d 'Write to FILE'

# generate
complete -c daybrief -n '__fish_daybrief_using_command generate' -l date -x -d 'Briefing date (YYYY-MM-DD)'
complete -c daybrief -n '__fish_daybrief_using_command generate' -l model -x -d 'Model identifier'
complete -f -c daybrief -n '__fish_daybrief_using_command generate' -l pull -d 'Fetch managed mirror clones first'
complete -f -c daybrief -n '__fish_daybrief_using_command generate' -l dry-run -d 'Preview without recording state'
complete -f -c daybrief -n '__fish_daybrief_using_command generate' -l json -d 'Print JSON'
complete -c daybrief -n '__fish_daybrief_using_command generate' -s o -l output -r -F -d 'Write to FILE'

# show
complete -f -c daybrief -n '__fish_daybrief_using_command show' -l backstage -d 'Include silent Producer Packet'
complete -c daybrief -n '__fish_daybrief_using_command show' -l item -x -d 'Filter to one item ID'
complete -f -c daybrief -n '__fish_daybrief_using_command show' -l json -d 'Print JSON'
complete -c daybrief -n '__fish_daybrief_using_command show' -s o -l output -r -F -d 'Write to FILE'

# list
complete -c daybrief -n '__fish_daybrief_using_command list' -l limit -x -d 'Maximum rows'
complete -f -c daybrief -n '__fish_daybrief_using_command list' -l json -d 'Print JSON'

# feedback
complete -c daybrief -n '__fish_daybrief_using_command feedback' -l brief -x -d 'Briefing ID'
complete -c daybrief -n '__fish_daybrief_using_command feedback' -l item -x -d 'Item ID'
complete -f -c daybrief -n '__fish_daybrief_using_command feedback' -l kind -x -a 'note answer outcome preference snooze' -d 'Feedback kind'
complete -c daybrief -n '__fish_daybrief_using_command feedback' -l snooze-days -x -d 'Cooldown days when snoozing'
complete -f -c daybrief -n '__fish_daybrief_using_command feedback' -l json -d 'Print JSON'

# retro
complete -c daybrief -n '__fish_daybrief_using_command retro' -l days -x -d 'Lookback window in days'
complete -c daybrief -n '__fish_daybrief_using_command retro' -l model -x -d 'Model identifier'
complete -f -c daybrief -n '__fish_daybrief_using_command retro' -l dry-run -d 'Preview diff without writing'
complete -f -c daybrief -n '__fish_daybrief_using_command retro' -l rollback -d 'Restore previous editorial guidance'
complete -f -c daybrief -n '__fish_daybrief_using_command retro' -l json -d 'Print JSON'

# doctor
complete -f -c daybrief -n '__fish_daybrief_using_command doctor' -l json -d 'Print JSON'

# mcp
complete -c daybrief -n '__fish_daybrief_using_command mcp' -l dir -x -a '(__fish_complete_directories)' -d 'State directory'
complete -f -c daybrief -n '__fish_daybrief_using_command mcp' -l http -d 'Serve HTTP at /mcp, not stdio'
complete -c daybrief -n '__fish_daybrief_using_command mcp' -l host -x -d 'HTTP address'
complete -c daybrief -n '__fish_daybrief_using_command mcp' -l port -x -d 'HTTP port'
complete -f -c daybrief -n '__fish_daybrief_using_command mcp' -l allow-host -x -d 'Also accept this host'
complete -f -c daybrief -n '__fish_daybrief_using_command mcp' -l access-team -x -d 'Cloudflare Access team domain'
complete -f -c daybrief -n '__fish_daybrief_using_command mcp' -l access-aud -x -d 'Cloudflare Access audience tag'
complete -c daybrief -n '__fish_daybrief_using_command mcp' -l log -r -F -d 'Request log'
complete -f -c daybrief -n '__fish_daybrief_using_command mcp' -s h -l help -d 'Display this help message and exit'
