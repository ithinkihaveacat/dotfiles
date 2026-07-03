# Fish completion script for envrc

# Helper function: parse the command line to extract the subcommand and its arguments,
# skipping options/flags and their arguments.
function __fish_envrc_parse
    set -l cmd (commandline -opc)
    set -e cmd[1] # Remove 'envrc'

    set -l subcommand ""
    set -l subcommand_args
    set -l i 1
    while test $i -le (count $cmd)
        switch $cmd[$i]
            case --output
                set i (math $i + 2)
            case --help
                set i (math $i + 1)
            case '-*'
                set i (math $i + 1)
            case '*'
                set subcommand $cmd[$i]
                if test $i -lt (count $cmd)
                    set subcommand_args $cmd[(math $i + 1)..-1]
                end
                break
        end
    end

    echo "$subcommand"
    for arg in $subcommand_args
        echo "$arg"
    end
end

# Helper function: check if we need a subcommand
function __fish_envrc_needs_command
    set -l parsed (__fish_envrc_parse)
    test (count $parsed) -eq 0
end

# Helper function: check if we are completing the block type for create/delete
function __fish_envrc_needs_type
    set -l parsed (__fish_envrc_parse)
    test (count $parsed) -eq 1; and contains "$parsed[1]" create delete
end

# Helper function: check if we are completing the list type for add/remove/list
function __fish_envrc_needs_list_type
    set -l parsed (__fish_envrc_parse)
    test (count $parsed) -eq 1; and contains "$parsed[1]" add remove rm list
end

# Helper function: check if we are completing the node version
function __fish_envrc_needs_node_version
    set -l parsed (__fish_envrc_parse)
    test (count $parsed) -eq 2; and test "$parsed[1]" = create; and test "$parsed[2]" = node
end

# Helper function: check if we are completing the ruby version
function __fish_envrc_needs_ruby_version
    set -l parsed (__fish_envrc_parse)
    test (count $parsed) -eq 2; and test "$parsed[1]" = create; and test "$parsed[2]" = ruby
end

# Helper function: list available types
function __fish_envrc_types
    echo -e "git-identity-beebo\nnode\nruby\nfirebase\nappengine\nskills"
end

# Helper function: list local Node.js versions
function __fish_envrc_node_versions
    if test -n "$NODE_VERSIONS"; and test -d "$NODE_VERSIONS"
        for d in $NODE_VERSIONS/node-*
            set -l full (string replace -r '^.*/node-v' '' $d | string replace -r '/$' '')
            set -l major (string split -m 1 . $full)[1]
            echo $full
            echo $major
        end | sort -un
    end
end

# Helper function: list local Ruby versions
function __fish_envrc_ruby_versions
    if test -n "$RUBY_VERSIONS"; and test -d "$RUBY_VERSIONS"
        for d in $RUBY_VERSIONS/ruby-*
            set -l full (string replace -r '^.*/ruby-v' '' $d | string replace -r '/$' '')
            set -l major (string split -m 1 . $full)[1]
            echo $full
            echo $major
        end | sort -un
    end
end

# Disable file completion by default
complete -c envrc -f

# Complete subcommands
complete -c envrc -n __fish_envrc_needs_command -a create -d 'Create a configuration block'
complete -c envrc -n __fish_envrc_needs_command -a delete -d 'Delete an entire configuration block'
complete -c envrc -n __fish_envrc_needs_command -a add -d 'Add skills to the skills block'
complete -c envrc -n __fish_envrc_needs_command -a remove -d 'Remove skills from the skills block'
complete -c envrc -n __fish_envrc_needs_command -a rm -d 'Remove skills from the skills block'
complete -c envrc -n __fish_envrc_needs_command -a list -d 'List active blocks or skills'
complete -c envrc -n __fish_envrc_needs_command -a catalog -d 'List available configuration types'
complete -c envrc -n __fish_envrc_needs_command -a help -d 'Display help message and exit'

# Complete types for create, delete
complete -c envrc -n __fish_envrc_needs_type -a '(__fish_envrc_types)'

# Complete list-valued types for add, remove, rm, list
complete -c envrc -n __fish_envrc_needs_list_type -a skills -d 'Agent skills list'

# Complete node versions
complete -c envrc -n __fish_envrc_needs_node_version -a '(__fish_envrc_node_versions)'

# Complete ruby versions
complete -c envrc -n __fish_envrc_needs_ruby_version -a '(__fish_envrc_ruby_versions)'

# Complete global flags
complete -c envrc -l help -d 'Display help message and exit'
complete -c envrc -r -l output -d 'Path to the output file'
