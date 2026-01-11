# Fish completion script for packagename

# Helper function: check if we need a command
function __fish_packagename_needs_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -eq 1
        return 0
    end
    return 1
end

# Helper function: check if using specific command
function __fish_packagename_using_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -gt 1
        if test $argv[1] = $cmd[2]
            return 0
        end
    end
    return 1
end

# Helper function: get list of installed packages
function __fish_packagename_list_packages
    adb shell pm list packages 2>/dev/null | string replace 'package:' ''
end

# Complete subcommands (when no subcommand given)
# Process/Lifecycle
complete -c packagename -f -n __fish_packagename_needs_command -a launch -d "Launch an application's main activity"
complete -c packagename -f -n __fish_packagename_needs_command -a force-stop -d 'Force stop an application'
complete -c packagename -f -n __fish_packagename_needs_command -a pid -d 'Get the process ID of a running package'
complete -c packagename -f -n __fish_packagename_needs_command -a logcat -d "Display logcat filtered by package's PID"

# Information
complete -c packagename -f -n __fish_packagename_needs_command -a dumpsys -d 'Display dumpsys package information'
complete -c packagename -f -n __fish_packagename_needs_command -a version -d 'Get the version name and code'
complete -c packagename -f -n __fish_packagename_needs_command -a permissions -d 'List declared permissions'
complete -c packagename -f -n __fish_packagename_needs_command -a services -d 'List the services of a package'
complete -c packagename -f -n __fish_packagename_needs_command -a services-dumpsys -d 'Display detailed dumpsys for all services'
complete -c packagename -f -n __fish_packagename_needs_command -a jobscheduler -d 'Display jobscheduler information'
complete -c packagename -f -n __fish_packagename_needs_command -a tiles -d 'List tiles provided by a package (Wear OS)'

# Profile/Optimization
complete -c packagename -f -n __fish_packagename_needs_command -a profile-status -d 'Display dex optimization status'
complete -c packagename -f -n __fish_packagename_needs_command -a profile-generate -d 'Trigger background dex optimization'

# Package Management
complete -c packagename -f -n __fish_packagename_needs_command -a pull -d 'Pull the APK file from the device'
complete -c packagename -f -n __fish_packagename_needs_command -a uninstall -d 'Uninstall a package'
complete -c packagename -f -n __fish_packagename_needs_command -a clear-cache -d 'Clear the cache of a package'
complete -c packagename -f -n __fish_packagename_needs_command -a reset-permissions -d 'Reset all permissions'

# Navigation
complete -c packagename -f -n __fish_packagename_needs_command -a view -d 'Open a URL within a package (PACKAGE URL)'
complete -c packagename -f -n __fish_packagename_needs_command -a playstore -d 'Open the Play Store page'
complete -c packagename -f -n __fish_packagename_needs_command -a settings -d 'Open the settings page'

# Complete package names for commands that need them
complete -c packagename -f -n '__fish_packagename_using_command launch' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command force-stop' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command pid' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command logcat' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command dumpsys' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command version' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command permissions' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command services' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command services-dumpsys' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command jobscheduler' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command tiles' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command profile-status' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command profile-generate' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command pull' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command uninstall' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command clear-cache' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command reset-permissions' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command view' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command playstore' -a '(__fish_packagename_list_packages)' -d 'Package'
complete -c packagename -f -n '__fish_packagename_using_command settings' -a '(__fish_packagename_list_packages)' -d 'Package'

# Complete flags
complete -c packagename -f -s h -l help -d 'Display help message and exit'
complete -c packagename -f -l list -d 'List available commands (names only)'
