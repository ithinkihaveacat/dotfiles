# completions for adb-demo
complete -c adb-demo -f

complete -c adb-demo -n "not __fish_seen_subcommand_from on off" -a on -d "Enter demo mode"
complete -c adb-demo -n "not __fish_seen_subcommand_from on off" -a off -d "Exit demo mode"

complete -c adb-demo -l help -d "Display help"
