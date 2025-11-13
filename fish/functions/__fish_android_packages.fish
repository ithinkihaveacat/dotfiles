# fish/functions/__fish_android_packages.fish
function __fish_android_packages
    # Check if a device is connected
    if not adb get-state >/dev/null 2>&1
        return 1
    end

    # List packages and extract package names
    adb shell pm list packages -f | sed 's/.*=//'
end
