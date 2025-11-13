# fish/functions/__fish_android_services.fish
function __fish_android_services
    # Check if a device is connected
    if not adb devices | grep -q "device$"
        return 1
    end

    # List services and extract service names, filtering out the header
    adb shell service list | grep ':' | awk '{print $2}' | tr -d ':' | command sort -u
end
