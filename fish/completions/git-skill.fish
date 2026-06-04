# Fish completion script for git-skill

# Helper function: check if using git skill subcommand
function __fish_git_skill_using_command
    # Get the commandline arguments as list
    set -l cmd (commandline -opc)
    # Check that we have at least 3 arguments: "git", "skill", and the subcommand
    test (count $cmd) -gt 2; and test git = $cmd[1]; and test skill = $cmd[2]; and test $argv[1] = $cmd[3]
end

# Check if we need a subcommand for git skill
function __fish_git_skill_needs_command
    set -l cmd (commandline -opc)
    # If "git skill" is the current commandline (count=2)
    test (count $cmd) -eq 2; and test git = $cmd[1]; and test skill = $cmd[2]
end

# Register the "skill" subcommand under git
complete -f -c git -n __fish_git_needs_command -a skill -d "Manage per-workspace agent skills"

# Complete subcommands
complete -f -c git -n __fish_git_skill_needs_command -a add -d 'Add a skill (path or topic)'
complete -f -c git -n __fish_git_skill_needs_command -a remove -d 'Remove a skill this tool added'
complete -f -c git -n __fish_git_skill_needs_command -a rm -d 'Remove a skill this tool added (alias of remove)'
complete -f -c git -n __fish_git_skill_needs_command -a list -d 'List managed skills in this repo'
complete -f -c git -n __fish_git_skill_needs_command -a update -d 'Re-fetch registered catalog entries'
complete -f -c git -n __fish_git_skill_needs_command -a clean -d 'Remove all managed skills and the exclude block'
complete -f -c git -n __fish_git_skill_needs_command -a catalog -d 'List registered skills and sources'

complete -f -c git -n __fish_git_skill_needs_command -a resolve -d 'Print source path for a name'
complete -f -c git -n __fish_git_skill_needs_command -a apply -d 'Provision skills for this repository via skill-select'
complete -f -c git -n __fish_git_skill_needs_command -a suggest -d 'Print skill-select recommendations without installing'
complete -f -c git -n __fish_git_skill_needs_command -a status -d 'Report drift between desired and on-disk state'

# Helper functions for fetching options/skills
function __fish_git_skill_source_skills
    set -l dirs $SKILL_SOURCE_DIRS
    test -z "$dirs"; and set dirs $HOME/.dotfiles/skills:$HOME/.private/skills:$HOME/.corp/skills
    for base in (string split : -- $dirs)
        test -d $base; or continue
        for d in $base/*/
            basename $d
        end
    end | sort -u
end

function __fish_git_skill_catalog
    git skill catalog 2>/dev/null
end

function __fish_git_skill_managed_skills
    git skill list 2>/dev/null | string replace -r '\s*->.*' ''
end

# resolve: source skill names only
complete -f -c git -n '__fish_git_skill_using_command resolve' -a '(__fish_git_skill_source_skills)' -d Skill

complete -c git -n '__fish_git_skill_using_command add' -a '(__fish_git_skill_catalog)'
complete -c git -n '__fish_git_skill_using_command add' -a '(__fish_git_skill_source_skills)' -d Skill

# remove (and rm)
complete -c git -f -n '__fish_git_skill_using_command remove' -a '(__fish_git_skill_managed_skills)' -d 'Managed skill'
complete -c git -f -n '__fish_git_skill_using_command rm' -a '(__fish_git_skill_managed_skills)' -d 'Managed skill'

# update
complete -c git -f -n '__fish_git_skill_using_command update' -a '(__fish_git_skill_managed_skills)' -d 'Managed skill'
complete -c git -f -n '__fish_git_skill_using_command update' -l all -d 'Update every managed skill'

# Complete flags
complete -c git -f -n '__fish_git_skill_using_command skill' -l help -d 'Display help message and exit'
