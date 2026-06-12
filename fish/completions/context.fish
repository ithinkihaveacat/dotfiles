# Fish completion script for context

# Helper function: check if we need a subcommand
function __fish_context_needs_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 1
        return 0
    end
    return 1
end

# Helper function: check if we are completing for a specific subcommand
function __fish_context_using_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -gt 1; and test "$cmd[2]" = "$argv[1]"
        return 0
    end
    return 1
end

# Helper function: get list of available catalog entries
function __fish_context_list_catalog
    context catalog 2>/dev/null
end

# Disable file completion by default for subcommands
complete -c context -f -n __fish_context_needs_command

# Complete subcommands
complete -c context -f -n __fish_context_needs_command -a catalog -d 'List available catalog entries'
complete -c context -f -n __fish_context_needs_command -a show -d 'Show context for a target'
complete -c context -f -n __fish_context_needs_command -a template -d 'Output a template for creating a Python plugin'
complete -c context -f -n __fish_context_needs_command -a help -d 'Display help message'

# Complete entries for 'show' subcommand
# We allow file completion (no -f) so users can complete local directories,
# but we also suggest catalog entries.
complete -c context -n '__fish_context_using_command show' -a '(__fish_context_list_catalog)' -d 'Catalog Entry'
complete -c context -l force -n '__fish_context_using_command show' -d 'Force cache rebuild'

# Complete subcommands for 'help' subcommand
complete -c context -f -n '__fish_context_using_command help' -a 'catalog show template'
