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

# Helper function: get list of AVDs
function __fish_emumanager_list_avds
  emumanager list --names-only 2>/dev/null
end

# Helper function: get list of system images
function __fish_emumanager_list_images
  emumanager images | string trim | string replace -r '\* ' ''
end

# Complete subcommands (when no subcommand given)
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'bootstrap' -d 'Bootstrap SDK environment for emulator management'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'list' -d 'List all available AVDs'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'info' -d 'Show detailed information about an AVD'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'images' -d 'List all available system images with API level >=33'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'outdated' -d 'Show outdated SDK packages'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'update' -d 'Update all installed SDK packages to latest versions'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'create' -d 'Create a new Wear OS AVD'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'start' -d 'Start the specified AVD'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'stop' -d 'Stop the specified AVD'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'delete' -d 'Delete the specified AVD'
complete -c emumanager -f -n '__fish_emumanager_needs_command' -a 'download' -d 'Download a system image'

# Complete AVD names for commands that need them
complete -c emumanager -f -n '__fish_emumanager_using_command info' -a '(__fish_emumanager_list_avds)' -d 'AVD name'
complete -c emumanager -f -n '__fish_emumanager_using_command start' -a '(__fish_emumanager_list_avds)' -d 'AVD name'
complete -c emumanager -f -n '__fish_emumanager_using_command stop' -a '(__fish_emumanager_list_avds)' -d 'AVD name'
complete -c emumanager -f -n '__fish_emumanager_using_command delete' -a '(__fish_emumanager_list_avds)' -d 'AVD name'
complete -c emumanager -f -n '__fish_emumanager_using_command download' -a '(__fish_emumanager_list_images)' -d 'System image'

# Complete flags
complete -c emumanager -f -s h -l help -d 'Display help message and exit'
complete -c emumanager -f -n '__fish_emumanager_using_command list' -l names-only -d 'Output only AVD names without decoration'
