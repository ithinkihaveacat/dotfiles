# Fish completion script for skill

# Helper function: check if we need a command
function __fish_skill_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

# Helper function: check if using specific command
function __fish_skill_using_command
    set -l cmd (commandline -opc)
    test (count $cmd) -gt 1; and test $argv[1] = $cmd[2]
end

# Helper function: list skills available under SKILL_SOURCE_DIR
function __fish_skill_source_skills
    set -l base $SKILL_SOURCE_DIR
    test -z "$base"; and set base $HOME/.agents/skills
    test -d $base; or return 0
    for d in $base/*/
        basename $d
    end
end

# Helper function: list registered topics (name<tab>source)
function __fish_skill_topics
    skill topics 2>/dev/null
end

# Helper function: list skills this tool manages in the current repo
function __fish_skill_managed_skills
    skill list 2>/dev/null
end

# Complete subcommands (when no subcommand given)
complete -c skill -f -n __fish_skill_needs_command -a add -d 'Add a skill (path or topic)'
complete -c skill -f -n __fish_skill_needs_command -a remove -d 'Remove a skill this tool added'
complete -c skill -f -n __fish_skill_needs_command -a list -d 'List managed skills in this repo'
complete -c skill -f -n __fish_skill_needs_command -a update -d 'Re-fetch registered topics'
complete -c skill -f -n __fish_skill_needs_command -a clean -d 'Remove all managed skills and the exclude block'
complete -c skill -f -n __fish_skill_needs_command -a topics -d 'List registered topics and sources'

# add: registered topics and source skills, plus file completion for local paths
complete -c skill -n '__fish_skill_using_command add' -a '(__fish_skill_topics)'
complete -c skill -n '__fish_skill_using_command add' -a '(__fish_skill_source_skills)' -d Skill

# remove (and its rm alias): suggest skills we currently manage
complete -c skill -f -n '__fish_skill_using_command remove' -a '(__fish_skill_managed_skills)' -d 'Managed skill'
complete -c skill -f -n '__fish_skill_using_command rm' -a '(__fish_skill_managed_skills)' -d 'Managed skill'

# update: managed skills, plus --all
complete -c skill -f -n '__fish_skill_using_command update' -a '(__fish_skill_managed_skills)' -d 'Managed skill'
complete -c skill -f -n '__fish_skill_using_command update' -l all -d 'Update every managed skill'

# Complete flags
complete -c skill -f -l help -d 'Display help message and exit'
