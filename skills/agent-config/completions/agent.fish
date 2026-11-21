# Fish completion script for agent

set -l commands list sync update doctor

complete -c agent -f
complete -c agent -s h -l help -d 'Show help and exit'

complete -c agent -n "not __fish_seen_subcommand_from $commands" -a list -d 'Table of agents: installed, version, path'
complete -c agent -n "not __fish_seen_subcommand_from $commands" -a sync -d 'Link shared context, hooks and plugins'
complete -c agent -n "not __fish_seen_subcommand_from $commands" -a update -d "Run each installed agent's own updater"
complete -c agent -n "not __fish_seen_subcommand_from $commands" -a doctor -d 'Check configuration and stale running versions'

complete -c agent -n "__fish_seen_subcommand_from $commands" -a 'claude codex opencode agy' -d Agent
complete -c agent -n "__fish_seen_subcommand_from doctor" -l quiet -d 'Only warnings and failures'
