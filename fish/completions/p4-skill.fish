# Fish completion script for p4-skill

# Helper functions for fetching options/skills
function __fish_p4_skill_source_skills
    set -l dirs $SKILL_SOURCE_DIRS
    test -z "$dirs"; and set dirs $HOME/.dotfiles/skills:$HOME/.private/skills:$HOME/.corp/skills
    for base in (string split : -- $dirs)
        test -d $base; or continue
        for d in $base/*/
            basename $d
        end
    end | sort -u
end

function __fish_p4_skill_catalog
    p4-skill catalog --json 2>/dev/null | jq -r '.[].name'
end

function __fish_p4_skill_managed_skills
    p4-skill list 2>/dev/null | string replace -r '\s*->.*' ''
end

# Complete subcommands
complete -f -c p4-skill -n __fish_use_subcommand -a add -d 'Add a skill (path or topic)'
complete -f -c p4-skill -n __fish_use_subcommand -a remove -d 'Remove a skill this tool added'
complete -f -c p4-skill -n __fish_use_subcommand -a rm -d 'Remove a skill this tool added (alias of remove)'
complete -f -c p4-skill -n __fish_use_subcommand -a list -d 'List managed skills in this workspace'
complete -f -c p4-skill -n __fish_use_subcommand -a update -d 'Re-fetch registered catalog entries'
complete -f -c p4-skill -n __fish_use_subcommand -a clean -d 'Remove all managed skills'
complete -f -c p4-skill -n __fish_use_subcommand -a catalog -d 'List registered skills and sources'
complete -f -c p4-skill -n __fish_use_subcommand -a resolve -d 'Print source path for a name'
complete -f -c p4-skill -n __fish_use_subcommand -a apply -d 'Provision skills for this workspace via skill-select'
complete -f -c p4-skill -n __fish_use_subcommand -a suggest -d 'Print skill-select recommendations without installing'
complete -f -c p4-skill -n __fish_use_subcommand -a doctor -d 'Diagnose drift between desired and on-disk skills'

# resolve: source skill names only
complete -f -c p4-skill -n '__fish_seen_subcommand_from resolve' -a '(__fish_p4_skill_source_skills)' -d Skill

# add
complete -c p4-skill -n '__fish_seen_subcommand_from add' -a '(__fish_p4_skill_catalog)'
complete -c p4-skill -n '__fish_seen_subcommand_from add' -a '(__fish_p4_skill_source_skills)' -d Skill

# remove (and rm)
complete -c p4-skill -f -n '__fish_seen_subcommand_from remove rm' -a '(__fish_p4_skill_managed_skills)' -d 'Managed skill'

# update
complete -c p4-skill -f -n '__fish_seen_subcommand_from update' -a '(__fish_p4_skill_catalog)' -d 'Registry skill'
complete -c p4-skill -f -n '__fish_seen_subcommand_from update' -a '(__fish_p4_skill_managed_skills)' -d 'Managed skill'
complete -c p4-skill -f -n '__fish_seen_subcommand_from update' -l all -d 'Update every managed skill'
complete -c p4-skill -f -n '__fish_seen_subcommand_from update' -l catalog -d 'Refresh the whole metadata index'

# Complete flags
complete -c p4-skill -f -l help -d 'Display help message and exit'
