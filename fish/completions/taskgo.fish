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
complete -f -c taskgo -n __fish_use_subcommand -a apply -d 'Apply a change set to the working tree'
complete -f -c taskgo -n __fish_use_subcommand -a edit -d 'Replace exact text in a file'
complete -f -c taskgo -n __fish_use_subcommand -a list -d 'List tasks'
complete -f -c taskgo -n __fish_use_subcommand -a info -d 'Show project metadata from README.md frontmatter'
complete -f -c taskgo -n __fish_use_subcommand -a status -d 'Show project status'
complete -f -c taskgo -n __fish_use_subcommand -a handoff -d 'Print agent instructions for a project or task'
complete -f -c taskgo -n __fish_use_subcommand -a sync -d 'Update STATUS.md snapshot'
complete -f -c taskgo -n __fish_use_subcommand -a check -d 'Sweep wait_for gates and date horizons'
complete -f -c taskgo -n __fish_use_subcommand -a doctor -d 'Run mechanical checks (read-only)'
complete -f -c taskgo -n __fish_use_subcommand -a fix -d 'Auto-heal task metadata and snapshots'
complete -f -c taskgo -n __fish_use_subcommand -a history -d 'Show frontmatter history'
complete -f -c taskgo -n __fish_use_subcommand -a read -d 'Print lines of a file'
complete -f -c taskgo -n __fish_use_subcommand -a search -d 'Search file contents with git grep'
complete -f -c taskgo -n __fish_use_subcommand -a checkpoint -d 'Commit an authorized tracker checkpoint'
complete -f -c taskgo -n __fish_use_subcommand -a commit -d 'Commit a logical transition'
complete -f -c taskgo -n __fish_use_subcommand -a schema -d 'Show the task, decision, and STATUS schema'
complete -f -c taskgo -n __fish_use_subcommand -a mcp -d 'Serve the tracker to MCP clients'
complete -f -c taskgo -n __fish_use_subcommand -a requests -d "Summarise the MCP server's request log"

# Global flags
complete -c taskgo -n __fish_use_subcommand -l root -s R -r -d 'Control repository (default: ~/.projects)'
complete -c taskgo -f -s h -l help -d 'Display help message and exit'

# Subcommand arguments (Projects)
complete -f -c taskgo -n '__fish_seen_subcommand_from create list info status handoff handover sync check doctor fix' -a '(__fish_taskgo_projects)' -d Project

# Subcommand arguments (Task IDs for update / history / checkpoint)
complete -f -c taskgo -n '__fish_seen_subcommand_from update history checkpoint handoff handover' -a '(__fish_taskgo_tasks)' -d 'Task ID'

# create options
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l slug -x -d 'Filename mnemonic (max 32 chars)'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -s s -l status -x -a 'todo in-progress blocked done cancelled' -d 'Initial state'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -s p -l problem -x -d 'Problem description'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l cost -x -d 'Consequences of leaving the task undone'
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
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l wait-for -x -d 'External or temporal gate'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l due -x -d 'Committed completion deadline (YYYY-MM-DD)'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l stale-after -x -d 'Relevance cutoff date (YYYY-MM-DD)'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l add-blocked-by -x -a '(__fish_taskgo_tasks)' -d 'Add a blocked_by edge'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l add-wait-for -x -d 'Add a wait_for gate'
complete -f -c taskgo -n '__fish_seen_subcommand_from create' -l add-conversation -x -d 'Add a conversation URI'

# update options
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s s -l status -x -a 'todo in-progress blocked done cancelled' -d 'New task state'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l expect-status -x -a 'todo in-progress blocked done cancelled' -d 'Refuse unless current state matches'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l add-blocked-by -x -a '(__fish_taskgo_tasks)' -d 'Add a blocked_by edge'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l remove-blocked-by -x -a '(__fish_taskgo_tasks)' -d 'Remove a blocked_by edge'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l add-wait-for -x -d 'Add a wait_for gate'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l remove-wait-for -x -d 'Remove a wait_for gate'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l add-conversation -x -d 'Add a conversation URI'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l remove-conversation -x -d 'Remove a conversation URI'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s t -l title -x -d 'New task title'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l slug -x -d 'Rename the task file slug (max 32 chars)'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s p -l problem -x -d 'Problem description'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l cost -x -d 'Consequences of leaving the task undone'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s g -l goal -x -d 'Goal description'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s c -l criteria -x -d 'Observable end condition'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l sketch -x -d 'Implementation sketch'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l constraints -x -d Constraints
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l outcome -x -d 'Outcome description'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l findings -x -d Findings
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l next -x -d 'Next steps'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -s C -l conv -l conversation -x -d 'Active conversation or session ID'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l wait-for -x -d 'External or temporal gate'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l due -x -d 'Committed completion deadline (YYYY-MM-DD)'
complete -f -c taskgo -n '__fish_seen_subcommand_from update' -l stale-after -x -d 'Relevance cutoff date (YYYY-MM-DD)'

