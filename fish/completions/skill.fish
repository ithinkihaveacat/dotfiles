# Fish completion script for skill

# Helper functions for fetching options/skills
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

function __fish_skill_catalog
    skill catalog --json 2>/dev/null | jq -r '.name'
end

function __fish_skill_managed_skills
    # List the skills of the scope (and directory) already on the command line.
    set -l opts
    set -l tokens (commandline -opc)
    for i in (seq 2 (count $tokens))
        switch $tokens[$i]
            case --scope -C --directory
                set -a opts $tokens[$i] $tokens[(math $i + 1)]
            case '--scope=*' '--directory=*'
                set -a opts $tokens[$i]
        end
    end
    skill $opts list 2>/dev/null | string replace -r '\s.*' ''
end

# Complete subcommands
complete -f -c skill -n __fish_use_subcommand -a add -d 'Link a skill (path or catalog name)'
complete -f -c skill -n __fish_use_subcommand -a remove -d 'Remove a skill\'s links'
complete -f -c skill -n __fish_use_subcommand -a rm -d 'Remove a skill\'s links (alias of remove)'
complete -f -c skill -n __fish_use_subcommand -a list -d 'List linked skills in the chosen scope'
complete -f -c skill -n __fish_use_subcommand -a update -d 'Re-fetch plugin-provided catalog entries'
complete -f -c skill -n __fish_use_subcommand -a clean -d 'Remove all managed skills'
complete -f -c skill -n __fish_use_subcommand -a catalog -d 'List plugin-provided skills and sources'
complete -f -c skill -n __fish_use_subcommand -a resolve -d 'Print source path for a name'
complete -f -c skill -n __fish_use_subcommand -a bundle -d 'Package skills into an archive or directory'
complete -f -c skill -n __fish_use_subcommand -a doctor -d 'Check skill links and the catalog'
complete -f -c skill -n __fish_use_subcommand -a show -d 'Show details and metadata of a skill (alias: info)'
complete -f -c skill -n __fish_use_subcommand -a info -d 'Show details and metadata of a skill'

# list
complete -c skill -f -n '__fish_seen_subcommand_from list' -l json -d 'Emit JSON (name, origin, path)'

# bundle
complete -c skill -n '__fish_seen_subcommand_from bundle' -a '(__fish_skill_catalog)' -d 'Catalog skill'
complete -c skill -n '__fish_seen_subcommand_from bundle' -a '(__fish_skill_source_skills)' -d Skill
complete -c skill -n '__fish_seen_subcommand_from bundle' -a '(__fish_skill_managed_skills)' -d 'Managed skill'
complete -c skill -n '__fish_seen_subcommand_from bundle' -s o -l output -r -d 'Output destination path'
complete -c skill -n '__fish_seen_subcommand_from bundle' -l format -x -a 'zip tar.gz dir' -d 'Output format'
complete -c skill -n '__fish_seen_subcommand_from bundle' -s w -l workspace -d 'Bundle the skills linked in the workspace'
complete -c skill -n '__fish_seen_subcommand_from bundle' -a - -d 'Read skill specs from stdin'

# catalog
complete -c skill -f -n '__fish_seen_subcommand_from catalog' -l json -d 'Emit JSON (description, source, structure)'

# resolve
complete -f -c skill -n '__fish_seen_subcommand_from resolve' -a '(__fish_skill_catalog)' -d 'Catalog skill'
complete -f -c skill -n '__fish_seen_subcommand_from resolve' -a '(__fish_skill_source_skills)' -d Skill

# show (and info)
complete -f -c skill -n '__fish_seen_subcommand_from show info' -a '(__fish_skill_managed_skills)' -d 'Managed skill'
complete -f -c skill -n '__fish_seen_subcommand_from show info' -a '(__fish_skill_catalog)' -d 'Catalog skill'
complete -f -c skill -n '__fish_seen_subcommand_from show info' -a '(__fish_skill_source_skills)' -d Skill

# add
complete -c skill -n '__fish_seen_subcommand_from add' -a '(__fish_skill_catalog)'
complete -c skill -n '__fish_seen_subcommand_from add' -a '(__fish_skill_source_skills)' -d Skill
complete -c skill -f -n '__fish_seen_subcommand_from add' -l defaults -d 'Link every default through the defaults directory'
complete -c skill -f -n '__fish_seen_subcommand_from add' -s q -l quiet -d 'Report only errors'

# remove (and rm)
complete -c skill -f -n '__fish_seen_subcommand_from remove rm' -a '(__fish_skill_managed_skills)' -d 'Managed skill'

# update
complete -c skill -f -n '__fish_seen_subcommand_from update' -a '(__fish_skill_catalog)' -d 'Catalog skill'
complete -c skill -f -n '__fish_seen_subcommand_from update' -a '(__fish_skill_managed_skills)' -d 'Managed skill'
complete -c skill -f -n '__fish_seen_subcommand_from update' -l all -d 'Update every managed skill'
complete -c skill -f -n '__fish_seen_subcommand_from update' -l catalog -d 'Refresh the whole metadata index'

# Complete flags
complete -c skill -f -s h -l help -d 'Display help message and exit'
complete -c skill -s C -l directory -x -a '(__fish_complete_directories)' -d 'Run as if started in DIR'
complete -c skill -f -l scope -x -a 'user workspace session defaults' -d 'Where to install skills'
complete -c skill -f -l plugin-template -d 'Output a template for creating a Workspace plugin'
