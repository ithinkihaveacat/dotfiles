# Fish completion for adb-tiles

complete -c adb-tiles -f
complete -c adb-tiles -s h -l help -d "Display help message"
complete -c adb-tiles -l tiles-only -d "List only tile services (no indicators)"
complete -c adb-tiles -l widgets-only -d "List only widget services (no indicators)"
complete -c adb-tiles -l all -d "List services from all packages (including system apps)"
