# Fish completion for adb-activities

complete -c adb-activities -f
complete -c adb-activities -s h -l help -d "Display help message"
complete -c adb-activities -l launcher-only -d "List only launcher activities"
complete -c adb-activities -l home-only -d "List only home/launcher app activities"
complete -c adb-activities -l tv-only -d "List only TV/Leanback activities"
complete -c adb-activities -l settings-only -d "List only settings activities"
complete -c adb-activities -l all -d "List activities from all packages (including system apps)"
