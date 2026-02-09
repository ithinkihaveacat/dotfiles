# completions for adb-theme
complete -c adb-theme -f

complete -c adb-theme -n "not __fish_seen_subcommand_from get set" -a get -d "Get the current theme configuration"
complete -c adb-theme -n "not __fish_seen_subcommand_from get set" -a set -d "Set the theme to one of the presets"

set -l themes indigo iris ivy jade lemongrass moonstone none peony porcelain watchface
complete -c adb-theme -n "__fish_seen_subcommand_from set" -a "$themes"

complete -c adb-theme -s h -l help -d "Display help"
