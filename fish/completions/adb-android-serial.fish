# completions for adb-android-serial function

function __fish_adb_android_serial_models
    if not adb get-state >/dev/null 2>&1
        return 1
    end
    adb devices -l | tail -n +2 | command grep -o 'model:[^ ]*' | command sed 's/model://'
end

complete -c adb-android-serial -f -a '(__fish_adb_android_serial_models)' -d 'Device model name'
