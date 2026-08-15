# Fish completion script for taskgo

function __fish_taskgo_projects
    set -l r (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$r"
        for p in $r/*/PROJECT.md
            basename (dirname $p)
        end
    end
end

# Complete subcommands
complete -f -c taskgo -n __fish_use_subcommand -a id -d 'Allocate a unique task ID'
complete -f -c taskgo -n __fish_use_subcommand -a new-task -d 'Create a new task'
complete -f -c taskgo -n __fish_use_subcommand -a tasks -d 'List tasks'
complete -f -c taskgo -n __fish_use_subcommand -a status -d 'Show project status'
complete -f -c taskgo -n __fish_use_subcommand -a sync-status -d 'Update STATUS.md snapshot'
complete -f -c taskgo -n __fish_use_subcommand -a doctor -d 'Run mechanical checks'
complete -f -c taskgo -n __fish_use_subcommand -a history -d 'Show frontmatter history'
complete -f -c taskgo -n __fish_use_subcommand -a commit -d 'Commit a logical transition'

# Subcommand arguments (Projects)
complete -f -c taskgo -n '__fish_seen_subcommand_from new-task tasks status sync-status doctor' -a '(__fish_taskgo_projects)' -d Project

# new-task options
complete -f -c taskgo -n '__fish_seen_subcommand_from new-task' -l status -x -a 'todo in-progress blocked done cancelled' -d 'Initial state'

# tasks options
complete -f -c taskgo -n '__fish_seen_subcommand_from tasks' -l state -x -a 'todo in-progress blocked done cancelled' -d 'Filter by state'

# commit options
complete -f -c taskgo -n '__fish_seen_subcommand_from commit' -l body -x -d 'Commit body'
complete -f -c taskgo -n '__fish_seen_subcommand_from commit' -l ref -x -d 'External reference URL/ID'

# Global flags
complete -c taskgo -f -s h -l help -d 'Display help message and exit'
