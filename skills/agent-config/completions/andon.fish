# Fish completion script for andon

function __fish_andon_ids
    # Open alerts, newest first: the 4-character suffix with the summary.
    andon list --status all 2>/dev/null | string replace -r '^(\S+)\s+\S+\s+L\d\s+(.*)$' '$1\t$2'
end

set -l commands pull list show prompt resolve dismiss reopen stats level clear-resolved mcp
set -l colors yellow red
set -l kinds skill_contradiction rule_conflict stale_instruction stuck_loop tool_anomaly environment_block other

complete -c andon -f
complete -c andon -s h -l help -d 'Show help and exit'

complete -c andon -n "not __fish_seen_subcommand_from $commands" -a pull -d 'Pull the cord: record a new alert'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a list -d 'List alerts, newest first'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a show -d 'Show one alert in full'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a prompt -d 'Print a fix prompt for an alert'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a resolve -d 'Mark an alert resolved'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a dismiss -d 'Mark an alert dismissed'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a reopen -d 'Reopen a closed alert'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a stats -d 'Count alerts'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a level -d 'Print or set the default trigger level'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a clear-resolved -d 'Delete resolved and dismissed alerts'
complete -c andon -n "not __fish_seen_subcommand_from $commands" -a mcp -d 'Serve Andon tools over MCP'
complete -c andon -n "__fish_seen_subcommand_from mcp" -l stdio -d 'Use stdin/stdout (the default)'

# pull
complete -c andon -n "__fish_seen_subcommand_from pull" -l color -xa "$colors" -d Severity
complete -c andon -n "__fish_seen_subcommand_from pull" -l kind -xa "$kinds" -d 'Kind of defect'
complete -c andon -n "__fish_seen_subcommand_from pull" -l summary -x -d 'One-line headline'
complete -c andon -n "__fish_seen_subcommand_from pull" -l details -x -d 'What conflicted or failed'
complete -c andon -n "__fish_seen_subcommand_from pull" -l source -rF -d 'File, rule or tool involved'
complete -c andon -n "__fish_seen_subcommand_from pull" -l resolution -x -d 'Workaround or decision needed'
complete -c andon -n "__fish_seen_subcommand_from pull" -l proposed-fix -x -d 'Edit that would remove the defect'
complete -c andon -n "__fish_seen_subcommand_from pull" -l level -xa "1 2 3 4 5" -d 'Trigger level'
complete -c andon -n "__fish_seen_subcommand_from pull" -l json -d 'Print the response as JSON'

# list
complete -c andon -n "__fish_seen_subcommand_from list" -l status -xa "open resolved dismissed all" -d Status
complete -c andon -n "__fish_seen_subcommand_from list" -l color -xa "$colors" -d Severity
complete -c andon -n "__fish_seen_subcommand_from list" -l kind -xa "$kinds" -d 'Kind of defect'
complete -c andon -n "__fish_seen_subcommand_from list" -l level -xa "1 2 3 4 5" -d 'Trigger level'
complete -c andon -n "__fish_seen_subcommand_from list" -l workspace -xa "(__fish_complete_directories)" -d 'Only alerts pulled in DIR'
complete -c andon -n "__fish_seen_subcommand_from list" -l session -x -d 'Only alerts from session ID'
complete -c andon -n "__fish_seen_subcommand_from list stats show level" -l json -d 'Print JSON'

# show, prompt, resolve, dismiss, reopen
complete -c andon -n "__fish_seen_subcommand_from show prompt resolve dismiss reopen" -xa "(__fish_andon_ids)"
complete -c andon -n "__fish_seen_subcommand_from resolve dismiss reopen" -l note -x -d 'What was done'
complete -c andon -n "__fish_seen_subcommand_from resolve dismiss reopen" -l all-matching -d 'Every alert sharing its fingerprint'

# level
complete -c andon -n "__fish_seen_subcommand_from level" -xa "1 2 3 4 5"
complete -c andon -n "__fish_seen_subcommand_from level" -l reset -d 'Return to the default'
