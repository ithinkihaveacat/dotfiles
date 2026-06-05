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
    emumanager list avd --names-only 2>/dev/null
end

# Helper function: get list of running AVDs only
function __fish_emumanager_list_running_avds
    emumanager list avd --running-only 2>/dev/null
end

# Helper function: get list of stopped AVDs only
function __fish_emumanager_list_stopped_avds
    emumanager list avd --stopped-only 2>/dev/null
end

# Helper function: get list of system images
function __fish_emumanager_list_images
    emumanager catalog package | string trim | string replace -r '\* ' ''
end

# Complete subcommands (when no subcommand given)
complete -c emumanager -f -n __fish_emumanager_needs_command -a bootstrap -d 'Bootstrap SDK environment for emulator management'
complete -c emumanager -f -n __fish_emumanager_needs_command -a doctor -d 'Run diagnostics to check for common issues'
complete -c emumanager -f -n __fish_emumanager_needs_command -a list -d 'List local resources (avd, package)'
complete -c emumanager -f -n __fish_emumanager_needs_command -a info -d 'Show detailed information about an AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a catalog -d 'List obtainable packages'
complete -c emumanager -f -n __fish_emumanager_needs_command -a update -d 'Update all installed SDK packages'
complete -c emumanager -f -n __fish_emumanager_needs_command -a create -d 'Create a new AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a start -d 'Start an AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a stop -d 'Stop a running AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a delete -d 'Delete an AVD'
complete -c emumanager -f -n __fish_emumanager_needs_command -a download -d 'Download a package'

# Complete resource nouns for subcommands
complete -c emumanager -f -n '__fish_emumanager_using_command list; and not __fish_seen_subcommand_from avd package' -a 'avd package' -d 'Resource type'
complete -c emumanager -f -n '__fish_emumanager_using_command create; and not __fish_seen_subcommand_from avd' -a avd -d 'Resource type'
complete -c emumanager -f -n '__fish_emumanager_using_command delete; and not __fish_seen_subcommand_from avd' -a avd -d 'Resource type'
complete -c emumanager -f -n '__fish_emumanager_using_command info; and not __fish_seen_subcommand_from avd' -a avd -d 'Resource type'
complete -c emumanager -f -n '__fish_emumanager_using_command start; and not __fish_seen_subcommand_from avd' -a avd -d 'Resource type'
complete -c emumanager -f -n '__fish_emumanager_using_command stop; and not __fish_seen_subcommand_from avd' -a avd -d 'Resource type'
complete -c emumanager -f -n '__fish_emumanager_using_command download; and not __fish_seen_subcommand_from package' -a package -d 'Resource type'
complete -c emumanager -f -n '__fish_emumanager_using_command catalog; and not __fish_seen_subcommand_from package' -a package -d 'Resource type'
complete -c emumanager -f -n '__fish_emumanager_using_command update; and not __fish_seen_subcommand_from package' -a package -d 'Resource type'

# Complete arguments after nouns
complete -c emumanager -f -n '__fish_seen_subcommand_from info; and __fish_seen_subcommand_from avd' -a '(__fish_emumanager_list_avds)' -d 'AVD name'
complete -c emumanager -f -n '__fish_seen_subcommand_from start; and __fish_seen_subcommand_from avd' -a '(__fish_emumanager_list_stopped_avds)' -d 'Stopped AVD'
complete -c emumanager -f -n '__fish_seen_subcommand_from stop; and __fish_seen_subcommand_from avd' -a '(__fish_emumanager_list_running_avds)' -d 'Running AVD'
complete -c emumanager -f -n '__fish_seen_subcommand_from delete; and __fish_seen_subcommand_from avd' -a '(__fish_emumanager_list_avds)' -d 'AVD name'
complete -c emumanager -f -n '__fish_seen_subcommand_from download; and __fish_seen_subcommand_from package' -a '(__fish_emumanager_list_images)' -d 'System image'

# Complete flags for specific noun contexts
complete -c emumanager -f -n '__fish_seen_subcommand_from create; and __fish_seen_subcommand_from avd' -l mobile -d 'Create mobile/phone device (latest API)'
complete -c emumanager -f -n '__fish_seen_subcommand_from create; and __fish_seen_subcommand_from avd' -l phone -d 'Create mobile/phone device (latest API)'
complete -c emumanager -f -n '__fish_seen_subcommand_from create; and __fish_seen_subcommand_from avd' -l wear -d 'Create Wear OS device (latest API)'
complete -c emumanager -f -n '__fish_seen_subcommand_from create; and __fish_seen_subcommand_from avd' -l watch -d 'Create Wear OS device (latest API)'
complete -c emumanager -f -n '__fish_seen_subcommand_from create; and __fish_seen_subcommand_from avd' -l tv -d 'Create Android/Google TV device (latest API)'
complete -c emumanager -f -n '__fish_seen_subcommand_from create; and __fish_seen_subcommand_from avd' -l auto -d 'Create Android Automotive device (latest API)'

complete -c emumanager -f -n '__fish_seen_subcommand_from list; and __fish_seen_subcommand_from avd' -l names-only -d 'Output only AVD names without decoration'
complete -c emumanager -f -n '__fish_seen_subcommand_from list; and __fish_seen_subcommand_from avd' -l running-only -d 'Output only running AVD names'
complete -c emumanager -f -n '__fish_seen_subcommand_from list; and __fish_seen_subcommand_from avd' -l stopped-only -d 'Output only stopped AVD names'

complete -c emumanager -f -n '__fish_seen_subcommand_from list; and __fish_seen_subcommand_from package' -l outdated -d 'List local packages that have remote updates available'

complete -c emumanager -f -n '__fish_seen_subcommand_from start; and __fish_seen_subcommand_from avd' -l cold-boot -d 'Perform a cold boot (bypass Quick Boot snapshots)'
complete -c emumanager -f -n '__fish_seen_subcommand_from start; and __fish_seen_subcommand_from avd' -l wipe-data -d 'Factory reset (wipe all data and perform cold boot)'

# Global flags
complete -c emumanager -f -s h -l help -d 'Display help message and exit'
complete -c emumanager -f -n '__fish_emumanager_using_command bootstrap' -l no-emulator -d 'Skip installing the emulator'
