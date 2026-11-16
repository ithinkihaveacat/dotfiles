# completions for shell-format
complete -c shell-format -F -a '(__fish_complete_suffix .sh .bash .fish)' -d 'Shell file'
complete -c shell-format -l check -d 'Check for lint errors and formatting'
complete -c shell-format -s h -l help -d 'Display help'
