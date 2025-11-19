function adb-all-head -d "Runs adb command on all connected devices"

    if test ( count $argv ) -eq 0
        printf "usage: %s cmd [args] # e.g. %s \"shell dumpsys package %%s | grep versionCode\" de.komoot.android\n" (status current-command) (status current-command)
        return
    end

    for d in (adb devices -l | tail +2 | awk 'length { print $1 }')
        set -l device (adb -s $d shell getprop ro.product.device)
        set -l model (adb -s $d shell getprop ro.product.model)
        set -l name (printf "%s (%s)\n" $device $model)
        set -l cmd adb -s $d (printf $argv[1] $argv[2..])
        set -l res (eval $cmd | head -1 | string trim)
        printf "%-20s %s\n" $name $res
    end

end
