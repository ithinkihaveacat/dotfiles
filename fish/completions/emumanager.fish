# Fish completion script for emumanager

# Helper function: check if we need a command
function __fish_emumanager_needs_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 1
        return 0
    end
    return 1
end

# Helper function: check if using specific command
function __fish_emumanager_using_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -gt 1
        if test $argv[1] = $cmd[2]
            return 0
        end
    end
    return 1
end

# Helper function: get list of all AVDs
function __fish_emumanager_list_avds
    emumanager list --names-only 2>/dev/null
end

# Helper function: get list of running AVDs only
function __fish_emumanager_list_running_avds
    emumanager list --running-only 2>/dev/null
end

# Helper function: get list of stopped AVDs only
function __fish_emumanager_list_stopped_avds
    emumanager list --stopped-only 2>/dev/null
end

# Helper function: get list of system images
function __fish_emumanager_list_images
    emumanager images | string trim | string replace -r '\* ' ''
end

# Complete subcommands (when no subcommand given)
complete -c emumanager -f -n __fish_emumanager_needs_command -a bootstrap -d 'Bootstrap SDK environment for emulator management'
complete -c emumanager -f -n __fish_emumanager_needs_command -a doctor -d 'Run diagnostics to check for common issues'
complete -c emumanager -f -n __fish_emumanager_needs_command -a list -d 'List all available AVDs'
complete -c emumanager -f -n __fish_emumanager_needs_command -a info -d 'Show detailed information about an AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a images -d 'List all available system images with API level >=33'
complete -c emumanager -f -n __fish_emumanager_needs_command -a outdated -d 'Show outdated SDK packages'
complete -c emumanager -f -n __fish_emumanager_needs_command -a update -d 'Update all installed SDK packages to latest versions'
complete -c emumanager -f -n __fish_emumanager_needs_command -a create -d 'Create a new AVD with the specified device type or image'
complete -c emumanager -f -n '__fish_emumanager_using_command create' -l mobile -d 'Create mobile/phone device (latest API)'
complete -c emumanager -f -n '__fish_emumanager_using_command create' -l phone -d 'Create mobile/phone device (latest API)'
complete -c emumanager -f -n '__fish_emumanager_using_command create' -l wear -d 'Create Wear OS device (latest API)'
complete -c emumanager -f -n '__fish_emumanager_using_command create' -l watch -d 'Create Wear OS device (latest API)'
complete -c emumanager -f -n '__fish_emumanager_using_command create' -l tv -d 'Create Android/Google TV device (latest API)'
complete -c emumanager -f -n '__fish_emumanager_using_command create' -l auto -d 'Create Android Automotive device (latest API)'
complete -c emumanager -f -n __fish_emumanager_needs_command -a start -d 'Start the specified AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a stop -d 'Stop the specified AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a delete -d 'Delete the specified AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a download -d 'Download a system image'

# Complete AVD names for commands that need them
complete -c emumanager -f -n '__fish_emumanager_using_command info' -a '(__fish_emumanager_list_avds)' -d 'AVD name'
complete -c emumanager -f -n '__fish_emumanager_using_command start' -a '(__fish_emumanager_list_stopped_avds)' -d 'Stopped AVD'
complete -c emumanager -f -n '__fish_emumanager_using_command stop' -a '(__fish_emumanager_list_running_avds)' -d 'Running AVD'
complete -c emumanager -f -n '__fish_emumanager_using_command delete' -a '(__fish_emumanager_list_avds)' -d 'AVD name'
complete -c emumanager -f -n '__fish_emumanager_using_command download' -a '(__fish_emumanager_list_images)' -d 'System image'

# Complete flags
complete -c emumanager -f -s h -l help -d 'Display help message and exit'
complete -c emumanager -f -n '__fish_emumanager_using_command bootstrap' -l no-emulator -d 'Skip installing the emulator'
complete -c emumanager -f -n '__fish_emumanager_using_command list' -l names-only -d 'Output only AVD names without decoration'
complete -c emumanager -f -n '__fish_emumanager_using_command list' -l running-only -d 'Output only running AVD names'
complete -c emumanager -f -n '__fish_emumanager_using_command list' -l stopped-only -d 'Output only stopped AVD names'
complete -c emumanager -f -n '__fish_emumanager_using_command start' -l cold-boot -d 'Perform a cold boot (bypass Quick Boot snapshots)'
complete -c emumanager -f -n '__fish_emumanager_using_command start' -l wipe-data -d 'Factory reset (wipe all data and perform cold boot)'
