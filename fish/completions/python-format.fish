# completions for python-format
complete -c python-format -F -a '(__fish_complete_suffix .py)' -d 'Python file'
complete -c python-format -l check -d 'Check for lint errors and formatting'
complete -c python-format -l help -d 'Display help'
