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
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l title -x -d Title
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l notes -x -d Notes
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l tags -x -d 'Tags, separated by spaces or commas'
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l public -d 'Make it public'
complete -f -c pinboard -n '__fish_pinboard_using_command add update' -l toread -d 'Mark it to read'
complete -f -c pinboard -n '__fish_pinboard_using_command update' -l private -d 'Make it private'
complete -f -c pinboard -n '__fish_pinboard_using_command update' -l read -d 'Mark it read'
complete -f -c pinboard -n '__fish_pinboard_using_command update' -l add-tag -x -d 'Add a tag'
complete -f -c pinboard -n '__fish_pinboard_using_command update' -l remove-tag -x -d 'Remove a tag'
