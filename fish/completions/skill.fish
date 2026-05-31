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

# Helper function: list skills available under any SKILL_SOURCE_DIRS entry
function __fish_skill_source_skills
    set -l dirs $SKILL_SOURCE_DIRS
    test -z "$dirs"; and set dirs $HOME/.dotfiles/skills:$HOME/.private/skills:$HOME/.corp/skills
    for base in (string split : -- $dirs)
        test -d $base; or continue
        for d in $base/*/
            basename $d
        end
    end | sort -u
end

# Helper function: list built-in skill sets as @name
function __fish_skill_sets
    skill sets 2>/dev/null | awk -F'\t' '{print $1}'
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
complete -c skill -f -n __fish_skill_needs_command -a sets -d 'List built-in skill sets'
complete -c skill -f -n __fish_skill_needs_command -a expand -d 'Print names a spec resolves to'
complete -c skill -f -n __fish_skill_needs_command -a resolve -d 'Print source path for a name'

# expand: accepts @sets and source skill names
complete -c skill -n '__fish_skill_using_command expand' -a '(__fish_skill_sets)' -d Set
complete -c skill -n '__fish_skill_using_command expand' -a '(__fish_skill_source_skills)' -d Skill

# resolve: source skill names only (no @sets, no topics)
complete -c skill -f -n '__fish_skill_using_command resolve' -a '(__fish_skill_source_skills)' -d Skill

# add: sets, registered topics, source skills, plus file completion for local paths
complete -c skill -n '__fish_skill_using_command add' -a '(__fish_skill_sets)' -d Set
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
