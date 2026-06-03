# Fish completion script for git-setup

# Helper function: check if using git setup subcommand
function __fish_git_setup_using_command
    set -l cmd (commandline -opc)
    test (count $cmd) -gt 1; and test git = $cmd[1]; and test setup = $cmd[2]
end

# Register the "setup" subcommand under git
complete -f -c git -n __fish_git_needs_command -a setup -d "Configure the current git repository"

# Complete flags
complete -c git -f -n __fish_git_setup_using_command -l help -d 'Display help message and exit'
complete -c git -f -n __fish_git_setup_using_command -l force -d 'Overwrite a foreign commit-msg hook'