# apply options (CHANGES.json file, or - for standard input)
complete -c taskgo -n '__fish_seen_subcommand_from apply' -F -d 'Change set file'
complete -f -c taskgo -n '__fish_seen_subcommand_from apply' -l dry-run -d 'Print the diff and write nothing'

# edit options (PATH is relative to the control repository root)
complete -f -c taskgo -n '__fish_seen_subcommand_from edit' -a '(git -C (__fish_taskgo_root) ls-files 2>/dev/null)' -d File
complete -x -c taskgo -n '__fish_seen_subcommand_from edit' -l old -d 'Text to replace'
complete -x -c taskgo -n '__fish_seen_subcommand_from edit' -l new -d 'Replacement text'
complete -r -F -c taskgo -n '__fish_seen_subcommand_from edit' -l old-file -d 'Read the text to replace from FILE'
complete -r -F -c taskgo -n '__fish_seen_subcommand_from edit' -l new-file -d 'Read the replacement from FILE'
complete -f -c taskgo -n '__fish_seen_subcommand_from edit' -l replace-all -d 'Replace every occurrence'
complete -x -c taskgo -n '__fish_seen_subcommand_from edit' -l expected-blob -d "Refuse unless the file's blob SHA is SHA"
complete -f -c taskgo -n '__fish_seen_subcommand_from edit' -l dry-run -d 'Print the diff and write nothing'
complete -f -c taskgo -n '__fish_seen_subcommand_from edit' -s j -l json -d 'Emit JSON output'

# handoff options
complete -x -c taskgo -n '__fish_seen_subcommand_from handoff handover' -l at -d 'Read commit REV instead of HEAD'
complete -f -c taskgo -n '__fish_seen_subcommand_from handoff handover' -s j -l json -d 'Output the full payload as JSON'

# list options
complete -f -c taskgo -n '__fish_seen_subcommand_from list' -s s -l state -l status -x -a 'todo in-progress blocked done cancelled ready' -d 'Filter by state'
complete -f -c taskgo -n '__fish_seen_subcommand_from list' -s j -l json -d 'Emit JSON output'

# info, status, and check options
complete -f -c taskgo -n '__fish_seen_subcommand_from info status check' -s j -l json -d 'Emit JSON output'

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

# schema options
complete -f -c taskgo -n '__fish_seen_subcommand_from schema' -s j -l json -d 'Output as JSON'

# read options (PATH is relative to the control repository root)
complete -f -c taskgo -n '__fish_seen_subcommand_from read' -a '(git -C (__fish_taskgo_root) ls-files 2>/dev/null)' -d File
complete -x -c taskgo -n '__fish_seen_subcommand_from read' -l start-line -d 'First line (default 1)'
complete -x -c taskgo -n '__fish_seen_subcommand_from read' -l end-line -d 'Last line (default: the last)'
complete -x -c taskgo -n '__fish_seen_subcommand_from read' -l at -d 'Read commit REV instead of the working tree'
complete -f -c taskgo -n '__fish_seen_subcommand_from read' -s j -l json -d 'Emit JSON output'
complete -f -c taskgo -n '__fish_seen_subcommand_from read' -s n -l line-numbers -d 'Prefix each line with its number'

# search options (other arguments go to git grep; see 'taskgo search --help')
complete -x -c taskgo -n '__fish_seen_subcommand_from search' -l at -d 'Search commit REV instead of the working tree'
complete -f -c taskgo -n '__fish_seen_subcommand_from search' -s j -l json -d 'Emit JSON output'

# mcp options
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l host -x -d 'Address to listen on (default 127.0.0.1)'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l port -x -d 'Port to listen on (default 8789)'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l path -x -d 'Endpoint path (default /mcp)'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l remote -x -a '(git -C (__fish_taskgo_root) remote 2>/dev/null)' -d 'Remote to fetch from (default origin)'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l branch -x -d 'Branch to serve (default main)'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l no-fetch -d 'Serve the local branch without fetching'
complete -x -c taskgo -n '__fish_seen_subcommand_from mcp' -l fetch-ttl -d 'Seconds a fetched or pushed head serves reads'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l auth -x -a 'access none' -d 'Check Access JWTs, or nothing (loopback only)'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l access-team -x -d 'Access team domain'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l access-aud -x -d 'Access application audience (AUD) tag'
complete -f -c taskgo -n '__fish_seen_subcommand_from mcp' -l stdio -d 'Serve one client on stdin and stdout'
complete -r -c taskgo -n '__fish_seen_subcommand_from mcp' -l log -d 'Request log to append to'

# requests options
complete -r -c taskgo -n '__fish_seen_subcommand_from requests' -l log -d 'Request log to read'
complete -x -c taskgo -n '__fish_seen_subcommand_from requests' -l days -d 'Read the last N days of records (default 7)'
complete -x -c taskgo -n '__fish_seen_subcommand_from requests' -l gap -d 'Longest pause within a chain, in seconds'
complete -f -c taskgo -n '__fish_seen_subcommand_from requests' -s j -l json -d 'Emit JSON output'
