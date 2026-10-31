# Fish completion script for pinboard

function __fish_pinboard_needs_command
    set -l tokens (commandline -opc)
    set -e tokens[1]
    while set -q tokens[1]
        switch $tokens[1]
            case --repo
                set -e tokens[1]
            case '-*'
            case '*'
                return 1
        end
        set -e tokens[1]
    end
    return 0
end

function __fish_pinboard_using_command
    set -l tokens (commandline -opc)
    set -e tokens[1]
    while set -q tokens[1]
        switch $tokens[1]
            case --repo
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
complete -f -c pinboard -n __fish_pinboard_needs_command -a sync -d 'Bring the mirror up to date with Pinboard'
complete -f -c pinboard -n __fish_pinboard_needs_command -a search -d 'Search the mirror'
complete -f -c pinboard -n __fish_pinboard_needs_command -a get -d 'Show one bookmark from the mirror'
complete -f -c pinboard -n __fish_pinboard_needs_command -a tags -d 'List tags in the mirror'
complete -f -c pinboard -n __fish_pinboard_needs_command -a add -d 'Add a bookmark'
complete -f -c pinboard -n __fish_pinboard_needs_command -a update -d "Change a bookmark"
complete -f -c pinboard -n __fish_pinboard_needs_command -a restore -d 'Re-add a deleted bookmark'
complete -f -c pinboard -n __fish_pinboard_needs_command -a history -d "List a bookmark's versions"
complete -f -c pinboard -n __fish_pinboard_needs_command -a suggest -d 'Ask Pinboard for tag suggestions'
complete -f -c pinboard -n __fish_pinboard_needs_command -a doctor -d 'Check the token, clone and mirror'
complete -f -c pinboard -n __fish_pinboard_needs_command -a audit -d 'Check links for rot and tag the verdicts'
complete -f -c pinboard -n __fish_pinboard_needs_command -a mcp -d 'Serve the mirror to agents over MCP'

# Global options
complete -c pinboard -n __fish_pinboard_needs_command -l repo -x -a '(__fish_complete_directories)' -d 'The mirror clone'
complete -f -c pinboard -s h -l help -d 'Display help message and exit'

# Command options
complete -f -c pinboard -n '__fish_pinboard_using_command sync' -l full -d 'Fetch posts/all even if nothing changed'
complete -f -c pinboard -n '__fish_pinboard_using_command sync' -l force -d 'Delete without confirming each'
complete -f -c pinboard -n '__fish_pinboard_using_command sync add update restore' -l dry-run -d 'Change nothing'
complete -f -c pinboard -n '__fish_pinboard_using_command search' -l tag -x -d 'Only bookmarks with TAG'
complete -f -c pinboard -n '__fish_pinboard_using_command search' -l limit -x -d 'Results per page'
complete -f -c pinboard -n '__fish_pinboard_using_command search' -l cursor -x -d 'Continue from a previous page'
complete -f -c pinboard -n '__fish_pinboard_using_command search get tags history suggest doctor' -l json -d 'Print JSON'
complete -f -c pinboard -n '__fish_pinboard_using_command add update restore' -l title -x -d Title
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l notes -x -d Notes
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l tags -x -d 'Tags, separated by spaces or commas'
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l public -d 'Make it public'
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l toread -d 'Mark it to read'
complete -f -c pinboard -n '__fish_pinboard_using_command update' -l private -d 'Make it private'
complete -f -c pinboard -n '__fish_pinboard_using_command update' -l read -d 'Mark it read'
complete -f -c pinboard -n '__fish_pinboard_using_command update' -l add-tag -x -d 'Add a tag'
complete -f -c pinboard -n '__fish_pinboard_using_command update' -l remove-tag -x -d 'Remove a tag'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -a plan -d 'Freeze a work list from the mirror'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -a check -d 'Check planned URLs over HTTP'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -a apply -d 'Apply verdict tags through the API'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -a status -d 'Show pass progress'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -a verify -d 'Check the mirror agrees with the journal'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -a bump -d 'Move a cohort tag after a complete pass'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l state -a '(__fish_complete_directories)' -d 'Audit state root'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l pass -d 'Pass identifier'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l year -d 'Only bookmarks created in this year'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l cohort -d 'Cohort tag (.checked:YYYY)'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l limit -d 'Stop after N URLs'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l jobs -d 'Concurrent checks'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l timeout -d 'Per-request timeout'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l commit-every -d 'Commit the mirror every N writes'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l old -d 'Tag to rename from'
complete -x -c pinboard -n '__fish_pinboard_using_command audit' -l new -d 'Tag to rename to'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -l dry-run -d 'Change nothing'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -l json -d 'Print JSON'
complete -f -c pinboard -n '__fish_pinboard_using_command audit' -l force -d 'Replace or override'
complete -f -c pinboard -n '__fish_pinboard_using_command mcp' -l http -d 'Serve streamable HTTP, not stdio'
complete -f -c pinboard -n '__fish_pinboard_using_command mcp' -l host -x -d 'HTTP address'
complete -f -c pinboard -n '__fish_pinboard_using_command mcp' -l port -x -d 'HTTP port'
complete -f -c pinboard -n '__fish_pinboard_using_command mcp' -l allow-host -x -d 'Also accept requests addressed to HOST'
complete -f -c pinboard -n '__fish_pinboard_using_command mcp' -l access-team -x -d 'Cloudflare Access team domain'
complete -f -c pinboard -n '__fish_pinboard_using_command mcp' -l access-aud -x -d 'Cloudflare Access audience tag'
complete -f -c pinboard -n '__fish_pinboard_using_command mcp' -l sync-every -x -d 'Sync when the last sync is this many hours old'
complete -c pinboard -n '__fish_pinboard_using_command mcp' -l log -r -F -d 'Request log'
