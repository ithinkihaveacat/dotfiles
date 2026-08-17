# Fish completion script for taskgo

function __fish_taskgo_projects
    set -l r (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$r"
        for p in $r/*/README.md $r/*/PROJECT.md
            if test -f "$p"
                basename (dirname $p)
            end
        end
    end
end

function __fish_taskgo_tasks
    set -l r (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$r"
        for t in $r/*/tasks/TASK-*.md
            if test -f "$t"
                set -l fname (basename $t .md)
                string match -r '^TASK-[0-9A-F]{5}' -- $fname
            end
        end
    end
end

# Complete subcommands
complete -f -c taskgo -n __fish_use_subcommand -a id -d 'Allocate a unique task ID'
complete -f -c taskgo -n __fish_use_subcommand -a create -d 'Create a new task'
complete -f -c taskgo -n __fish_use_subcommand -a list -d 'List tasks'
complete -f -c taskgo -n __fish_use_subcommand -a status -d 'Show project status'
complete -f -c taskgo -n __fish_use_subcommand -a sync -d 'Update STATUS.md snapshot'
complete -f -c taskgo -n __fish_use_subcommand -a doctor -d 'Run mechanical checks (read-only)'
complete -f -c taskgo -n __fish_use_subcommand -a fix -d 'Auto-heal task metadata and snapshots'
complete -f -c taskgo -n __fish_use_subcommand -a history -d 'Show frontmatter history'
complete -f -c taskgo -n __fish_use_subcommand -a checkpoint -d 'Commit an authorized tracker checkpoint'
complete -f -c taskgo -n __fish_use_subcommand -a commit -d 'Commit a logical transition'

# Subcommand arguments (Projects)
complete -f -c taskgo -n '__fish_seen_subcommand_from create list status sync doctor fix' -a '(__fish_taskgo_projects)' -d Project

# Subcommand arguments (Task IDs for history / checkpoint)
complete -f -c taskgo -n '__fish_seen_subcommand_from history checkpoint' -a '(__fish_taskgo_tasks)' -d 'Task ID'

# create options
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l status -x -a 'todo in-progress blocked done cancelled' -d 'Initial state'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l no-commit -d 'Create task and sync without committing'

# list options
complete -f -c taskgo -n '__fish_seen_subcommand_from list' -l state -x -a 'todo in-progress blocked done cancelled' -d 'Filter by state'

# fix options
complete -f -c taskgo -n '__fish_seen_subcommand_from fix' -l dry-run -d 'Preview repairs without modifying files'

# checkpoint options
complete -f -c taskgo -n '__fish_seen_subcommand_from checkpoint' -l path -r -d 'Include additional modified project file'
complete -f -c taskgo -n '__fish_seen_subcommand_from checkpoint' -l body -x -d 'Commit body'
complete -f -c taskgo -n '__fish_seen_subcommand_from checkpoint' -l ref -x -d 'External reference URL/ID'

# commit options
complete -f -c taskgo -n '__fish_seen_subcommand_from commit' -l body -x -d 'Commit body'
complete -f -c taskgo -n '__fish_seen_subcommand_from commit' -l ref -x -d 'External reference URL/ID'

# Global flags
complete -c taskgo -f -s h -l help -d 'Display help message and exit'
