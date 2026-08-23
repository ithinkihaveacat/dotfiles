# Fish completion script for taskgo

function __fish_taskgo_root
    if set -q TASKGO_ROOT
        echo $TASKGO_ROOT
    else
        echo $HOME/.projects
    end
end

function __fish_taskgo_projects
    set -l r (__fish_taskgo_root)
    for p in $r/*/README.md $r/*/PROJECT.md
        if test -f "$p"
            basename (dirname $p)
        end
    end
end

function __fish_taskgo_tasks
    set -l r (__fish_taskgo_root)
    for t in $r/*/tasks/TASK-*.md
        if test -f "$t"
            set -l fname (basename $t .md)
            string match -r '^TASK-[0-9A-F]{5}' -- $fname
        end
    end
end

# Complete subcommands
complete -f -c taskgo -n __fish_use_subcommand -a id -d 'Allocate a unique task ID'
complete -f -c taskgo -n __fish_use_subcommand -a root -d 'Print the active control repository root'
complete -f -c taskgo -n __fish_use_subcommand -a create -d 'Create a new task'
complete -f -c taskgo -n __fish_use_subcommand -a update -d 'Update task fields, status, or headings'
complete -f -c taskgo -n __fish_use_subcommand -a list -d 'List tasks'
complete -f -c taskgo -n __fish_use_subcommand -a status -d 'Show project status'
complete -f -c taskgo -n __fish_use_subcommand -a sync -d 'Update STATUS.md snapshot'
complete -f -c taskgo -n __fish_use_subcommand -a doctor -d 'Run mechanical checks (read-only)'
complete -f -c taskgo -n __fish_use_subcommand -a fix -d 'Auto-heal task metadata and snapshots'
complete -f -c taskgo -n __fish_use_subcommand -a history -d 'Show frontmatter history'
complete -f -c taskgo -n __fish_use_subcommand -a checkpoint -d 'Commit an authorized tracker checkpoint'
complete -f -c taskgo -n __fish_use_subcommand -a commit -d 'Commit a logical transition'

# Global flags
complete -c taskgo -n __fish_use_subcommand -l root -s R -r -d 'Control repository (default: ~/.projects)'
complete -c taskgo -f -s h -l help -d 'Display help message and exit'

# Subcommand arguments (Projects)
complete -f -c taskgo -n '__fish_seen_subcommand_from create list status sync doctor fix' -a '(__fish_taskgo_projects)' -d Project

# Subcommand arguments (Task IDs for update / history / checkpoint)
complete -f -c taskgo -n '__fish_seen_subcommand_from update history checkpoint' -a '(__fish_taskgo_tasks)' -d 'Task ID'

# create options
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l slug -x -d 'Filename mnemonic (max 32 chars)'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -s s -l status -x -a 'todo in-progress blocked done cancelled' -d 'Initial state'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -s p -l problem -x -d 'Problem description'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -s g -l goal -x -d 'Goal description'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -s c -l criteria -x -d 'Observable end condition'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l sketch -x -d 'Implementation sketch'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l constraints -x -d Constraints
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l outcome -x -d 'Outcome description'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l findings -x -d Findings
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l next -x -d 'Next steps'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -s C -l conv -l conversation -x -d 'Active conversation or session ID'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l no-commit -d 'Create task and sync without committing'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l dry-run -d 'Preview task path without creating files'

# update options
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s s -l status -x -a 'todo in-progress blocked done cancelled' -d 'New task state'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s t -l title -x -d 'New task title'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l slug -x -d 'Rename the task file slug (max 32 chars)'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s p -l problem -x -d 'Problem description'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s g -l goal -x -d 'Goal description'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s c -l criteria -x -d 'Observable end condition'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l sketch -x -d 'Implementation sketch'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l constraints -x -d Constraints
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l outcome -x -d 'Outcome description'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l findings -x -d Findings
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l next -x -d 'Next steps'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s C -l conv -l conversation -x -d 'Active conversation or session ID'

# list options
complete -f -c taskgo -n '__fish_seen_subcommand_from list' -s s -l state -l status -x -a 'todo in-progress blocked done cancelled' -d 'Filter by state'
complete -f -c taskgo -n '__fish_seen_subcommand_from list' -s j -l json -d 'Emit JSON output'

# status options
complete -f -c taskgo -n '__fish_seen_subcommand_from status' -s j -l json -d 'Emit JSON output'

# fix options
complete -f -c taskgo -n '__fish_seen_subcommand_from fix' -l dry-run -d 'Preview repairs without modifying files'
complete -f -c taskgo -n '__fish_seen_subcommand_from fix' -l no-commit -d 'Apply repairs without committing'

# checkpoint options
complete -f -c taskgo -n '__fish_seen_subcommand_from checkpoint' -s a -l all -d 'Stage all modified/untracked project files'
complete -c taskgo -n '__fish_seen_subcommand_from checkpoint' -s p -l path -r -d 'Include additional modified project file'
complete -f -c taskgo -n '__fish_seen_subcommand_from checkpoint' -s b -l body -x -d 'Commit body'
complete -f -c taskgo -n '__fish_seen_subcommand_from checkpoint' -s r -l ref -x -d 'External reference URL/ID'
complete -f -c taskgo -n '__fish_seen_subcommand_from checkpoint' -s C -l conv -l conversation -x -d 'Active conversation or session ID'

# commit options
complete -f -c taskgo -n '__fish_seen_subcommand_from commit' -s b -l body -x -d 'Commit body'
complete -f -c taskgo -n '__fish_seen_subcommand_from commit' -s r -l ref -x -d 'External reference URL/ID'
complete -f -c taskgo -n '__fish_seen_subcommand_from commit' -s C -l conv -l conversation -x -d 'Active conversation or session ID'
