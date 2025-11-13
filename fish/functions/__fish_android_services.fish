function __fish_android_services -d 'List Android system services'
    # Check if adb is available
    command -q adb; or return 1

    # List services, extracting service names from second column and removing brackets/colons
    # Redirect stderr to avoid polluting completion output with error messages
    adb shell service list 2>/dev/null | awk '{print $2}' | tr -d '[]:'
end
