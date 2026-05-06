# Fish completion for adb-tiles

complete -c adb-tiles -f
complete -c adb-tiles -l help -d "Display help message"
complete -c adb-tiles -l tiles-only -d "List only tile services"
complete -c adb-tiles -l widgets-only -d "List only widget services"
complete -c adb-tiles -l user-only -d "List only services from user-installed apps"
complete -c adb-tiles -l system-only -d "List only services from system apps"
complete -c adb-tiles -l carousel-only -d "List only services currently in the carousel"
