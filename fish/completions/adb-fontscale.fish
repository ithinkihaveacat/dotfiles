# completions for adb-fontscale
complete -c adb-fontscale -f

complete -c adb-fontscale -n "not __fish_seen_subcommand_from get set" -a get -d "Print the current font scale"
complete -c adb-fontscale -n "not __fish_seen_subcommand_from get set" -a set -d "Set the font scale"

complete -c adb-fontscale -n "__fish_seen_subcommand_from set" -a "default large"

complete -c adb-fontscale -l help -d "Display help"
