function __fish_android_packages -d 'List installed Android packages'
    # Check if adb is available
    command -q adb; or return 1

    # List packages, extracting package names after '='
    # Redirect stderr to avoid polluting completion output with error messages
    adb shell pm list packages -f 2>/dev/null | sed 's/.*=//'
end
